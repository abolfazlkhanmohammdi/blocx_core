// lib/src/blocs/list/bloc/list_state.dart
part of 'blocx_collection_bloc.dart';

abstract class BlocxCollectionState<T extends BlocxBaseEntity> extends BaseState {
  final List<T> list;
  final bool hasReachedEnd;
  final bool isLoadingNextPage;
  final bool isRefreshing;
  final bool isSearching;
  final dynamic additionalInfo;
  final Set<String> selectedItemIds;
  final Set<String> beingSelectedItemIds;
  final Set<String> highlightedItemIds;
  final Set<String> beingRemovedItemIds;
  final Set<String> expandedItemIds;

  const BlocxCollectionState({
    required this.list,
    required this.hasReachedEnd,
    required this.isLoadingNextPage,
    required this.isRefreshing,
    required this.isSearching,
    this.selectedItemIds = const {},
    this.beingSelectedItemIds = const {},
    this.highlightedItemIds = const {},
    this.beingRemovedItemIds = const {},
    this.expandedItemIds = const {},
    this.additionalInfo,
    required super.shouldRebuild,
    required super.shouldListen,
  });

  bool get isEmpty => list.isEmpty;
}

class BlocxCollectionStateLoading<T extends BlocxBaseEntity> extends BlocxCollectionState<T> {
  const BlocxCollectionStateLoading({
    super.list = const [],
    super.hasReachedEnd = false,
    super.isLoadingNextPage = false,
    super.isRefreshing = false,
    super.isSearching = false,
    super.selectedItemIds = const {},
    super.beingSelectedItemIds = const {},
    super.highlightedItemIds = const {},
    super.beingRemovedItemIds = const {},
  }) : super(shouldRebuild: true, shouldListen: false);
}

class BlocxCollectionStateLoaded<T extends BlocxBaseEntity> extends BlocxCollectionState<T> {
  const BlocxCollectionStateLoaded({
    required super.list,
    required super.hasReachedEnd,
    required super.isLoadingNextPage,
    required super.isRefreshing,
    required super.isSearching,
    required super.selectedItemIds,
    required super.beingSelectedItemIds,
    required super.highlightedItemIds,
    required super.beingRemovedItemIds,
    required super.expandedItemIds,
    super.additionalInfo,
  }) : super(shouldRebuild: true, shouldListen: false);

  BlocxCollectionStateLoaded<T> copyWith({
    List<T>? list,
    bool? hasReachedEnd,
    bool? isLoadingNextPage,
    bool? isRefreshing,
    bool? isSearching,
    Set<String>? selectedItemIds,
    Set<String>? beingSelectedItemIds,
    Set<String>? highlightedItemIds,
    Set<String>? beingRemovedItemIds,
    Set<String>? expandedItemIds,
    Object? additionalInfo,
  }) {
    return BlocxCollectionStateLoaded<T>(
      list: list ?? this.list,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      isLoadingNextPage: isLoadingNextPage ?? this.isLoadingNextPage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isSearching: isSearching ?? this.isSearching,
      selectedItemIds: selectedItemIds ?? this.selectedItemIds,
      beingSelectedItemIds: beingSelectedItemIds ?? this.beingSelectedItemIds,
      highlightedItemIds: highlightedItemIds ?? this.highlightedItemIds,
      beingRemovedItemIds: beingRemovedItemIds ?? this.beingRemovedItemIds,
      expandedItemIds: expandedItemIds ?? this.expandedItemIds,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }
}

class BlocxCollectionStateError<T extends BlocxBaseEntity> extends BlocxCollectionState<T> {
  final String message;

  const BlocxCollectionStateError({
    required this.message,
    super.list = const [],
    super.hasReachedEnd = false,
    super.isLoadingNextPage = false,
    super.isRefreshing = false,
    super.isSearching = false,
    super.selectedItemIds = const {},
    super.beingSelectedItemIds = const {},
    super.highlightedItemIds = const {},
    super.beingRemovedItemIds = const {},
  }) : super(shouldRebuild: true, shouldListen: false);
}

class BlocxCollectionStateScrollToItem<T extends BlocxBaseEntity> extends BlocxCollectionState<T> {
  final T item;
  final int index;

  const BlocxCollectionStateScrollToItem({required this.item, required this.index})
      : super(
          list: const [],
          hasReachedEnd: false,
          isLoadingNextPage: false,
          isRefreshing: false,
          isSearching: false,
          shouldRebuild: false,
          shouldListen: true,
        );
}

class BlocxCollectionStateSelectionChanged<T extends BlocxBaseEntity> extends BlocxCollectionState<T> {
  final SelectionChangedData<T> selectionData;
  const BlocxCollectionStateSelectionChanged({
    required this.selectionData,
    required super.list,
    required super.hasReachedEnd,
    required super.isLoadingNextPage,
    required super.isRefreshing,
    required super.isSearching,
    required super.selectedItemIds,
    required super.beingSelectedItemIds,
    required super.highlightedItemIds,
    required super.beingRemovedItemIds,
    required super.expandedItemIds,
  }) : super(shouldRebuild: false, shouldListen: true);
}
