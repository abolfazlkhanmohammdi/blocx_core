// lib/src/blocs/list/bloc/list_state.dart
part of 'blocx_list_bloc.dart';

abstract class BlocxListState<T extends BaseEntity> extends BaseState {
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

  const BlocxListState({
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

class BlocxListStateLoading<T extends BaseEntity> extends BlocxListState<T> {
  const BlocxListStateLoading({
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

class BlocxListStateLoaded<T extends BaseEntity> extends BlocxListState<T> {
  const BlocxListStateLoaded({
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

  BlocxListStateLoaded<T> copyWith({
    List<T>? list,
    bool? hasReachedEnd,
    bool? isLoadingNextPage,
    bool? isRefreshing,
    bool? isSearching,
    Set<String>? selectedItemIds,
    Set<String>? beingSelectedItemIds,
    Set<String>? highlightedItemIds,
    Set<String>? beingRemovedItemIds,
  }) {
    return BlocxListStateLoaded<T>(
      list: list ?? this.list,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      isLoadingNextPage: isLoadingNextPage ?? this.isLoadingNextPage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isSearching: isSearching ?? this.isSearching,
      selectedItemIds: selectedItemIds ?? this.selectedItemIds,
      beingSelectedItemIds: beingSelectedItemIds ?? this.beingSelectedItemIds,
      highlightedItemIds: highlightedItemIds ?? this.highlightedItemIds,
      beingRemovedItemIds: beingRemovedItemIds ?? this.beingRemovedItemIds,
      expandedItemIds: expandedItemIds,
    );
  }
}

class BlocxListStateError<T extends BaseEntity> extends BlocxListState<T> {
  final String message;

  const BlocxListStateError({
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

class BlocxListStateScrollToItem<T extends BaseEntity> extends BlocxListState<T> {
  final T item;
  final int index;

  const BlocxListStateScrollToItem({required this.item, required this.index})
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

class BlocxListStateSelectionChanged<T extends BaseEntity> extends BlocxListState<T> {
  final SelectionChangedData<T> selectionData;
  const BlocxListStateSelectionChanged({
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
