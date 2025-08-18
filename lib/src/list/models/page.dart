class Page<T> {
  final List<T> items;
  final int offset;
  final int limit;
  final bool hasNext;
  const Page({required this.items, required this.hasNext, required this.offset, required this.limit});
}

class PaginationQuery<P> {
  final int loadCount;
  final int offset;
  final P? payload;
  const PaginationQuery({required this.payload, required this.loadCount, required this.offset});
}
