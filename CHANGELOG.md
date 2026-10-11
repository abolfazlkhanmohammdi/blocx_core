# Changelog

## [1.2.1] - 2026-10-11

### Documentation
* Corrected outdated class and method names throughout `README.md` (`refreshPageUseCaseTask`/`refreshPageCursorTask`, `setFilter`/`getFilter`, `highlightedItemIds`, `expandedItemIds`, `BlocxCollectionEventAddItem`, `stepIndex`/`maxStep`, `FakePaginatedSource`, full mixin names).
* Added automated `tool/check_readme.dart` validation in CI to prevent referencing nonexistent symbols in documentation.

### Infrastructure
* Transitioned GitHub Actions release automation to a token-free model using `workflow_dispatch` on tags without requiring personal access tokens.

## [1.2.0] - 2026-10-10

### Fixed
* Fixed stuck `isLoadingNextPage` when `loadGeneration` increments during an in-flight pagination request (F1 / K1): `nextLoadGeneration()` now always clears `isLoadingNextPage = false` and signals bottom loader completion.
* Fixed local pagination offset drift when entities are inserted or removed locally (F2 / K2): introduced `_localOffsetDelta` tracking with `noteLocalInsert()`, `noteLocalRemoval()`, and `adjustOffsetForLocalChanges()` across initial load, next page, search, and refresh.
* Accounted for appended items in local pagination offset drift tracking (C-B): extended `noteLocalInsert` with `bool isAppended` to ensure items appended to the tail of the list do not shift pagination fetch offsets.
* Fixed duplicate entity insertions in `insertToList()` (F3 / K3): bulk inserts now check `identifier` against existing items and replace existing matches in-place while inserting new items at the target position.
* Optimized `insertToList` deduplication to $O(N + M)$ linear time (C-G): indexed existing collection items by `identifier` in a hash map before merging new items.
* Guarded `searchNextPage` against redundant in-flight triggers (F5 / K5): now verifies `!hasReachedEnd && !isLoadingNextPage`, tracks `isLoadingNextPage` with a generation-safe `try/finally`, and verifies search guards when delegating from `loadNextPage`.
* Concurrency and event transformers for `BlocxFormCoreMixin` (F4 / K4): registered `Init` with `restartable()`, `UpdateData` with `sequential()`, `Submit` with `droppable()`, `UpdateFormData` with `restartable()`, and `SyncFormData` with `sequential()`; guarded `initForm` against cancelled emissions (`if (emit.isDone) return`).
* Stepped form navigation boundary guards (C-D): guarded `goToNextStep`, `goToPreviousStep`, and `goToStep` in `BlocxFormSteppedMixin` against invalid or out-of-bounds step transitions.
* Pruned removed item states on deletion (C-E): added `pruneItemState(identifier)` removing deleted entities from `selectedItemIds`, `beingSelectedItemIds`, `highlightedItemIds`, and `expandedItemIds` across `removeItemFromList` and `removeFromList`.
* Guarded unique field availability checks (C-F): in `BlocxFormCoreMixin._checkUniqueValue`, evaluated the unique-field task before emitting pending state or assigning in-flight tokens, preventing dangling validation tokens when no task is configured.
* Localized delete confirmation and failure snackbars (F6 / K6, C-E): added default getters `itemDeleted`, `itemDeleteFailed`, `itemsDeleted`, `itemsDeleteFailed`, `itemsDeletedPartially`, `selectItemFailed`, and `deselectItemFailed` to `BlocXLocalizations`, and updated `deletion/mixin.dart` and `selection/mixin.dart` to use localized strings.

### Added
* Added `reportError(Object error, StackTrace? stackTrace)` hook to `BlocxBaseBloc` (F7 / K7): called automatically from `handleError` before UI translation, allowing subclasses to forward unhandled errors to crash reporting services (such as Sentry or Firebase Crashlytics) without coupling to UI layers.
* Documented error monitoring best practices across `BlocxBaseBloc` and `BlocxBaseUseCase`.

