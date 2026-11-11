// lib/src/blocs/list/bloc/list_state.dart
part of 'blocx_collection_bloc.dart';

abstract class BlocxCollectionState<T extends BlocxBaseEntity>
    extends BlocxBaseState {
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
  final ReadableError? initialError;
  final String? searchQuery;
  final Object? filter;
  final Map<String, dynamic> activeFilters;

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
    this.initialError,
    this.searchQuery,
    this.filter,
    this.activeFilters = const {},
    required super.shouldRebuild,
    required super.shouldListen,
  });

  bool get isEmpty => list.isEmpty;

  /// Shorthand alias for [initialError].
  ReadableError? get initialLoadError => initialError;

  /// Whether the collection is currently in its initial loading state.
  bool get isInitialLoading => this is BlocxCollectionStateLoading<T>;

  /// Whether the latest initial, search, or empty-refresh load failed.
  bool get hasInitialError =>
      this is BlocxCollectionStateError<T> || initialError != null;

  /// True when at least one non-null filter is active or a non-empty search
  /// query is applied.
  bool get hasActiveQueryOrFilters {
    final hasSearch = searchQuery != null && searchQuery!.trim().isNotEmpty;
    final hasMapFilters = activeFilters.values.any((value) => value != null);
    final currentFilter = filter;
    final hasTypedFilter = switch (currentFilter) {
      null => false,
      final Map<dynamic, dynamic> map => map.values.any(
        (value) => value != null,
      ),
      final Iterable<dynamic> iterable => iterable.isNotEmpty,
      _ => true,
    };
    return hasSearch || hasMapFilters || hasTypedFilter;
  }

  /// True when the list is empty solely because of active search/filter criteria.
  bool get isEmptyFilteredResult =>
      list.isEmpty &&
      !isInitialLoading &&
      !isSearching &&
      !isRefreshing &&
      !hasInitialError &&
      hasActiveQueryOrFilters;

  /// Retrieves a typed filter value from [activeFilters], or `null` if absent
  /// or mismatched in type.
  F? filterValue<F>(String key) {
    final val = activeFilters[key];
    return val is F ? val : null;
  }

  /// Checks whether [activeFilters] contains [key] with a non-null value,
  /// or matches [expectedValue] when provided.
  bool hasFilter(String key, [Object? expectedValue]) {
    if (!activeFilters.containsKey(key)) return false;
    if (expectedValue == null) return activeFilters[key] != null;
    return activeFilters[key] == expectedValue;
  }
}

class BlocxCollectionStateLoading<T extends BlocxBaseEntity>
    extends BlocxCollectionState<T> {
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
    super.expandedItemIds = const {},
    super.additionalInfo,
    super.initialError,
    super.searchQuery,
    super.filter,
    super.activeFilters = const {},
  }) : super(shouldRebuild: true, shouldListen: false);
}

class BlocxCollectionStateLoaded<T extends BlocxBaseEntity>
    extends BlocxCollectionState<T> {
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
    super.initialError,
    super.searchQuery,
    super.filter,
    super.activeFilters = const {},
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
    ReadableError? initialError,
    bool clearInitialError = false,
    String? searchQuery,
    Object? filter,
    Map<String, dynamic>? activeFilters,
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
      initialError: clearInitialError
          ? null
          : (initialError ?? this.initialError),
      searchQuery: searchQuery ?? this.searchQuery,
      filter: filter ?? this.filter,
      activeFilters: activeFilters ?? this.activeFilters,
    );
  }
}

class BlocxCollectionStateError<T extends BlocxBaseEntity>
    extends BlocxCollectionState<T> {
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
    super.expandedItemIds = const {},
    super.additionalInfo,
    super.initialError,
    super.searchQuery,
    super.filter,
    super.activeFilters = const {},
  }) : super(shouldRebuild: true, shouldListen: false);
}

class BlocxCollectionStateScrollToItem<T extends BlocxBaseEntity>
    extends BlocxCollectionState<T> {
  final T item;
  final int index;

  const BlocxCollectionStateScrollToItem({
    required this.item,
    required this.index,
  }) : super(
         list: const [],
         hasReachedEnd: false,
         isLoadingNextPage: false,
         isRefreshing: false,
         isSearching: false,
         shouldRebuild: false,
         shouldListen: true,
       );
}

class BlocxCollectionStateSelectionChanged<T extends BlocxBaseEntity>
    extends BlocxCollectionState<T> {
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
    super.searchQuery,
    super.filter,
    super.activeFilters = const {},
  }) : super(shouldRebuild: false, shouldListen: true);
}
