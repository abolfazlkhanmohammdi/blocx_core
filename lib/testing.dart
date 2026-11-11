import 'dart:async';
import 'dart:collection';

import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/collection_bloc.dart';
import 'package:blocx_core/form_bloc.dart';

/// In-memory test event hub with inspection and recording capabilities.
class BlocxTestEventHub extends BlocxSimpleEventHub {
  final List<BlocxAppEvent> _recordedEvents = [];

  /// All events recorded since creation or the last [clearRecordedEvents].
  List<BlocxAppEvent> get recordedEvents => List.unmodifiable(_recordedEvents);

  /// All recorded events matching type [T].
  List<T> recordedEventsOfType<T extends BlocxAppEvent>() =>
      List.unmodifiable(_recordedEvents.whereType<T>());

  /// All recorded entity command events targeting entity type [T].
  List<BlocxEntityEvent<T>> recordedEntityEvents<T extends BlocxBaseEntity>() =>
      List.unmodifiable(
        _recordedEvents
            .whereType<BlocxEntityEvent>()
            .where((e) => e.entities.any((item) => item is T))
            .map(
              (e) => BlocxEntityEvent<T>(
                id: e.id,
                command: e.command,
                origin: e.origin,
                entities: e.entities.whereType<T>().toList(),
                createdAt: e.createdAt,
              ),
            ),
      );

  /// Clears the recorded event history.
  void clearRecordedEvents() => _recordedEvents.clear();

  @override
  void emit(BlocxAppEvent event) {
    _recordedEvents.add(event);
    super.emit(event);
  }
}

/// A lightweight, immutable entity for testing collections and event hubs.
class BlocxTestEntity extends BlocxBaseEntity {
  final String id;
  final String name;
  final int order;
  final Map<String, dynamic>? data;

  const BlocxTestEntity({
    required this.id,
    this.name = '',
    this.order = 0,
    this.data,
  });

  @override
  String get identifier => id;

  BlocxTestEntity copyWith({
    String? id,
    String? name,
    int? order,
    Map<String, dynamic>? data,
  }) {
    return BlocxTestEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      order: order ?? this.order,
      data: data ?? this.data,
    );
  }

  @override
  String toString() => 'BlocxTestEntity(id: $id, name: $name, order: $order)';
}

/// Helper that creates a list of [count] [BlocxTestEntity] objects.
List<BlocxTestEntity> createTestEntities(int count, {String prefix = 'Item'}) {
  return List.generate(
    count,
    (i) => BlocxTestEntity(id: '$i', name: '$prefix $i', order: i),
  );
}

/// Field enum for [BlocxTestFormEntity].
enum BlocxTestFormField { field1, field2 }

