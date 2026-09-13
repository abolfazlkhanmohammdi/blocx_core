class SelectionChangedData<T> {
  final List<T> selection;
  final bool wasSelected;
  final T item;
  SelectionChangedData({required this.selection, required this.wasSelected, required this.item});
}
