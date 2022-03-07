import 'package:flutter/material.dart';
import 'package:test_pull_refresh/refresh/app_simple_refresh.dart';

class TestRefreshList extends StatefulWidget {
  const TestRefreshList({Key? key}) : super(key: key);

  @override
  State<TestRefreshList> createState() => _TestRefreshListState();
}

class _TestRefreshListState extends State<TestRefreshList> {
  get buildListItemCallBack => null;

  Future<List<int>> loadDataCallBack(int offset) async {
    List<int> datas = <int>[];
    await Future.delayed(const Duration(milliseconds: 3000),(){
      datas = List.generate(10, (index) => offset * 10 + index);
    });
    return Future.value(datas);
  }

  @override
  Widget build(BuildContext context) {
    return AppSimpleRefresh<int>(
        haveRefresh: false,
        pageSize: 10,
        loadDataCallBack: loadDataCallBack,
        buildListItemCallBack: ( _, int data, int index) {
          return Container(
            margin: const EdgeInsets.only(top: 5),
            color: index%2== 0 ? Colors.white54 : Colors.lightGreen,
            height: 80,
            child: Center(
              child: Text('这是第$index个的数据：$data'),
            ),
          );
        }
    );
  }
}
