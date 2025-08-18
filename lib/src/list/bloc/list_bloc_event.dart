part of 'list_bloc.dart';

class ListBlocEvent<T extends ListEntity<T>> extends BaseBlocEvent {}

class ListBlocEventSelectItem<T extends ListEntity<T>> extends ListBlocEvent<T> {
  final T item;
  ListBlocEventSelectItem({required this.item});
}

class ListBlocEventDeSelectItem<T extends ListEntity<T>> extends ListBlocEvent<T> {
  final T item;
  ListBlocEventDeSelectItem({required this.item});
}

class ListBlocEventHighlightItem<T extends ListEntity<T>> extends ListBlocEvent<T> {
  final T item;
  ListBlocEventHighlightItem({required this.item});
}

class ListBlocEventClearHighlightedItem<T extends ListEntity<T>> extends ListBlocEvent<T> {
  final T item;
  ListBlocEventClearHighlightedItem({required this.item});
}

// Data
class ListBlocEventLoadData<T extends ListEntity<T>, P> extends ListBlocEvent<T> {
  final P? payload;
  ListBlocEventLoadData({required this.payload});
}

class ListBlocEventRefreshData<T extends ListEntity<T>> extends ListBlocEvent<T> {}

class ListBlocEventLoadMoreData<T extends ListEntity<T>> extends ListBlocEvent<T> {}

class ListBlocEventSearch<T extends ListEntity<T>> extends ListBlocEvent<T> {
  final String searchText;
  ListBlocEventSearch({required this.searchText});
}

class ListBlocEventClearSearch<T extends ListEntity<T>> extends ListBlocEvent<T> {}
