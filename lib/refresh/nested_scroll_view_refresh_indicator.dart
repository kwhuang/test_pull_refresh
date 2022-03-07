import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

const double _kDragContainerExtentPercentage = 0.25;
const double _kDragSizeFactorLimit = 1.5;
const Duration _kIndicatorSnapDuration = Duration(milliseconds: 150);
const Duration _kIndicatorScaleDuration = Duration(milliseconds: 200);

typedef NestedScrollViewRefreshCallback = Future<void> Function();

enum _RefreshIndicatorMode {
  drag, // Pointer is down.
  armed, // Dragged far enough that an up event will run the onRefresh callback.
  snap, // Animating to the indicator's final "displacement".
  refresh, // Running the refresh callback.
  done, // Animating the indicator's fade-out after refreshing.
  canceled, // Animating the indicator's fade-out after not arming.
}

class NestedScrollViewRefreshIndicator extends StatefulWidget {

  const NestedScrollViewRefreshIndicator({
    Key? key,
    required this.child,
    this.displacement = 40.0,
    required this.onRefresh,
    this.color,
    this.backgroundColor,
    this.notificationPredicate = nestedScrollViewScrollNotificationPredicate,
    this.semanticsLabel,
    this.semanticsValue,
  })  : super(key: key);

  final Widget child;
  final double displacement;
  final NestedScrollViewRefreshCallback onRefresh;
  final Color? color;
  final Color? backgroundColor;
  final ScrollNotificationPredicate notificationPredicate;
  final String? semanticsLabel;
  final String? semanticsValue;
  @override
  NestedScrollViewRefreshIndicatorState createState() =>
      NestedScrollViewRefreshIndicatorState();
}