### Infrastructure & Testing
* Resolved static analysis warnings on Dart stable (C-A): corrected dead code branches and deprecated member usages.
* Strengthened invariant test suite (C-C): expanded randomized fuzzing invariants across seeds 1 through 30 for collection ordering, deduplication, and pagination integrity.
* Replaced arbitrary test sleep waits with deterministic synchronization (C-H): converted all real `Future.delayed` sleeps in collection and form tests to `pumpEventQueue()`, `Completer`, or `fakeAsync`.
* Configured GitHub Actions CI/CD workflows (`ci.yml`, `release.yml`, `publish.yml`) supporting OIDC automated pub.dev publishing on release tag push.

## [1.1.0] - 2026-10-10

### Added
* Added `clearError()` to `ScreenManagerCubit` and `BlocxBaseBloc`, which emits `ScreenManagerCubitStateInitial(shouldRebuild: true)` to dismiss full-page errors and restore normal screen display without resurrecting error states on subsequent snackbars.
* Added cursor-based pagination support with `BlocxPage.nextCursor`, `BlocxCursorPaginatedInput`, `BlocxCursorPaginatedUseCase`, `BlocxCursorPaginatedUseCaseTask`, and datasource cursor tracking (`nextCursor`) in `BlocxCollectionCoreMixin` and `BlocxCollectionInfiniteMixin`.
* Added `sortComparator` and sort-aware item insertion (`getInsertIndexForItem`) to `BlocxCollectionCoreMixin` and `BlocxCollectionSyncStreamMixin` to preserve ordered placement of newly created or synced items.
* Added per-bloc injectable `errorTranslator` and `localizations` constructor parameters and getters to `BlocxBaseBloc`, `BlocxCollectionBloc`, and `BlocxFormBloc`, falling back to `BlocxErrorTranslator.instance` and `BlocXLocalizations.localizations`.
* Added `searchingText` and `searchHint` keys to `BlocXLocalizations` with default implementations.
* Added `package:blocx_core/testing.dart` exporting test utilities: in-memory `BlocxTestEventHub`, `BlocxTestEntity`, `BlocxTestFormEntity`, `FakePaginatedSource`, `FakePaginatedUseCase`, `FakeCursorPaginatedUseCase`, `FakeSearchUseCase`, `FakeUseCase`, and task construction helpers.

### Fixed
* Fixed cursor pagination end-of-list detection: a missing or empty `nextCursor` is now treated as the end of list (`hasReachedEnd == true`), preventing infinite refetches of page 1 when `items.length == limit`. Added guard in `_fetchNextPageWithCursor` when cursor is missing.
* Fixed pull-to-refresh throwing `UnimplementedError` on cursor-only collection blocs: added `refreshPageCursorTask` and `_fetchRefreshPageWithCursor` to `BlocxCollectionRefreshableMixin`.

### Changed
* Raised the minimum Dart SDK to 3.8.0, which is what the dependency constraints (bloc 9 etc.) already required.

## [1.0.1] - 2026-10-09

### Documentation
* Recorded baseline test and analysis results in `docs/fix-notes.md`.
* Aligned `BlocxBaseEntity` documentation and examples to accurately reflect that entity matching, deduplication, and sync operate via the contractual `identifier` getter, while Dart `operator ==` and `hashCode` remain standard `Object` identity unless overridden by subclasses.
* Corrected `resolveCommandEntities(input, output)` signature in `README.md` to reflect the 2-parameter signature in source.
* Updated `BlocxCollectionSearchableMixin` doc descriptions in `blocx_collection_bloc.dart` to clarify that search filters the active collection list in-place rather than maintaining a disconnected secondary list.

### Infrastructure & Testing
* Added GitHub Actions CI workflow (`.github/workflows/ci.yml`) covering formatting, static analysis (`--fatal-infos`), tests with coverage, and dry-run publishing across SDK matrix (`3.5.0` and `stable`).
* Added `bloc_test` and `fake_async` dev dependencies and test harness fixtures in `test/helpers/` (fake use cases, paginated source, entity models).
* Added comprehensive multi-mixin combination test suite (`test/collection/collection_combination_test.dart`) exercising the flagship combination of Infinite, Refreshable, Searchable, Selectable, Deletable, and SyncStream mixins working together.
* Replaced arbitrary `Future.delayed` sleeps in existing collection and form tests with reactive stream synchronization.

