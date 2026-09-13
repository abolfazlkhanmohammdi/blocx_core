part of 'blocx_collection_bloc.dart';

/// Base class for all list-related events.
///
/// Extend this to define actions that mutate or interact with a [BlocxCollectionBloc].
class BlocxCollectionEvent<T extends BlocxBaseEntity> extends BlocxBaseEvent {}

/// Loads the initial page of data into the list.
///
/// [payload] can hold request parameters such as filters, paging info,
/// or repository instructions.
class BlocxCollectionEventLoadInitialPage<T extends BlocxBaseEntity, P> extends BlocxCollectionEvent<T> {
  /// Optional request payload (e.g. filter, page size, etc.).
  final P? payload;

  BlocxCollectionEventLoadInitialPage({required this.payload});
}

class BlocxCollectionEventUpdateItem<T extends BlocxBaseEntity> extends BlocxCollectionEvent<T> {
  final T item;
  BlocxCollectionEventUpdateItem({required this.item});
}

class BlocxCollectionEventReplaceList<T extends BlocxBaseEntity> extends BlocxCollectionEvent<T> {
  final List<T> newItems;
  BlocxCollectionEventReplaceList({required this.newItems});
}

class BlocxCollectionEventRemoveFromList<T extends BlocxBaseEntity> extends BlocxCollectionEvent<T> {
  final T item;
  BlocxCollectionEventRemoveFromList({required this.item});
}
