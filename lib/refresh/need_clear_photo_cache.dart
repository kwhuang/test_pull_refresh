///需要清理图片的缓存
mixin NeedClearPhotoCache<T> {
  ///需要实现的方法，返回需要清理的图片路径集合
  List<String> getClearPhotoPaths(T data);
}