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
