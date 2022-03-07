import 'package:flutter/material.dart';
import 'package:pull_to_refresh_notification/pull_to_refresh_notification.dart';

double get maxDragOffset => 60;
double hideHeight = maxDragOffset / 2.3;
double refreshHeight = maxDragOffset / 1.5;

class PullToRefreshHeader extends StatelessWidget {
  const PullToRefreshHeader(
    this.info, {
    this.color,
  });

  final PullToRefreshScrollNotificationInfo? info;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final PullToRefreshScrollNotificationInfo? _info = info;
    if (_info == null) {
      return Container();
    }
    String text = '';
    bool showProgressIndicator = false;
    if (_info.mode == RefreshIndicatorMode.armed) {
      text = '↑ 松开刷新';
    } else if (_info.mode == RefreshIndicatorMode.refresh ||
        _info.mode == RefreshIndicatorMode.snap) {
      text = '拼命加载中...';
      showProgressIndicator = true;
    } else if (_info.mode == RefreshIndicatorMode.done) {
      text = '加载完成';
    } else if (_info.mode == RefreshIndicatorMode.drag) {
      text = '↓ 下拉刷新';
    } else if (_info.mode == RefreshIndicatorMode.canceled) {
      text = '取消刷新';
    }
    final TextStyle ts = const TextStyle(
      color: Colors.black45,
    ).copyWith(fontSize: 14);
    final double dragOffset = info?.dragOffset ?? 0.0;
    return Container(
      height: dragOffset,
      child: Stack(
        children: <Widget>[
          Align(
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const Spacer(),
                Visibility(
                  visible: showProgressIndicator,
                  child: Container(
                    height: 20,
                    width: 20,
                    margin: const EdgeInsets.only(right: 8),
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation(Colors.green),
                    ),
                  ),
                ),
                Text(text, style: ts),
                const Spacer(),
              ],
            ),
          )
        ],
      ),
    );
  }
}