class NestedScrollViewRefreshIndicatorState
    extends State<NestedScrollViewRefreshIndicator>
    with TickerProviderStateMixin<NestedScrollViewRefreshIndicator> {
  late AnimationController _positionController;
  late AnimationController _scaleController;
  late Animation<double> _positionFactor;
  late Animation<double> _scaleFactor;
  late Animation<double> _value;
  late Animation<Color?> _valueColor;

  _RefreshIndicatorMode? _mode;
  late Future<void> _pendingRefreshFuture;
  bool? _isIndicatorAtTop;
  double? _dragOffset;

  static final Animatable<double> _threeQuarterTween =
      Tween<double>(begin: 0.0, end: 0.75);
  static final Animatable<double> _kDragSizeFactorLimitTween =
      Tween<double>(begin: 0.0, end: _kDragSizeFactorLimit);
  static final Animatable<double> _oneToZeroTween =
      Tween<double>(begin: 1.0, end: 0.0);

  @override
  void initState() {
    super.initState();
    _positionController = AnimationController(vsync: this);
    _positionFactor = _positionController.drive(_kDragSizeFactorLimitTween);
    _value = _positionController.drive(
        _threeQuarterTween); // The "value" of the circular progress indicator during a drag.

    _scaleController = AnimationController(vsync: this);
    _scaleFactor = _scaleController.drive(_oneToZeroTween);
  }

  @override
  void didChangeDependencies() {
    final ThemeData theme = Theme.of(context);
    _valueColor = _positionController.drive(
      ColorTween(
              begin: (widget.color ?? theme.accentColor).withOpacity(0.0),
              end: (widget.color ?? theme.accentColor).withOpacity(1.0))
          .chain(CurveTween(
              curve: const Interval(0.0, 1.0 / _kDragSizeFactorLimit))),
    );
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _positionController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  double maxContainerExtent = 0.0;
  bool _handleScrollNotification(ScrollNotification notification) {
    if (!widget.notificationPredicate(notification)) return false;
    maxContainerExtent = math.max(
        notification.metrics.viewportDimension, this.maxContainerExtent);
    if (notification is ScrollStartNotification &&
        notification.metrics.extentBefore == 0.0 &&
        _mode == null &&
        _start(notification.metrics.axisDirection)) {
      setState(() {
        _mode = _RefreshIndicatorMode.drag;
      });
      return false;
    }
    bool? indicatorAtTopNow;
    switch (notification.metrics.axisDirection) {
      case AxisDirection.down:
        indicatorAtTopNow = true;
        break;
      case AxisDirection.up:
        indicatorAtTopNow = false;
        break;
      case AxisDirection.left:
      case AxisDirection.right:
        indicatorAtTopNow = null;
        break;
    }
    if (indicatorAtTopNow != _isIndicatorAtTop) {
      if (_mode == _RefreshIndicatorMode.drag ||
          _mode == _RefreshIndicatorMode.armed)
        _dismiss(_RefreshIndicatorMode.canceled);
    } else if (notification is ScrollUpdateNotification) {
      if (_mode == _RefreshIndicatorMode.drag ||
          _mode == _RefreshIndicatorMode.armed) {
        if (notification.metrics.extentBefore > 0.0) {
          _dismiss(_RefreshIndicatorMode.canceled);
        } else {
          if (_dragOffset != null) {
            _dragOffset = _dragOffset! - notification.scrollDelta!;
          }
          _checkDragOffset(maxContainerExtent);
        }
      }
      if (_mode == _RefreshIndicatorMode.armed &&
          notification.dragDetails == null) {
        // On iOS start the refresh when the Scrollable bounces back from the
        // overscroll (ScrollNotification indicating this don't have dragDetails
        // because the scroll activity is not directly triggered by a drag).
        _show();
      }
    } else if (notification is OverscrollNotification) {
      if (_mode == _RefreshIndicatorMode.drag ||
          _mode == _RefreshIndicatorMode.armed) {
        if (_dragOffset != null) {
          _dragOffset = _dragOffset! - notification.overscroll / 2.0;
        }

        _checkDragOffset(maxContainerExtent);
      }
    } else if (notification is ScrollEndNotification) {
      switch (_mode) {
        case _RefreshIndicatorMode.armed:
          _show();
          break;
        case _RefreshIndicatorMode.drag:
          _dismiss(_RefreshIndicatorMode.canceled);
          break;
        default:
          // do nothing
          break;
      }
    }
    return false;
  }

  bool _handleGlowNotification(OverscrollIndicatorNotification notification) {
    if (notification.depth != 0 || !notification.leading) return false;
    if (_mode == _RefreshIndicatorMode.drag) {
      notification.disallowGlow();
      return true;
    }
    return false;
  }

  bool _start(AxisDirection direction) {
    assert(_mode == null);
    assert(_isIndicatorAtTop == null);
    assert(_dragOffset == null);
    switch (direction) {
      case AxisDirection.down:
        _isIndicatorAtTop = true;
        break;
      case AxisDirection.up:
        _isIndicatorAtTop = false;
        break;
      case AxisDirection.left:
      case AxisDirection.right:
        _isIndicatorAtTop = null;
        // we do not support horizontal scroll views.
        return false;
    }
    _dragOffset = 0.0;
    _scaleController.value = 0.0;
    _positionController.value = 0.0;
    return true;
  }

  void _checkDragOffset(double containerExtent) {
    assert(_mode == _RefreshIndicatorMode.drag ||
        _mode == _RefreshIndicatorMode.armed);
    double newValue =
        _dragOffset??0.0 / (containerExtent * _kDragContainerExtentPercentage);
    if (_mode == _RefreshIndicatorMode.armed)
      newValue = math.max(newValue, 1.0 / _kDragSizeFactorLimit);
    _positionController.value =
        newValue.clamp(0.0, 1.0); // this triggers various rebuilds
    if (_mode == _RefreshIndicatorMode.drag && _valueColor.value!.alpha == 0xFF)
      _mode = _RefreshIndicatorMode.armed;
  }

  Future<void> _dismiss(_RefreshIndicatorMode newMode) async {
    await Future<void>.value();
    assert(newMode == _RefreshIndicatorMode.canceled ||
        newMode == _RefreshIndicatorMode.done);
    setState(() {
      _mode = newMode;
    });
    switch (_mode) {
      case _RefreshIndicatorMode.done:
        await _scaleController.animateTo(1.0,
            duration: _kIndicatorScaleDuration);
        break;
      case _RefreshIndicatorMode.canceled:
        await _positionController.animateTo(0.0,
            duration: _kIndicatorScaleDuration);
        break;
      default:
        assert(false);
    }
    if (mounted && _mode == newMode) {
      _dragOffset = null;
      _isIndicatorAtTop = null;
      setState(() {
        _mode = null;
      });
    }
  }

  void _show() {
    assert(_mode != _RefreshIndicatorMode.refresh);
    assert(_mode != _RefreshIndicatorMode.snap);
    final Completer<void> completer = Completer<void>();
    _pendingRefreshFuture = completer.future;
    _mode = _RefreshIndicatorMode.snap;
    _positionController
        .animateTo(1.0 / _kDragSizeFactorLimit,
            duration: _kIndicatorSnapDuration)
        .then<void>((void value) {
      if (mounted && _mode == _RefreshIndicatorMode.snap) {
        assert(widget.onRefresh != null);
        setState(() {
          // Show the indeterminate progress indicator.
          _mode = _RefreshIndicatorMode.refresh;
        });

        final Future<void> refreshResult = widget.onRefresh();
        assert(() {
          if (refreshResult == null)
            FlutterError.reportError(FlutterErrorDetails(
              exception: FlutterError('The onRefresh callback returned null.\n'
                  'The RefreshIndicator onRefresh callback must return a Future.'),
              context: ErrorDescription('when calling onRefresh'),
              library: 'material library',
            ));
          return true;
        }());
        if (refreshResult == null) return;
        refreshResult.whenComplete(() {
          if (mounted && _mode == _RefreshIndicatorMode.refresh) {
            completer.complete();
            _dismiss(_RefreshIndicatorMode.done);
          }
        });
      }
    });
  }

  Future<void> show({bool atTop = true}) {
    if (_mode != _RefreshIndicatorMode.refresh &&
        _mode != _RefreshIndicatorMode.snap) {
      if (_mode == null) _start(atTop ? AxisDirection.down : AxisDirection.up);
      _show();
    }
    return _pendingRefreshFuture;
  }

  final GlobalKey _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));
    final Widget child = NotificationListener<ScrollNotification>(
      key: _key,
      onNotification: _handleScrollNotification,
      child: NotificationListener<OverscrollIndicatorNotification>(
        onNotification: _handleGlowNotification,
        child: widget.child,
      ),
    );
    if (_mode == null) {
      assert(_dragOffset == null);
      assert(_isIndicatorAtTop == null);
      return child;
    }
    assert(_dragOffset != null);
    assert(_isIndicatorAtTop != null);

    final bool showIndeterminateIndicator =
        _mode == _RefreshIndicatorMode.refresh ||
            _mode == _RefreshIndicatorMode.done;

    return Stack(
      children: <Widget>[
        child,
        Positioned(
          top: _isIndicatorAtTop == true ? 0.0 : null,
          bottom: _isIndicatorAtTop == false ? 0.0 : null,
          left: 0.0,
          right: 0.0,
          child: SizeTransition(
            axisAlignment: _isIndicatorAtTop == true ? 1.0 : -1.0,
            sizeFactor: _positionFactor, // this is what brings it down
            child: Container(
              padding: _isIndicatorAtTop == true
                  ? EdgeInsets.only(top: widget.displacement)
                  : EdgeInsets.only(bottom: widget.displacement),
              alignment: _isIndicatorAtTop == true
                  ? Alignment.topCenter
                  : Alignment.bottomCenter,
              child: ScaleTransition(
                scale: _scaleFactor,
                child: AnimatedBuilder(
                  animation: _positionController,
                  builder: (BuildContext context, Widget? child) {
                    return RefreshProgressIndicator(
                      semanticsLabel: widget.semanticsLabel ?? MaterialLocalizations.of(context).refreshIndicatorSemanticLabel,
                      semanticsValue: widget.semanticsValue,
                      value: showIndeterminateIndicator ? null : _value.value,
                      valueColor: _valueColor,
                      backgroundColor: widget.backgroundColor,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

//return true so that we can handle inner scroll notification
bool nestedScrollViewScrollNotificationPredicate(
    ScrollNotification notification) {
  return true;
}