### Fixed
* Fixed initial load failure leaving collection state stuck in `Loading` forever; now emits `BlocxCollectionStateError` with translated error message while keeping existing list and status flags intact.
* Added `readableErrorOf` helper on `BlocxBaseBloc` to centralize readable error translation.
* Ensured `isLoadingNextPage`, `isRefreshing`, and `isSearching` flags and states are consistently reset and emitted on failure paths.
* Fixed `BlocxCollectionInfiniteMixin` to emit `isLoadingNextPage: true` upon fetch initiation and reset to `false` upon page arrival/completion, keeping state snapshots synchronized with bloc status.
* Prevented emitted states from aliasing live mutable lists and identifier sets by emitting true unmodifiable snapshots (`List<Entity>.unmodifiable` and `Set<String>.unmodifiable`), eliminating retroactive state mutations.
* Decoupled pagination offset (`offset` and `searchOffset`) from local list length (`list.length`) by tracking datasource-loaded counts (`_loadedCount` and `_searchLoadedCount`), preventing pagination offset drift when entities are added or deleted locally via sync streams or user actions.
* Prevented stale-response race conditions by introducing a monotonically incrementing `loadGeneration` counter and registering `BlocxCollectionEventLoadInitialPage` and `BlocxCollectionEventRefreshData` with `restartable()`, and `BlocxCollectionEventLoadNextPage` with `droppable()`, safely discarding out-of-order in-flight responses across initial load, pagination, refresh, and search.
* Added in-place deduplication to `addItem` and `insertToListSingle`: if an item with matching `identifier` already exists in the collection, it is updated in-place rather than inserted as a duplicate entry.
* Isolated entity resolution and EventHub event broadcasting within `BlocxBaseUseCase.execute(input)` in a dedicated `try/catch` with a `handleBroadcastError` hook, ensuring that exceptions thrown during post-execution broadcasting never cause a successful persistent business operation to return a `BlocxUseCaseFailure`.
* Optimized `BlocxSimpleEventHub.emit` to capture `StackTrace.current` conditionally inside an assert block (`assert(() { event.debugTrace ??= StackTrace.current; return true; }())`), eliminating expensive stack trace capture overhead in release builds while preserving diagnostics in debug/test environments.
* Enhanced `BlocxSimpleEventHub.onEntity<T>` to support heterogeneous entity batches using `entities.any((item) => item is T)` and `whereType<T>()`, and preserved original event `id` and `createdAt` timestamps when re-wrapping typed `BlocxEntityEvent`s.

## [1.0.0]

### Added

* **Command-Driven EventHub & Automatic UseCase Broadcasting**
  * Added `BlocxCommandType` (`create`, `read`, `update`, `delete`) and `BlocxEntityEvent<T extends BlocxBaseEntity>` (containing `entities`, `command`, `origin`, `debugTrace`, and a convenience `entity` getter).
  * Updated `BlocxEventHub` and `BlocxSimpleEventHub` with `emitEntity<T>`, `emitEntities<T>`, and typed `onEntity<T>({Iterable<BlocxCommandType>? commands})` stream filtering.
  * Updated `BlocxBaseUseCase`, `BlocxPaginatedUseCase`, and `BlocxSearchUseCase` constructors to accept optional `eventHub`, `commandType`, and `commandTypes`.
  * Automatic entity broadcasting on UseCase success: `BlocxBaseUseCase.execute(input)` now automatically resolves affected `BlocxBaseEntity` instances via `resolveCommandEntities(input, output, command)` (extracting from `Output`, `BlocxPage<Output>`, `Iterable<BlocxBaseEntity>`, or `Input` when `command == BlocxCommandType.delete`) and emits `BlocxEntityEvent`s to `eventHub`.
  * Defaulted `BlocxPaginatedUseCase` and `BlocxSearchUseCase` to `BlocxCommandType.read`.
  * Added overridable `shouldBroadcastCommandResult(input, output)` hook on `BlocxBaseUseCase`.
