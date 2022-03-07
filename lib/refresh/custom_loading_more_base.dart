
import 'package:loading_more_list/loading_more_list.dart';

typedef Future<C> LoadDataCallBack<C>(int offset);

typedef void OnDataChangeListener<C>(List<C> data);

///
///数据源基类 封装上下拉刷新逻辑
///
class CustomLoadingMoreBase<T> extends LoadingMoreBase<T> {
  CustomLoadingMoreBase({required this.loadDataCallBack, this.pageSize = 10, this.onDataChangeListener})
      : assert(pageSize != null);

  //加载数据的回调方法
  LoadDataCallBack loadDataCallBack;

  //数据变化的回调
  OnDataChangeListener? onDataChangeListener;

  //默认第一页
  int _offset = 1;

  //是否还有更多数据
  bool _hasMore = true;

  //默认一页10条数据
  int pageSize;

  @override
  bool get hasMore => _hasMore;

  @override
  Future<bool> refresh([bool clearBeforeRequest = false]) async {
    print('CustomLoadingMoreBase clearBeforeRequest=$clearBeforeRequest');
    _offset = 0;
    _hasMore = true;
    return await super.refresh(clearBeforeRequest);
  }

  @override
  Future<bool> loadData([bool isloadMoreAction = false]) async {
    print('CustomLoadingMoreBase isloadMoreAction=$isloadMoreAction');
    bool isSuccess = false;
    bool hasError = false;
    var newOffset = _offset + 1;
    try {
      var listData = await loadDataCallBack(newOffset);
      if (newOffset == 1) {
        this.clear();
      }

      //集合数据
      var list;

      //如果listData本身就是一个集合
      if (listData is List) {
        list = listData;
      } else {
        //否则看下集合数据是不是在dataList或logList字段里面
        bool isInDataList = false, isInLogList = false;
        try {
          isInDataList = (listData?.dataList?.length ?? 0) > 0;
        } catch (e) {
          print('CustomLoadingMoreBase: is not InDataList');
        }

        if (isInDataList == true) {
          list = listData.dataList;
        } else {
          try {
            isInLogList = (listData?.logList?.length ?? 0) > 0;
          } catch (e) {
            print('CustomLoadingMoreBase: is not InLogList');
          }
          if (isInLogList == true) {
            list = listData.logList;
          }
        }
      }

      //操作集合数据
      if (list is List) {
        for (var item in list) {
          this.add(item);
        }
        _offset = newOffset;
        _hasMore = list.length >= pageSize;
      } else {
        _hasMore = false;
      }

      isSuccess = true;
    } catch (exception, stack) {
      hasError = true;
      print(exception);
      print(stack);
    }
    if (onDataChangeListener != null) {
      onDataChangeListener!(this);
    }
    return isloadMoreAction ? isSuccess : !hasError;
  }
}
