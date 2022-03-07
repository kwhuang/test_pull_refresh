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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        vsync: this,
        length: 3,
        initialIndex: 0
    );
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
                      ],
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