* **Live Collection Stream Synchronization (`BlocxCollectionSyncStreamMixin`)**
  * Enhanced `BlocxCollectionSyncStreamMixin<T, P>` to automatically subscribe to `eventHub.onEntity<T>(commands: listenedCommandTypes)` as well as custom `entityEventsStreams` and `entitiesStream`.
  * Added command-aware handlers (`onStreamEntitiesCreate`, `onStreamEntitiesUpdate`, `onStreamEntitiesRead`, `onStreamEntitiesDelete`), `shouldSyncEntity(entity, command)` filter hook, `insertCreatedEntitiesAtStart` flag, and `updateOnlyExistingOnRead` flag.
  * Exported `BlocxCollectionSyncStreamMixin` from `package:blocx_core/collection_bloc.dart`.
* **Live Form Stream Synchronization (`BlocxFormSyncStreamMixin`)**
  * Added `BlocxFormSyncStreamMixin<F, P, E, WatchedEntity>` (exported from `package:blocx_core/form_bloc.dart`) to synchronize open forms when a watched entity is updated/read/created via `BlocxEventHub` or custom streams (`isWatchedEntity`, `mapSyncedEntityToFormData`, `applySyncedDataToControllers`, `validateAfterSync`).
  * Added automatic screen pop support (`popOnEntityDeleted` and `onWatchedEntityDeleted`) when the watched entity is deleted.
  * Added `BlocxFormEventSyncFormData<F>` and `handleSyncFormDataEvent` to `BlocxFormCoreMixin`, plus `initStreams()` and `closeStreams()` lifecycle hooks on `BlocxFormBloc`.
* **Listener Helper on `BlocxEventHubMixin`**
  * Added `entityEventsOfType<T extends BlocxBaseEntity>({Iterable<BlocxCommandType>? commands})` to `BlocxEventHubMixin`.
* **Bundled AI Agent Skill (`skills/blocx-core`)**
  * Added a comprehensive `blocx-core` AI coding skill (`SKILL.md` and `references/`) for agentic IDEs.
* **Runnable Package Example (`example/blocx_core_example.dart`)**
  * Added a complete runnable pure-Dart example showcasing `BlocxBaseEntity`, `BlocxPaginatedUseCase`, `BlocxEventHub`, `BlocxCollectionBloc`, and `BlocxFormBloc`.

### Changed

* **Full Web & WASM Platform Compatibility**
  * Removed the unused `logger` dependency (which transitively imported `dart:io`), enabling 100% Web and WASM runtime compatibility across all 6 target platforms.
* **Strict Unidirectional EventHub Architecture**
  * Removed `emitSystemWideEvent` from `BlocxEventHubMixin`. Only `BlocxBaseUseCase` subclasses emit app/domain events; `BlocxBaseBloc` and `BlocxEventHubMixin` are strictly listeners.
* **Documentation Overhaul**
  * Rebuilt `README.md` with concise architecture diagrams, side-by-side comparisons, live `BlocxEventHub` synchronization examples, and cross-references to `flutter_blocx`.

### Fixed

* **Safe Collection Item Insertion & Update (`BlocxCollectionCoreMixin`)**
  * `addItem` (`BlocxCollectionEventAddItem`) now clamps `event.index` to `[0, list.length]` instead of throwing a `RangeError` when out of bounds.
  * `updateItem` (`BlocxCollectionEventUpdateItem`) now safely returns a no-op when the item's identifier is not present in the current list instead of throwing an unhandled `Exception`.
* **Collection Pull-to-Refresh Limit (`BlocxCollectionRefreshableMixin`)**
  * Fixed `refreshData` (`BlocxCollectionEventRefreshData`) to request `limit` items instead of `list.length`, ensuring consistent pagination page sizes after refreshing.

---

## [0.9.0]

### Fixed

* **Form submission validation**

  * Added full-form validation before submit hooks and use case execution.
  * Blocked submit use case execution when validation errors exist.
  * Blocked submission while required form info is loading.
  * Blocked submission while unique-field validation is still running.
  * Preserved `FormValidationMode` behavior during submit, init, and field-update validation.

