// lib/src/list/bloc/list_state.dart
part of 'list_bloc.dart';

abstract class ListState<T extends BaseEntity> extends BaseState {
  final List<T> list;
  final bool hasReachedEnd;
  final bool isLoadingNextPage;
  final bool isRefreshing;
  final bool isSearching;

  final Set<String> selectedItemIds;
  final Set<String> beingSelectedItemIds;
  final Set<String> highlightedItemIds;
  final Set<String> beingRemovedItemIds;
  final Set<String> expandedItemIds;

  const ListState({
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
    required super.shouldRebuild,
    required super.shouldListen,
  });

  bool get isEmpty => list.isEmpty;

  get additionalInfo => null;
}

class ListStateLoading<T extends BaseEntity> extends ListState<T> {
  const ListStateLoading({
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

class ListStateLoaded<T extends BaseEntity> extends ListState<T> {
  const ListStateLoaded({
    required super.list,
    required super.hasReachedEnd,
    required super.isLoadingNextPage,
    required super.isRefreshing,
    required super.isSearching,
    super.selectedItemIds = const {},
    super.beingSelectedItemIds = const {},
    super.highlightedItemIds = const {},
    super.beingRemovedItemIds = const {},
    super.expandedItemIds = const {},
  }) : super(shouldRebuild: true, shouldListen: false);

  ListStateLoaded<T> copyWith({
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
    return ListStateLoaded<T>(
      list: list ?? this.list,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      isLoadingNextPage: isLoadingNextPage ?? this.isLoadingNextPage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isSearching: isSearching ?? this.isSearching,
      selectedItemIds: selectedItemIds ?? this.selectedItemIds,
      beingSelectedItemIds: beingSelectedItemIds ?? this.beingSelectedItemIds,
      highlightedItemIds: highlightedItemIds ?? this.highlightedItemIds,
      beingRemovedItemIds: beingRemovedItemIds ?? this.beingRemovedItemIds,
    );
  }
}

class ListStateError<T extends BaseEntity> extends ListState<T> {
  final String message;

  const ListStateError({
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

class ListStateScrollToItem<T extends BaseEntity> extends ListState<T> {
  final T item;
  final int index;

  const ListStateScrollToItem({required this.item, required this.index})
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
