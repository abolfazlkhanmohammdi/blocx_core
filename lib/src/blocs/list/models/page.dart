class Page<T> {
  final List<T> items;
  final int offset;
  final int loadCount;
  const Page({required this.items, required this.offset, required this.loadCount});
  bool get hasNext => loadCount == items.length;
}