* **Form validation behavior**

  * Updated `BlocxFormValidationMixin` so:

    * `none` disables validation.
    * `onSubmit` validates the full form only on submit/full-validation requests.
    * `onUserInteraction` validates changed fields while editing and the full form on submit.
    * `always` validates the full form on every update and submit.
  * Fixed field-level validation so validating one field no longer clears errors from unrelated fields.

* **Timed form errors**

  * Fixed timed field errors so timers dispatch clear events instead of reusing an old `Emitter`.
  * Added timer cleanup when clearing errors.
  * Added timer cleanup when `BlocxFormBloc` closes.

* **Unique-field validation**

  * Updated unique-field checks to use the new typed `BlocxUseCaseTask<Input, Output>` API.
  * Awaited form updates after successful unique checks.
  * Preserved stale-response protection through per-field request tokens.
  * Forwarded use case stack traces to `handleError`.

* **Pagination & Collection Tests**

  * Fixed `BlocxPage.hasNext` to compare returned item count against the requested `limit`.
  * Replaced the old `loadCount` field with `limit`.
  * Fixed `BlocxCollectionBloc` initial page test limit configuration.

### Changed

* **Use case task typing**

  * Changed `BlocxUseCaseTask` from use-case-class/input typing to input/output typing:

    * Before: `BlocxUseCaseTask<UseCase, Input>`
    * After: `BlocxUseCaseTask<Input, Output>`
  * Added `execute()` to `BlocxUseCaseTask` so callers no longer manually call `task.useCase.execute(task.inputBuilder())`.

* **Paginated task typing**

  * Changed `BlocxPaginatedUseCaseTask` to use input/output typing:

    * `BlocxPaginatedUseCaseTask<Input extends BlocxPaginatedInput, Output extends BlocxBaseEntity>`
  * Added `execute(offset: ..., limit: ...)` to centralize paginated task execution.

* **Paginated input naming**

  * Renamed `BlocxPaginatedInput` to `BlocxPaginatedInput`.
  * Renamed the source file/export from `blocx_pagination_use_case.dart` to `blocx_paginated_use_case.dart`.
  * Updated `BlocxSearchInput` to extend `BlocxPaginatedInput`.

* **Form core mixin**

  * Replaced `BlocxFormDataMixin` with `BlocxFormCoreMixin`.
  * Removed the raw `FormSubmitTask` typedef.
  * Added stronger dartdocs for form initialization, update, validation, submission, payload handling, and submit hooks.

* **Form info fetching**

  * Updated `BlocxFormInfoFetcherMixin.requiredInitialInfoTasks` to use `Map<E, BlocxUseCaseTask<Object?, Object?>>`.
  * Updated info-fetch execution to call `task.execute()`.
  * Improved docs and immutable views for fetched info/loading state.

* **Collection pagination mixins**

  * Updated collection core, infinite, refreshable, and searchable mixins to use `BlocxPaginatedUseCaseTask<Input, Output>`.
  * Updated initial load, next-page load, refresh, search pagination, and search refresh to call `task.execute(...)`.
  * Improved error messages when required pagination/search tasks are missing.
  * Cleared the existing list before applying initial-load and refresh results.

* **Collection action mixins**

  * Updated delete behavior to use task factories:

    * `deleteItemTask(item)`
    * `deleteMultipleItemsTask(items)`
  * Added `performDeleteItem(item)` fallback for custom delete implementations.
  * Updated selection sync to use task factories:

    * `selectItemTask(item)`
    * `deselectItemTask(item)`
  * Added rollback handling for failed remote selection and deselection sync.
  * Improved typed selection-change events and empty multi-select guards.

* **Public exports**

  * Exported `BlocxFormValidator` from `form_bloc.dart`.
  * Exported additional non-string validator groups from `form_bloc.dart`.
  * Updated `list_bloc.dart` to export `blocx_paginated_use_case.dart`.

* **Documentation**

  * Expanded dartdocs across form core, form errors, validation, info fetching, unique-field validation, collection core, pagination, refresh, search, selection, deletion, page model, and use case task APIs.

