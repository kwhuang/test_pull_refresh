import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart' ;
import 'package:loading_more_list/loading_more_list.dart';
import 'package:pull_to_refresh_notification/pull_to_refresh_notification.dart' hide RefreshCallback;
import 'package:test_pull_refresh/refresh/push_to_refresh_header.dart';

import 'nested_scroll_view_refresh_indicator.dart';

///App默认的头部刷新
Widget getAppDefaultRefreshIndicator({required RefreshCallback onRefresh, required Widget child, Key? key,bool isSliver = false,bool haveRefresh = false}) {
  return PullToRefreshNotification(
    color: Colors.blue,
    onRefresh: () async {
      await onRefresh();
      return true;
    },
    maxDragOffset: 60,
    child: GlowNotificationWidget(
      isSliver == true || haveRefresh == false ? child : Column(
        children: <Widget>[
          PullToRefreshContainer(
                (PullToRefreshScrollNotificationInfo? info) {
              return PullToRefreshHeader(info);
            },
          ),
          Expanded(
            child: child,
          )
        ],
      ),
      showGlowLeading: false,
    ),
  );
}

///App默认的头部刷新（用于NestedScrollView）
Widget getAppDefaultRefreshIndicator4Nested({required RefreshCallback onRefresh, required Widget child, Key? key}) {
  return PullToRefreshNotification(
    key: key,
    child: child,
    onRefresh: () async {
      await onRefresh();
      return true;
    },
  );
}
