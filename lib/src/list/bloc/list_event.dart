part of 'list_bloc.dart';

class ListEvent<T extends ListEntity<T>> extends BaseEvent {}

class ListEventSelectItem<T extends ListEntity<T>> extends ListEvent<T> {
  final T item;
  ListEventSelectItem({required this.item});
}

class ListEventDeselectItem<T extends ListEntity<T>> extends ListEvent<T> {
  final T item;
  ListEventDeselectItem({required this.item});
}

class ListEventHighlightItem<T extends ListEntity<T>> extends ListEvent<T> {
  final T item;
  ListEventHighlightItem({required this.item});
}

class ListEventClearHighlightedItem<T extends ListEntity<T>> extends ListEvent<T> {
  final T item;
  ListEventClearHighlightedItem({required this.item});
}

// Data
class ListEventLoadInitialPage<T extends ListEntity<T>, P> extends ListEvent<T> {
  final P? payload;
  ListEventLoadInitialPage({required this.payload});
}

class ListEventRefreshData<T extends ListEntity<T>> extends ListEvent<T> {}

class ListEventLoadNextPage<T extends ListEntity<T>> extends ListEvent<T> {}

class ListEventSearch<T extends ListEntity<T>> extends ListEvent<T> {
  final String searchText;
  ListEventSearch({required this.searchText});
}

class ListEventSearchNextPage<T extends ListEntity<T>> extends ListEvent<T> {}

class ListEventClearSearch<T extends ListEntity<T>> extends ListEvent<T> {}

class ListEventRemoveItem<T extends ListEntity<T>> extends ListEvent<T> {
  final T item;
  ListEventRemoveItem({required this.item});
}