### Migration Guide

#### Replace `BlocxPaginatedInput` with `BlocxPaginatedInput`

```dart
// Before
class GetUsersInput extends BlocxPaginatedInput {
  const GetUsersInput({
    required super.limit,
    required super.offset,
  });
}

// After
class GetUsersInput extends BlocxPaginatedInput {
  const GetUsersInput({
    required super.limit,
    required super.offset,
  });
}
```

#### Update paginated use case imports

```dart
// Before
import 'package:blocx_core/src/blocs/collection/use_cases/blocx_pagination_use_case.dart';

// After
import 'package:blocx_core/src/blocs/collection/use_cases/blocx_paginated_use_case.dart';
```

Prefer the public barrel when possible:

```dart
import 'package:blocx_core/list_bloc.dart';
```

#### Update normal use case tasks

```dart
// Before
BlocxUseCaseTask<CreateUserUseCase, CreateUserInput>(
  useCase: createUserUseCase,
  inputBuilder: () => CreateUserInput(...),
);

// After
BlocxUseCaseTask<CreateUserInput, UserEntity>(
  useCase: createUserUseCase,
  inputBuilder: () => CreateUserInput(...),
);
```

#### Update form submit tasks

```dart
@override
BlocxUseCaseTask<CreateAccountInput, AccountResponse> get submitUseCaseTask {
  return BlocxUseCaseTask<CreateAccountInput, AccountResponse>(
    useCase: createAccountUseCase,
    inputBuilder: () {
      return CreateAccountInput(
        email: formData.email,
        password: formData.password,
      );
    },
  );
}
```

#### Update paginated collection tasks

```dart
@override
BlocxPaginatedUseCaseTask<GetUsersInput, UserEntity>? get paginationTask {
  return BlocxPaginatedUseCaseTask<GetUsersInput, UserEntity>(
    useCase: getUsersUseCase,
    inputBuilder: (offset, limit) {
      return GetUsersInput(
        offset: offset,
        limit: limit,
      );
    },
  );
}
```

#### Update search tasks

```dart
@override
BlocxPaginatedUseCaseTask<BlocxSearchInput, UserEntity>? get searchUseCaseTask {
  return BlocxPaginatedUseCaseTask<BlocxSearchInput, UserEntity>(
    useCase: searchUsersUseCase,
    inputBuilder: (offset, limit) {
      return BlocxSearchInput(
        searchText: searchText,
        offset: offset,
        limit: limit,
      );
    },
  );
}
```

#### Update delete mixins

```dart
// Before
@override
BlocxBaseUseCase<UserEntity, bool>? get deleteItemUseCase {
  return deleteUserUseCase;
}

// After
@override
BlocxUseCaseTask<DeleteUserInput, bool>? deleteItemTask(UserEntity item) {
  return BlocxUseCaseTask<DeleteUserInput, bool>(
    useCase: deleteUserUseCase,
    inputBuilder: () {
      return DeleteUserInput(id: item.id);
    },
  );
}
```

#### Update selection sync mixins

```dart
@override
BlocxUseCaseTask<SelectUserInput, bool>? selectItemTask(UserEntity item) {
  return BlocxUseCaseTask<SelectUserInput, bool>(
    useCase: selectUserUseCase,
    inputBuilder: () {
      return SelectUserInput(id: item.id);
    },
  );
}

@override
BlocxUseCaseTask<DeselectUserInput, bool>? deselectItemTask(UserEntity item) {
  return BlocxUseCaseTask<DeselectUserInput, bool>(
    useCase: deselectUserUseCase,
    inputBuilder: () {
      return DeselectUserInput(id: item.id);
    },
  );
}
```

---

## [0.8.3]

### Fixed

* Improved package stability by fixing public exports, collection state copying, and initial search pagination behavior.

### Changed

* Updated documentation and migration guidance to reflect the current `BlocxCollectionBloc`, task-based use case APIs, renamed infinite-list internals, and `0.8.3` usage.

## [0.8.2]

* Updated CHANGELOG.md

## [0.8.1]

### Changed

