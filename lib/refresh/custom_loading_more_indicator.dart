import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loading_more_list/loading_more_list.dart';

//自定义列表的加载状态
class CustomLoadingMoreIndicator {
  CustomLoadingMoreIndicator({
    this.listSourceRepository,
    this.isSliver = false,
    this.loadingMoreBusyingWidgt,
    this.fullScreenBusyingWidgt,
    this.errorWidgt,
    this.fullScreenErrorWidgt,
    this.noMoreLoadWidgt,
    this.emptyWidgt,
  });

  final LoadingMoreBase? listSourceRepository;
  final bool isSliver;
  final Widget? loadingMoreBusyingWidgt;
  final Widget? fullScreenBusyingWidgt;
  final Widget? errorWidgt;
  final Widget? fullScreenErrorWidgt;
  final Widget? noMoreLoadWidgt;
  final Widget? emptyWidgt;

  Widget buildYiHuaIndicator(BuildContext context, IndicatorStatus status) {
    //print('iloveyou${status.index}');
    Widget widget;
    switch (status) {
      case IndicatorStatus.none:
        widget = Container(height: 0.0);
        break;
      case IndicatorStatus.loadingMoreBusying:
        widget = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(margin: EdgeInsets.only(right: 5.0), height: 15.0, width: 15.0, child: getIndicator(context)),
            Text("拼命加载中")
          ],
        );
        widget = setbackground(false, widget, 35.0);
        widget = loadingMoreBusyingWidgt ?? widget;
        break;
      case IndicatorStatus.fullScreenBusying:
        widget = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(right: 4.0),
              height: 30.0,
              width: 30.0,
              child: getIndicator(context),
            ),
            Text("刷新中")
          ],
        );
        widget = setbackground(true, widget, double.infinity);
        widget = fullScreenBusyingWidgt ?? widget;
        if (isSliver) {
          widget = SliverFillRemaining(
            child: widget,
          );
        } else {
          widget = CustomScrollView(
            slivers: <Widget>[
              SliverFillRemaining(
                child: widget,
              )
            ],
          );
        }
        break;
      case IndicatorStatus.error:
        widget = Text(
          "加载失败(点我重试)",
        );
        widget = setbackground(false, widget, 35.0);
        widget = errorWidgt ?? widget;
        widget = GestureDetector(
          onTap: () {
            listSourceRepository?.errorRefresh();
          },
          child: widget,
        );
        break;
      case IndicatorStatus.fullScreenError:
        widget = Text(
          "加载失败(点我重试)",
        );
        widget = setbackground(true, widget, double.infinity);
        widget = fullScreenErrorWidgt ?? widget;
        widget = GestureDetector(
          onTap: () {
            listSourceRepository?.errorRefresh();
          },
          child: widget,
        );
        if (isSliver) {
          widget = SliverFillRemaining(
            child: widget,
          );
        } else {
          widget = CustomScrollView(
            slivers: <Widget>[
              SliverFillRemaining(
                child: widget,
              )
            ],
          );
        }
        break;
      case IndicatorStatus.noMoreLoad:
        widget = Text(
          "没有更多了",
          style: TextStyle(color: Colors.black26),
        );
        widget = setbackground(false, widget, 80.0);
        widget = noMoreLoadWidgt ?? widget;
        break;
      case IndicatorStatus.empty:
        widget = Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              /*Icon(
                size: 64,
                color: emptyIconColor??Color(),
              ),*/
              Padding(
                padding: EdgeInsets.only(top: 16),
              ),
              Text(
                "暂无数据",
                style: TextStyle(fontSize: 10, color: Colors.black26),
              )
            ],
          ),
        );
//        widget = setbackground(true, widget, double.infinity);
        //widget = setbackground(true, widget, 300);
        widget = emptyWidgt ?? widget;
        widget = GestureDetector(
          onTap: () => listSourceRepository?.errorRefresh(),
          child: widget,
        );
        if (isSliver) {
          widget = SliverFillRemaining(
            child: widget,
          );
        } else {
          widget = CustomScrollView(
            slivers: <Widget>[
              SliverFillRemaining(
                child: widget,
              )
            ],
          );
        }
        break;
    }
    return widget;
  }

  Widget setbackground(bool full, Widget widget, double height, {Color? backgroundColor}) {
    widget = Container(
        width: double.infinity,
        height: height,
        child: widget,
//        color: backgroundColor ?? Colors.grey[200],
        alignment: Alignment.center);
    return widget;
  }

  Widget getIndicator(BuildContext context) {
    return Platform.isIOS
        ? CupertinoActivityIndicator(
            animating: true,
            radius: 16.0,
          )
        : CircularProgressIndicator(
            strokeWidth: 2.0,
            valueColor: AlwaysStoppedAnimation(Theme.of(context).primaryColor),
          );
  }
}