/// A lightweight, immutable form entity for testing form blocs.
class BlocxTestFormEntity
    extends BlocxBaseFormEntity<BlocxTestFormEntity, BlocxTestFormField> {
  final String id;
  final String field1;
  final String field2;

  const BlocxTestFormEntity({
    this.id = '1',
    this.field1 = '',
    this.field2 = '',
  });

  @override
  String get identifier => id;

  @override
  BlocxTestFormEntity updateByKey(BlocxTestFormField key, dynamic value) =>
      switch (key) {
        BlocxTestFormField.field1 => copyWith(field1: value as String? ?? ''),
        BlocxTestFormField.field2 => copyWith(field2: value as String? ?? ''),
      };

  @override
  dynamic getValueByKey(BlocxTestFormField key) => switch (key) {
    BlocxTestFormField.field1 => field1,
    BlocxTestFormField.field2 => field2,
  };

  BlocxTestFormEntity copyWith({String? id, String? field1, String? field2}) {
    return BlocxTestFormEntity(
      id: id ?? this.id,
      field1: field1 ?? this.field1,
      field2: field2 ?? this.field2,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlocxTestFormEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          field1 == other.field1 &&
          field2 == other.field2;

  @override
  int get hashCode => Object.hash(id, field1, field2);
}

/// Fake paginated in-memory data source for unit testing.
class FakePaginatedSource<T extends BlocxBaseEntity> {
  final List<T> items;

  FakePaginatedSource([List<T>? initialItems])
    : items = initialItems != null ? List.of(initialItems) : <T>[];

  BlocxPage<T> getPage({required int offset, required int limit}) {
    final clampedOffset = offset.clamp(0, items.length);
    final endIndex = (clampedOffset + limit).clamp(0, items.length);
    final pageItems = items.sublist(clampedOffset, endIndex);
    final hasNext = endIndex < items.length;
    return BlocxPage<T>(
      items: pageItems,
      offset: clampedOffset,
      limit: limit,
      hasNext: hasNext,
    );
  }

  BlocxPage<T> getCursorPage({String? cursor, required int limit}) {
    final startIndex = cursor != null ? int.tryParse(cursor) ?? 0 : 0;
    final clampedStart = startIndex.clamp(0, items.length);
    final endIndex = (clampedStart + limit).clamp(0, items.length);
    final pageItems = items.sublist(clampedStart, endIndex);
    final nextCursor = endIndex < items.length ? endIndex.toString() : null;
    return BlocxPage<T>(
      items: pageItems,
      offset: clampedStart,
      limit: limit,
      nextCursor: nextCursor,
      hasNext: nextCursor != null,
    );
  }
}

/// Fake paginated use case for offset-based pagination.
class FakePaginatedUseCase<T extends BlocxBaseEntity>
    extends BlocxPaginatedUseCase<BlocxPaginatedInput, T> {
  final FakePaginatedSource<T> source;
  bool shouldFail;
  Object? failureError;
  Completer<void>? completer;
  Duration delay;
  final List<BlocxPaginatedInput> recordedInputs = [];

  FakePaginatedUseCase({
    FakePaginatedSource<T>? source,
    this.shouldFail = false,
    this.failureError,
    this.completer,
    this.delay = Duration.zero,
    super.eventHub,
    super.commandType,
    super.commandTypes,
  }) : source = source ?? FakePaginatedSource<T>();

  @override
  Future<BlocxUseCaseResult<BlocxPage<T>>> perform(
    BlocxPaginatedInput input,
  ) async {
    recordedInputs.add(input);
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (completer != null) await completer!.future;
    if (shouldFail) throw failureError ?? Exception('Paginated task failed');
    final page = source.getPage(offset: input.offset, limit: input.limit);
    return success(page);
  }
}

/// Fake cursor-based paginated use case.
class FakeCursorPaginatedUseCase<T extends BlocxBaseEntity>
    extends BlocxCursorPaginatedUseCase<BlocxCursorPaginatedInput, T> {
  final FakePaginatedSource<T> source;
  bool shouldFail;
  Object? failureError;
  Completer<void>? completer;
  Duration delay;
  final List<BlocxCursorPaginatedInput> recordedInputs = [];

  FakeCursorPaginatedUseCase({
    FakePaginatedSource<T>? source,
    this.shouldFail = false,
    this.failureError,
    this.completer,
    this.delay = Duration.zero,
    super.eventHub,
    super.commandType,
    super.commandTypes,
  }) : source = source ?? FakePaginatedSource<T>();

  @override
  Future<BlocxUseCaseResult<BlocxPage<T>>> perform(
    BlocxCursorPaginatedInput input,
  ) async {
    recordedInputs.add(input);
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (completer != null) await completer!.future;
    if (shouldFail) {
      throw failureError ?? Exception('Cursor paginated task failed');
    }
    final page = source.getCursorPage(cursor: input.cursor, limit: input.limit);
    return success(page);
  }
}

/// Fake search use case.
class FakeSearchUseCase<T extends BlocxBaseEntity>
    extends BlocxSearchUseCase<BlocxSearchInput, T> {
  final FakePaginatedSource<T> source;
  final bool Function(T item, String query)? matcher;
  bool shouldFail;
  Object? failureError;
  Completer<void>? completer;
  final List<BlocxSearchInput> recordedInputs = [];

  FakeSearchUseCase({
    FakePaginatedSource<T>? source,
    this.matcher,
    this.shouldFail = false,
    this.failureError,
    this.completer,
    super.eventHub,
  }) : source = source ?? FakePaginatedSource<T>();

  @override
  Future<BlocxUseCaseResult<BlocxPage<T>>> perform(
    BlocxSearchInput input,
  ) async {
    recordedInputs.add(input);
    if (completer != null) await completer!.future;
    if (shouldFail) throw failureError ?? Exception('Search task failed');

    final query = input.searchText?.toLowerCase() ?? '';
    final matching = source.items.where((item) {
      if (matcher != null) return matcher!(item, query);
      return item.identifier.toLowerCase().contains(query);
    }).toList();

    final clampedOffset = input.offset.clamp(0, matching.length);
    final endIndex = (clampedOffset + input.limit).clamp(0, matching.length);
    final pageItems = matching.sublist(clampedOffset, endIndex);

    return success(
      BlocxPage<T>(
        items: pageItems,
        offset: clampedOffset,
        limit: input.limit,
        hasNext: endIndex < matching.length,
      ),
    );
  }
}

/// General-purpose fake use case for submit and operation tasks.
class FakeUseCase<Input, Output> extends BlocxBaseUseCase<Input, Output> {
  final Output Function(Input input)? handler;
  Output? returnValue;
  bool shouldFail;
  Object? failureError;
  Completer<void>? completer;
  Duration delay;
  final List<Input> recordedInputs = [];

  FakeUseCase({
    this.handler,
    this.returnValue,
    this.shouldFail = false,
    this.failureError,
    this.completer,
    this.delay = Duration.zero,
    super.eventHub,
    super.commandType,
    super.commandTypes,
  });

  @override
  Future<BlocxUseCaseResult<Output>> perform(Input input) async {
    recordedInputs.add(input);
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (completer != null) await completer!.future;
    if (shouldFail) throw failureError ?? Exception('UseCase task failed');
    final result = handler != null ? handler!(input) : returnValue as Output;
    return success(result);
  }
}

/// Helper that builds a [BlocxPaginatedUseCaseTask] wrapping [useCase].
BlocxPaginatedUseCaseTask<BlocxPaginatedInput, T> createFakePaginatedTask<
  T extends BlocxBaseEntity
>({required FakePaginatedUseCase<T> useCase}) {
  return BlocxPaginatedUseCaseTask<BlocxPaginatedInput, T>(
    useCase: useCase,
    inputBuilder: (offset, limit) =>
        BlocxPaginatedInput(offset: offset, limit: limit),
  );
}

/// Helper that builds a [BlocxCursorPaginatedUseCaseTask] wrapping [useCase].
BlocxCursorPaginatedUseCaseTask<BlocxCursorPaginatedInput, T>
createFakeCursorPaginatedTask<T extends BlocxBaseEntity>({
  required FakeCursorPaginatedUseCase<T> useCase,
}) {
  return BlocxCursorPaginatedUseCaseTask<BlocxCursorPaginatedInput, T>(
    useCase: useCase,
    inputBuilder: (cursor, limit) =>
        BlocxCursorPaginatedInput(cursor: cursor, limit: limit),
  );
}

/// Helper that builds a [BlocxUseCaseTask] wrapping [useCase].
BlocxUseCaseTask<Input, Output> createFakeSubmitTask<Input, Output>({
  required FakeUseCase<Input, Output> useCase,
  required Input Function() inputBuilder,
}) {
  return BlocxUseCaseTask<Input, Output>(
    useCase: useCase,
    inputBuilder: inputBuilder,
  );
}

/// Builds a [BlocxCollectionState] snapshot for unit and widget tests without
/// repeating boilerplate defaults.
///
/// - When [isInitialLoading] is `true`, returns [BlocxCollectionStateLoading].
/// - Otherwise when [initialError] is non-null, returns
///   [BlocxCollectionStateError] with [initialError] populated.
/// - Otherwise returns [BlocxCollectionStateLoaded].
BlocxCollectionState<T> buildTestCollectionState<T extends BlocxBaseEntity>({
  List<T> list = const [],
  bool hasReachedEnd = true,
  bool isLoadingNextPage = false,
  bool isRefreshing = false,
  bool isSearching = false,
  bool isInitialLoading = false,
  ReadableError? initialError,
  Set<String> selectedItemIds = const {},
  Set<String> beingSelectedItemIds = const {},
  Set<String> highlightedItemIds = const {},
  Set<String> beingRemovedItemIds = const {},
  Set<String> expandedItemIds = const {},
  dynamic additionalInfo,
  Object? filter,
  Map<String, dynamic> activeFilters = const {},
  String? searchQuery,
}) {
  final unmodifiableList = List<T>.unmodifiable(list);
  final unmodifiableSelected = Set<String>.unmodifiable(selectedItemIds);
  final unmodifiableBeingSelected = Set<String>.unmodifiable(
    beingSelectedItemIds,
  );
  final unmodifiableHighlighted = Set<String>.unmodifiable(highlightedItemIds);
  final unmodifiableBeingRemoved = Set<String>.unmodifiable(
    beingRemovedItemIds,
  );
  final unmodifiableExpanded = Set<String>.unmodifiable(expandedItemIds);
  final unmodifiableFilters = Map<String, dynamic>.unmodifiable(activeFilters);

  if (isInitialLoading) {
    return BlocxCollectionStateLoading<T>(
      list: unmodifiableList,
      hasReachedEnd: hasReachedEnd,
      isLoadingNextPage: isLoadingNextPage,
      isRefreshing: isRefreshing,
      isSearching: isSearching,
      selectedItemIds: unmodifiableSelected,
      beingSelectedItemIds: unmodifiableBeingSelected,
      highlightedItemIds: unmodifiableHighlighted,
      beingRemovedItemIds: unmodifiableBeingRemoved,
      expandedItemIds: unmodifiableExpanded,
      additionalInfo: additionalInfo,
      initialError: initialError,
      searchQuery: searchQuery,
      filter: filter,
      activeFilters: unmodifiableFilters,
    );
  }

  if (initialError != null) {
    return BlocxCollectionStateError<T>(
      message: initialError.message,
      initialError: initialError,
      list: unmodifiableList,
      hasReachedEnd: hasReachedEnd,
      isLoadingNextPage: isLoadingNextPage,
      isRefreshing: isRefreshing,
      isSearching: isSearching,
      selectedItemIds: unmodifiableSelected,
      beingSelectedItemIds: unmodifiableBeingSelected,
      highlightedItemIds: unmodifiableHighlighted,
      beingRemovedItemIds: unmodifiableBeingRemoved,
      expandedItemIds: unmodifiableExpanded,
      additionalInfo: additionalInfo,
      searchQuery: searchQuery,
      filter: filter,
      activeFilters: unmodifiableFilters,
    );
  }

  return BlocxCollectionStateLoaded<T>(
    list: unmodifiableList,
    hasReachedEnd: hasReachedEnd,
    isLoadingNextPage: isLoadingNextPage,
    isRefreshing: isRefreshing,
    isSearching: isSearching,
    selectedItemIds: unmodifiableSelected,
    beingSelectedItemIds: unmodifiableBeingSelected,
    highlightedItemIds: unmodifiableHighlighted,
    beingRemovedItemIds: unmodifiableBeingRemoved,
    expandedItemIds: unmodifiableExpanded,
    additionalInfo: additionalInfo,
    searchQuery: searchQuery,
    filter: filter,
    activeFilters: unmodifiableFilters,
  );
}

/// Convenience factory wrapper for seeding [BlocxCollectionState] in tests.
abstract final class BlocxCollectionStateSeeder {
  /// Delegates to [buildTestCollectionState].
  static BlocxCollectionState<T> build<T extends BlocxBaseEntity>({
    List<T> list = const [],
    bool hasReachedEnd = true,
    bool isLoadingNextPage = false,
    bool isRefreshing = false,
    bool isSearching = false,
    bool isInitialLoading = false,
    ReadableError? initialError,
    Set<String> selectedItemIds = const {},
    Set<String> beingSelectedItemIds = const {},
    Set<String> highlightedItemIds = const {},
    Set<String> beingRemovedItemIds = const {},
    Set<String> expandedItemIds = const {},
    dynamic additionalInfo,
    Object? filter,
    Map<String, dynamic> activeFilters = const {},
    String? searchQuery,
  }) => buildTestCollectionState<T>(
    list: list,
    hasReachedEnd: hasReachedEnd,
    isLoadingNextPage: isLoadingNextPage,
    isRefreshing: isRefreshing,
    isSearching: isSearching,
    isInitialLoading: isInitialLoading,
    initialError: initialError,
    selectedItemIds: selectedItemIds,
    beingSelectedItemIds: beingSelectedItemIds,
    highlightedItemIds: highlightedItemIds,
    beingRemovedItemIds: beingRemovedItemIds,
    expandedItemIds: expandedItemIds,
    additionalInfo: additionalInfo,
    filter: filter,
    activeFilters: activeFilters,
    searchQuery: searchQuery,
  );
}

/// Builds a [BlocxFormState] snapshot for unit and widget tests without
/// repeating boilerplate defaults.
///
/// - When [isSubmittingForm] is `true`, returns [BlocxFormStateSubmittingForm].
/// - Otherwise returns [BlocxFormStateLoaded].
BlocxFormState<F, E>
buildTestFormState<F extends BlocxBaseFormEntity<F, E>, E extends Enum>({
  required F formData,
  F? initialData,
  Map<E, Set<String>> errors = const {},
  Set<E> fieldsFetchingInfo = const {},
  Set<E> checkingUniqueFields = const {},
  bool isSubmittingForm = false,
  bool isFormValid = true,
  int step = 0,
  bool comesFromPreviousStep = false,
  String? submittingButtonText,
}) {
  final unmodifiableErrors = UnmodifiableMapView<E, Set<String>>({
    for (final entry in errors.entries)
      entry.key: Set<String>.unmodifiable(entry.value),
  });

  if (isSubmittingForm) {
    return BlocxFormStateSubmittingForm<F, E>(
      step: step,
      formData: formData,
      initialData: initialData,
      buttonText: submittingButtonText,
    );
  }

  return BlocxFormStateLoaded<F, E>(
    formData: formData,
    initialData: initialData,
    step: step,
    comesFromPreviousStep: comesFromPreviousStep,
    errors: unmodifiableErrors,
    fieldsFetchingInfo: Set<E>.unmodifiable(fieldsFetchingInfo),
    checkingUniqueFields: Set<E>.unmodifiable(checkingUniqueFields),
    isFormValid: isFormValid,
  );
}

/// Convenience factory wrapper for seeding [BlocxFormState] in tests.
abstract final class BlocxFormStateSeeder {
  /// Delegates to [buildTestFormState].
  static BlocxFormState<F, E>
  build<F extends BlocxBaseFormEntity<F, E>, E extends Enum>({
    required F formData,
    F? initialData,
    Map<E, Set<String>> errors = const {},
    Set<E> fieldsFetchingInfo = const {},
    Set<E> checkingUniqueFields = const {},
    bool isSubmittingForm = false,
    bool isFormValid = true,
    int step = 0,
    bool comesFromPreviousStep = false,
    String? submittingButtonText,
  }) => buildTestFormState<F, E>(
    formData: formData,
    initialData: initialData,
    errors: errors,
    fieldsFetchingInfo: fieldsFetchingInfo,
    checkingUniqueFields: checkingUniqueFields,
    isSubmittingForm: isSubmittingForm,
    isFormValid: isFormValid,
    step: step,
    comesFromPreviousStep: comesFromPreviousStep,
    submittingButtonText: submittingButtonText,
  );
}
