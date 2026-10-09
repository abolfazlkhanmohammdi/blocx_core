# Collection BLoC & Mixins Reference (`blocx_core`)

## Table of Contents
1. [`BlocxCollectionBloc<Entity, Payload>` Overview](#1-blocxcollectionblocentity-payload-overview)
2. [`BlocxCollectionCoreMixin` Properties, Tasks & Helpers](#2-blocxcollectioncoremixin-properties-tasks--helpers)
3. [Core Collection Events](#3-core-collection-events)
4. [Collection States & `ListStateExtensions`](#4-collection-states--liststateextensions)
5. [All 10 Collection Mixins (Complete Reference)](#5-all-10-collection-mixins-complete-reference)
   - [5.1 `BlocxCollectionInfiniteMixin` (Next-Page Pagination)](#51-blocxcollectioninfinitemixin-next-page-pagination)
   - [5.2 `BlocxCollectionRefreshableMixin` (Pull-to-Refresh)](#52-blocxcollectionrefreshablemixin-pull-to-refresh)
   - [5.3 `BlocxCollectionSearchableMixin` (Debounced Search & Search Pagination)](#53-blocxcollectionsearchablemixin-debounced-search--search-pagination)
   - [5.4 `BlocxCollectionSelectableMixin` (Single/Multi Selection & Server Sync)](#54-blocxcollectionselectablemixin-singlemulti-selection--server-sync)
   - [5.5 `BlocxCollectionDeletableMixin` (Single & Bulk Deletion)](#55-blocxcollectiondeletablemixin-single--bulk-deletion)
   - [5.6 `BlocxCollectionHighlightableMixin` (Temporary Item Highlight)](#56-blocxcollectionhighlightablemixin-temporary-item-highlight)
   - [5.7 `BlocxCollectionExpandableMixin` (Expand / Collapse Items)](#57-blocxcollectionexpandablemixin-expand--collapse-items)
   - [5.8 `BlocxCollectionScrollableMixin` (Programmatic Scroll-to-Item)](#58-blocxcollectionscrollablemixin-programmatic-scroll-to-item)
   - [5.9 `BlocxCollectionFilterMixin` (Debounced Filter & Reload)](#59-blocxcollectionfiltermixin-debounced-filter--reload)
   - [5.10 `BlocxCollectionSyncStreamMixin` (Real-Time EventHub CRUD Sync)](#510-blocxcollectionsyncstreammixin-real-time-eventhub-crud-sync)

---

## 1. `BlocxCollectionBloc<Entity, Payload>` Overview

Import:
```dart
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/collection_bloc.dart';
```

Declaration:
```dart
abstract class BlocxCollectionBloc<Entity extends BlocxBaseEntity, Payload>
    extends BlocxBaseBloc<BlocxCollectionEvent<Entity>, BlocxCollectionState<Entity>>
    with BlocxCollectionCoreMixin<Entity, Payload>
```
- **2 Type Parameters**:
  - `Entity`: Must extend `BlocxBaseEntity`.
  - `Payload`: Type passed in `BlocxCollectionEventLoadInitialPage<Entity, Payload>(payload: ...)`. Use `void` when no payload is needed.
- **Constructor**: `BlocxCollectionBloc()` takes **no arguments** (`super()`). It starts in `BlocxCollectionStateLoading<Entity>()` and automatically invokes `initCoreMixin()` and all mixin `init*()` hooks.

---

## 2. `BlocxCollectionCoreMixin` Properties, Tasks & Helpers

### Pagination Task Configuration
- `BlocxPaginatedUseCaseTask<BlocxPaginatedInput, Entity>? get paginationTask => null;`
  Override this to provide the default paginated task shared by initial load, next-page load (`BlocxCollectionInfiniteMixin`), and pull-to-refresh (`BlocxCollectionRefreshableMixin`).
- `BlocxPaginatedUseCaseTask<BlocxPaginatedInput, Entity>? get loadInitialPageTask => paginationTask;`
  Override only if initial loading uses a different UseCase from `paginationTask`.
- `int get limit => 20;` (page size per request)
- `int get offset => _loadedCount;` (tracks items loaded from datasource independently of local mutations to prevent pagination offset drift)
- `int get loadGeneration => _loadGeneration;` (monotonic load generation counter used to discard responses from obsolete asynchronous operations)

### State & List Properties
- `Payload? payload`: Stored from the latest `BlocxCollectionEventLoadInitialPage`.
- `UnmodifiableListView<Entity> get list`: Current items in the collection.
- `bool isLoadingNextPage`, `bool hasReachedEnd`, `bool isSearching`, `bool isRefreshing`
- `dynamic get additionalInfo => null`: Optional custom metadata attached to every `BlocxCollectionStateLoaded`.

### List Manipulation & Lifecycle Hooks
- `Future<List<Entity>> modifyListBeforeInsert(List<Entity> data) async => data;` (override to transform/filter fetched pages before insertion)
- `void doAfterInsert() {}` (hook called after `insertToList`, e.g., to sort the list)
- `void clearList()` (clears `list` and resets `_loadedCount` to 0)
- `void replaceList(List<Entity> newList)`
- `void replaceItemInList(Entity item)`
- `void removeItemFromList(Entity item)`
- `void insertToListSingle(Entity item, {int index = 0})`
- `void sortList(Comparator<Entity> comparator)`
- `void emitState(Emitter<BlocxCollectionState<Entity>> emit)` (emits `BlocxCollectionStateLoaded<Entity>` with all current list and mixin sets)

---

## 3. Core Collection Events

| Event Class | Constructor / Properties | Behavior |
|---|---|---|
| `BlocxCollectionEventLoadInitialPage<T, P>` | `BlocxCollectionEventLoadInitialPage({required P? payload})` | Handled with `restartable()`. Stores `payload`, increments `loadGeneration`, emits `BlocxCollectionStateLoading<T>()`, executes `loadInitialPageTask(offset: 0, limit: limit)`, clears old list, inserts items, applies initial selection if selectable, and emits `BlocxCollectionStateLoaded<T>`. Discards stale responses if generation has advanced. |
| `BlocxCollectionEventAddItem<T>` | `BlocxCollectionEventAddItem({required T item, int index = 0})` | Inserts `item` into `list` at `index.clamp(0, list.length)` and emits `BlocxCollectionStateLoaded<T>`. |
| `BlocxCollectionEventUpdateItem<T>` | `BlocxCollectionEventUpdateItem({required T item})` | Finds item in `list` by `identifier` and replaces it (no-op if not found). Triggers highlight if `isHighlightable` is `true`, and emits state. |
| `BlocxCollectionEventReplaceList<T>` | `BlocxCollectionEventReplaceList({required List<T> newItems})` | Replaces the entire `list` with `newItems` and emits state. |
| `BlocxCollectionEventRemoveFromList<T>` | `BlocxCollectionEventRemoveFromList({required T item})` | Removes `item` locally by `identifier` and emits state. |

---

## 4. Collection States & `ListStateExtensions`

### State Classes
- `BlocxCollectionStateLoading<T>` (`shouldRebuild: true, shouldListen: false`)
- `BlocxCollectionStateLoaded<T>` (`shouldRebuild: true, shouldListen: false`)
- `BlocxCollectionStateError<T>({required String message, ...})` (`shouldRebuild: true, shouldListen: false`)
- `BlocxCollectionStateScrollToItem<T>({required T item, required int index})` (`shouldRebuild: false, shouldListen: true`)
- `BlocxCollectionStateSelectionChanged<T>({required SelectionChangedData<T> selectionData, ...})` (`shouldRebuild: false, shouldListen: true`)

### `ListStateExtensions<T>` on `BlocxCollectionState<T>`
- **Selection**: `state.isSelected(item)`, `state.isSelectedId(id)`, `state.hasSelection`, `state.selectedCount`, `state.selectedItems`, `state.firstSelectedItemOrNull()`, `state.isBeingSelected(item)`, `state.isBeingSelectedId(id)`
- **Highlight**: `state.isHighlighted(item)`, `state.isHighlightedId(id)`
- **Deletion**: `state.isBeingRemoved(item)`, `state.isBeingRemovedId(id)`
- **Expansion**: `state.isExpanded(item)`
- **Utilities**: `state.isEmpty`, `state.indexOfId(id)`, `state.isBusy` (`isRefreshing || isLoadingNextPage || isSearching`)

---

## 5. All 10 Collection Mixins (Complete Reference)

### 5.1 `BlocxCollectionInfiniteMixin<Entity, Payload>` (Next-Page Pagination)
- **Events**: `BlocxCollectionEventLoadNextPage<Entity>()`
- **Overrides**:
  - `BlocxPaginatedUseCaseTask<BlocxPaginatedInput, Entity>? get loadNextPageTask => paginationTask;`
- **Behavior**: Handled with `droppable()`. Guards against `hasReachedEnd || isLoadingNextPage`. If `isSearchable` and `searchText.isNotEmpty`, automatically dispatches `BlocxCollectionEventSearchNextPage<Entity>()`. Otherwise executes `loadNextPageTask(offset: offset, limit: limit)` and appends items. Discards stale responses if load generation has advanced.

### 5.2 `BlocxCollectionRefreshableMixin<Entity, Payload>` (Pull-to-Refresh)
- **Events**: `BlocxCollectionEventRefreshData<Entity>({bool clearSelection = true})`
- **Overrides**:
  - `BlocxPaginatedUseCaseTask<BlocxPaginatedInput, Entity>? get refreshPageUseCaseTask => paginationTask;`
  - `double get refreshThreshold => 64.0;`
- **Behavior**: Handled with `restartable()`. Increments `loadGeneration`. Clears selection if `clearSelection && isSelectable`. Delegates to `BlocxCollectionEventSearchRefresh<Entity>()` if a search query is active. Otherwise executes `refreshPageUseCaseTask(offset: 0, limit: limit)`, clears the list, and inserts fresh items. Discards stale responses if generation has advanced.

### 5.3 `BlocxCollectionSearchableMixin<Entity, Payload>` (Debounced Search & Search Pagination)
- **Events**:
  - `BlocxCollectionEventSearch<Entity>({required String searchText})` (debounced by `searchDebounceDuration`)
  - `BlocxCollectionEventClearSearch<Entity>()`
  - `BlocxCollectionEventSearchNextPage<Entity>()`
  - `BlocxCollectionEventSearchRefresh<Entity>()`
- **Required Override**:
  ```dart
  @override
  BlocxPaginatedUseCaseTask<BlocxSearchInput, ProductEntity>? get searchUseCaseTask {
    return BlocxPaginatedUseCaseTask<BlocxSearchInput, ProductEntity>(
      useCase: searchProductsUseCase,
      inputBuilder: (offset, limit) => BlocxSearchInput(
        searchText: searchText,
        offset: offset,
        limit: limit,
      ),
    );
  }
  ```
- **Optional Overrides**:
  - `Duration get searchDebounceDuration => const Duration(milliseconds: 300);`
- **Properties**: `String searchText = '';` (automatically updated when `BlocxCollectionEventSearch` runs; if `searchText.isEmpty`, clears list and reloads initial page via `BlocxCollectionEventLoadInitialPage(payload: payload)`).

### 5.4 `BlocxCollectionSelectableMixin<Entity, Payload>` (Single/Multi Selection & Server Sync)
- **Events**:
  - `BlocxCollectionEventSelectItem<Entity>({required Entity item})`
  - `BlocxCollectionEventDeselectItem<Entity>({required Entity item})`
  - `BlocxCollectionEventSelectMultipleItems<Entity>({required List<Entity> items})`
  - `BlocxCollectionEventDeselectMultipleItems<Entity>({required List<Entity> items})`
  - `BlocxCollectionEventClearSelection<Entity>()`
- **Overrides**:
  - `bool get isSingleSelect => true;` (set to `false` for multi-select)
  - `bool get syncWithServerOnSelection => false;`
  - `BlocxUseCaseTask<Object?, bool>? selectItemTask(Entity item) => null;` (used when `syncWithServerOnSelection` is `true`; automatically rolls back selection on failure)
  - `BlocxUseCaseTask<Object?, bool>? deselectItemTask(Entity item) => null;`
  - `FutureOr<Set<String>> getInitiallySelectedItemIds() async => <String>{};`
- **Emitted Notification State**: Emits `BlocxCollectionStateSelectionChanged<Entity>` with `SelectionChangedData<Entity>(selection: selectedItems, wasSelected: ..., item: item)`.

### 5.5 `BlocxCollectionDeletableMixin<Entity, Payload>` (Single & Bulk Deletion)
- **Events**:
  - `BlocxCollectionEventRemoveItem<Entity>(Entity item)` *(positional `item`)*
  - `BlocxCollectionEventRemoveMultipleItems<Entity>({required List<Entity> items})`
  - `BlocxCollectionEventRemoveItemById<Entity>({required String identifier})` *(local-only removal without remote task)*
- **Overrides**:
  ```dart
  @override
  BlocxUseCaseTask<Object?, bool>? deleteItemTask(ProductEntity item) {
    return BlocxUseCaseTask<ProductEntity, bool>(
      useCase: deleteProductUseCase,
      inputBuilder: () => item,
    );
  }
  ```
  - `BlocxUseCaseTask<Object?, bool>? deleteMultipleItemsTask(List<Entity> items) => null;` (if `null`, falls back to calling `deleteItemTask` per item)
  - `bool get displayDeletedSnackbar => false;`
  - `void onItemDeleted(Entity item, bool deleted)`
  - `void onMultipleItemsDeleted(List<Entity> items, Map<Entity, bool> results)`

### 5.6 `BlocxCollectionHighlightableMixin<Entity, Payload>` (Temporary Item Highlight)
- **Events**:
  - `BlocxCollectionEventHighlightItem<Entity>({required Entity item})`
  - `BlocxCollectionEventClearHighlightedItem<Entity>({required Entity item})`
- **Overrides**:
  - `bool get autoClearHighlight => true;`
  - `Duration get highlightDuration => const Duration(seconds: 3);`

### 5.7 `BlocxCollectionExpandableMixin<Entity, Payload>` (Expand / Collapse Items)
- **Events**:
  - `BlocxCollectionEventExpandItem<Entity>(Entity item)` *(positional `item`)*
  - `BlocxCollectionEventCollapseItem<Entity>(Entity item)` *(positional `item`)*
  - `BlocxCollectionEventToggleItemExpansion<Entity>(Entity item)` *(positional `item`)*

### 5.8 `BlocxCollectionScrollableMixin<Entity, Payload>` (Programmatic Scroll-to-Item)
- **Events**:
  - `BlocxCollectionEventScrollToItem<Entity>({required Entity item, bool highlightItem = false})`
  - `BlocxCollectionEventScrollToIdentifier<Entity>({required String identifier, bool highlightItem = false})`
  - `BlocxCollectionEventHighlightScrolledToItems<Entity>()`

### 5.9 `BlocxCollectionFilterMixin<Entity, Payload, Filter>` (Debounced Filter & Reload)
- **Note**: Takes **3** type parameters: `<Entity, Payload, Filter>`.
- **Events**: `BlocxCollectionEventFilter<Entity, Filter>(Filter filter)` (debounced 500ms; stores `_filter` and dispatches `BlocxCollectionEventLoadInitialPage(payload: payload)`).
- **Helper**: `Filter? getFilter() => _filter;`

### 5.10 `BlocxCollectionSyncStreamMixin<T extends BlocxBaseEntity, P>` (Real-Time EventHub CRUD Sync)
Listens to `eventHub.onEntity<T>(commands: listenedCommands)` and automatically synchronizes the collection whenever any UseCase broadcasts a `BlocxEntityEvent<T>`.

```dart
class ProductsCollectionBloc extends BlocxCollectionBloc<ProductEntity, void>
    with BlocxCollectionSyncStreamMixin<ProductEntity, void> {
  @override
  final BlocxEventHub eventHub;

  ProductsCollectionBloc({required this.eventHub}) : super();

  @override
  List<BlocxCommandType> get listenedCommands => const <BlocxCommandType>[
    BlocxCommandType.create,
    BlocxCommandType.read,
    BlocxCommandType.update,
    BlocxCommandType.delete,
  ];

  @override
  bool shouldSyncEntity(ProductEntity entity, BlocxCommandType command) {
    // Example: For create/update/read, only keep available products; always allow delete
    if (command == BlocxCommandType.delete) return true;
    return entity.isAvailable;
  }
}
```
- **Overridable Getters & Methods**:
  - `BlocxEventHub? get eventHub => null;` (must be initialized in constructor parameter list before `super()`)
  - `List<BlocxCommandType> get listenedCommands` (returns `List<BlocxCommandType>`, defaults to `[create, read, update, delete]`)
  - `bool shouldSyncEntity(T entity, BlocxCommandType command) => true;`
  - `bool get updateExistingOnCreate => false;` (when `true`, if `create` arrives for an item already in `list`, updates it in place)
  - `bool get insertMissingOnRead => false;` (when `true`, if `read` arrives for an item not in `list`, inserts it at `getInsertIndexForItem(item)`)
  - `int getInsertIndexForItem(T value) => 0;`
  - `@protected void onCreateCommand(List<T> items)`
  - `@protected void onReadCommand(List<T> items)`
  - `@protected void onUpdateCommand(List<T> items)`
  - `@protected void onDeleteCommand(List<T> items)`
  - Optional standalone streams: `Stream<T>? get itemCreationStream`, `Stream<String>? get itemDeleteStream`, `Stream<T>? get itemUpdateStream`
