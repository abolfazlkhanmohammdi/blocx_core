part of 'list_bloc.dart';

class ListEvent<T extends BaseEntity> extends BaseEvent {}

class ListEventSelectItem<T extends BaseEntity> extends ListEvent<T> {
  final T item;
  ListEventSelectItem({required this.item});
}

class ListEventDeselectItem<T extends BaseEntity> extends ListEvent<T> {
  final T item;
  ListEventDeselectItem({required this.item});
}

class ListEventHighlightItem<T extends BaseEntity> extends ListEvent<T> {
  final T item;
  ListEventHighlightItem({required this.item});
}

class ListEventClearHighlightedItem<T extends BaseEntity> extends ListEvent<T> {
  final T item;
  ListEventClearHighlightedItem({required this.item});
}

// Data
class ListEventLoadInitialPage<T extends BaseEntity, P> extends ListEvent<T> {
  final P? payload;
  ListEventLoadInitialPage({required this.payload});
}

class ListEventRefreshData<T extends BaseEntity> extends ListEvent<T> {}

class ListEventLoadNextPage<T extends BaseEntity> extends ListEvent<T> {}

class ListEventSearch<T extends BaseEntity> extends ListEvent<T> {
  final String searchText;
  ListEventSearch({required this.searchText});
}

class ListEventSearchNextPage<T extends BaseEntity> extends ListEvent<T> {}

class ListEventSearchRefresh<T extends BaseEntity> extends ListEvent<T> {}

class ListEventClearSearch<T extends BaseEntity> extends ListEvent<T> {}

class ListEventRemoveItem<T extends BaseEntity> extends ListEvent<T> {
  final T item;
  ListEventRemoveItem({required this.item});
}

class ListEventRemoveMultipleItems<T extends BaseEntity> extends ListEvent<T> {
  final List<T> items;
  ListEventRemoveMultipleItems({required this.items});
}

class ListEventExpandItem<T extends BaseEntity> extends ListEvent<T> {
  final T item;
  ListEventExpandItem({required this.item});
}

class ListEventCollapseItem<T extends BaseEntity> extends ListEvent<T> {
  final T item;
  ListEventCollapseItem({required this.item});
}

class ListEventScrollToItem<T extends BaseEntity> extends ListEvent<T> {
  final T item;
  final bool highlightItem;
  ListEventScrollToItem({required this.item, this.highlightItem = true});
}