* **README terminology alignment**

  * Renamed documentation references from `BaseEntity` to `BlocxBaseEntity`.
  * Renamed documentation references from `BlocxPaginationUseCase` to `BlocxPaginatedUseCase`.
  * Updated examples and code snippets to use the current API naming.
  * Simplified the collection mixins capability table and removed outdated `init*()` references.

* **`BlocxPaginatedUseCaseTask` type constraints**

  * Tightened generic bounds to require a `BlocxPaginatedUseCase<Input, dynamic>` instead of a generic `BlocxBaseUseCase`, improving compile-time type safety and ensuring task/use-case compatibility.

---

## [0.8.0]

### Added

* **`BlocxPaginatedUseCaseTask`** — new task class that pairs a paginated `BlocxPaginatedUseCase` with a `PaginationInputBuilder`, receiving the current `limit` and `offset` at execution time. This is the standard task type for `BlocxCollectionBloc.paginationTask` and supports per-operation overrides via `loadInitialPageTask`.
* **`BaseBloc` documentation** — comprehensive dartdoc covering:

  * Internal `ScreenManagerCubit` ownership (consumers no longer need to construct or pass one).
  * Error handling via `handleError` and `errorDisplayPolicy` (snackbar by default, overridable to full-page).
  * Navigation via `pop`.
  * Custom error presentation via `BlocxErrorTranslator` registered at app startup.
* **`InputBuilder` type alias** — replaces the inline function type in `BlocxUseCaseTask`, improving readability and reuse.

### Changed

* **Mixin export naming — list** (`list_bloc.dart`): removed `_bloc` segment from all collection mixin export paths for a flatter, consistent naming scheme:

  * `blocx_collection_bloc_infinite_mixin` → `blocx_collection_infinite_mixin`
  * `blocx_collection_bloc_selectable_mixin` → `blocx_collection_selectable_mixin`
  * `blocx_list_bloc_sync_stream_mixin` → `blocx_collection_sync_stream_mixin`
  * `blocx_collection_bloc_deletable_mixin` → `blocx_collection_deletable_mixin`
  * `blocx_collection_bloc_expandable_mixin` → `blocx_collection_expandable_mixin`
  * `blocx_collection_bloc_highlightable_mixin` → `blocx_collection_highlightable_mixin`
  * `blocx_collection_bloc_refreshable_mixin` → `blocx_collection_refreshable_mixin`
  * `blocx_collection_bloc_scrollable_mixin` → `blocx_collection_scrollable_mixin`
  * `blocx_collection_bloc_searchable_mixin` → `blocx_collection_searchable_mixin`

* **Mixin export naming — form** (`form_bloc.dart`): standardised exports to the `blocx_form_*` prefix pattern:

  * `blocx_info_fetcher_form_mixin` → `blocx_form_info_fetcher_mixin`
  * `blocx_stepped_form_mixin` → `blocx_form_stepped_mixin`

* **Model export rename** (`form_bloc.dart`):

  * `base_form_entity.dart` → `blocx_base_form_entity.dart`

* **`BlocxUseCaseTask` docs** — condensed and clarified; class-level doc now explains lazy `inputBuilder` evaluation; inline field comments tightened.

### Migration Guide

#### List mixin imports

Update any direct imports of the renamed mixin files:

```dart
// Before
import 'package:blocx_core/src/blocs/collection/mixins/blocx_collection_bloc_infinite_mixin.dart';

// After
import 'package:blocx_core/src/blocs/collection/mixins/blocx_collection_infinite_mixin.dart';
```

The same pattern applies to all other renamed list mixins listed above.

#### Form mixin & model imports

```dart
// Before
import 'package:blocx_core/src/blocs/form/mixins/blocx_info_fetcher_form_mixin.dart';
import 'package:blocx_core/src/core/models/base_form_entity.dart';

// After
import 'package:blocx_core/src/blocs/form/mixins/blocx_form_info_fetcher_mixin.dart';
import 'package:blocx_core/src/core/models/blocx_base_form_entity.dart';
```

---

## [0.7.1] - prior release

*See repository history for earlier entries.*
