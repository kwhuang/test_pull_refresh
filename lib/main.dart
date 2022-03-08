import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:loading_more_list/loading_more_list.dart';
import 'package:pull_to_refresh_notification/pull_to_refresh_notification.dart';
import 'package:test_pull_refresh/refresh/push_to_refresh_header.dart';
import 'package:test_pull_refresh/test_refresh_list.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {

  /// 刷新页面
  Future<void> _refresh({bool needShowBusy = true}) async{
    await Future.delayed(const Duration(milliseconds: 3000),(){

    });
  }
  late TabController _tabController;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        vsync: this,
        length: 3,
        initialIndex: 0
    );
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      print('------------列表滚动高度${_tabController.offset}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: PullToRefreshNotification(
          color: Colors.blue,
          onRefresh: () async {
            await _refresh(needShowBusy: false);
            return true;
          },
          maxDragOffset: maxDragOffset,
          child: GlowNotificationWidget(
            ExtendedNestedScrollView(
              controller: _scrollController,
              headerSliverBuilder: (BuildContext c, bool f) {
                return <Widget>[
                  PullToRefreshContainer(
                        (PullToRefreshScrollNotificationInfo? info) {
                      return SliverToBoxAdapter(
                        child: PullToRefreshHeader(info),
                      );
                    },
                  ),
                  SliverToBoxAdapter(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                       Container(
                         margin: const EdgeInsets.all(5),
                         color: Colors.redAccent,
                         height: 60,
                         child: const Center(
                           child: Text('广告位'),
                         ),
                       ),
                        Container(
                          color:Colors.amberAccent,
                          margin: const EdgeInsets.all(5),
                          height: 60,
                          child: const Center(
                            child: Text('活动位置'),
                          ),
                        ),
                        Container(
                          color:Colors.purpleAccent,
                          margin: const EdgeInsets.all(5),
                          height: 60,
                          child: const Center(
                            child: Text('活提示的信息'),
                          ),
                        ),
                        /*
                        SizedBox(
                          height: 48,
                          child: TabBar(
                            controller: _tabController,
                            tabs: List.generate(_tabController.length, (index){
                              return Container(
                                color: index%2 == 0 ? Colors.green : index%2==1 ? Colors.amberAccent : Colors.blue,
                                alignment: Alignment.center,
                                child: Text(index.toString()),
                              );
                            }),
                          ),
                        )
                         */
                      ],
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: SliverHeaderDelegate.fixedHeight( //固定高度
                      height: 50,
                      child: TabBar(
                        controller: _tabController,
                        tabs: List.generate(_tabController.length, (index){
                          return Container(
                            color: index%2 == 0 ? Colors.green : index%2==1 ? Colors.amberAccent : Colors.blue,
                            alignment: Alignment.center,
                            child: Text(index.toString()),
                          );
                        }),
                      ),
                    ),
                  ),
                ];
              },
              onlyOneScrollInBody: true,
              body: GlowNotificationWidget(
                TabBarView(
                  controller: _tabController,
                  children: List.generate(
                    3, (index) {
                      return const TestRefreshList();
                    },
                  ),
                ),
              ),
            ),
          )
      ),
    );
  }

}

typedef SliverHeaderBuilder = Widget Function(
    BuildContext context, double shrinkOffset, bool overlapsContent);

class SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  // child 为 header
  SliverHeaderDelegate({
    required this.maxHeight,
    this.minHeight = 0,
    required Widget child,
  })  : builder = ((a, b, c) => child),
        assert(minHeight <= maxHeight && minHeight >= 0);

  //最大和最小高度相同
  SliverHeaderDelegate.fixedHeight({
    required double height,
    required Widget child,
  })  : builder = ((a, b, c) => child),
        maxHeight = height,
        minHeight = height;

  //需要自定义builder时使用
  SliverHeaderDelegate.builder({
    required this.maxHeight,
    this.minHeight = 0,
    required this.builder,
  });

  final double maxHeight;
  final double minHeight;
  final SliverHeaderBuilder builder;

  @override
  Widget build(
      BuildContext context,
      double shrinkOffset,
      bool overlapsContent,
      ) {
    Widget child = builder(context, shrinkOffset, overlapsContent);
    //测试代码：如果在调试模式，且子组件设置了key，则打印日志
    assert(() {
      if (child.key != null) {
        print('${child.key}: shrink: $shrinkOffset，overlaps:$overlapsContent');
      }
      return true;
    }());
    // 让 header 尽可能充满限制的空间；宽度为 Viewport 宽度，
    // 高度随着用户滑动在[minHeight,maxHeight]之间变化。
    return SizedBox.expand(child: child);
  }

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(SliverHeaderDelegate old) {
    return old.maxExtent != maxExtent || old.minExtent != minExtent;
  }
}
