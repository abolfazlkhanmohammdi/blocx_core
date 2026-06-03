# Changelog

## [0.8.4]

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

* **Pagination**

  * Fixed `BlocxPage.hasNext` to compare returned item count against the requested `limit`.
  * Replaced the old `loadCount` field with `limit`.

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

  * Renamed `BlocxPaginationInput` to `BlocxPaginatedInput`.
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

#### Replace `BlocxPaginationInput` with `BlocxPaginatedInput`

```dart
// Before
class GetUsersInput extends BlocxPaginationInput {
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
import 'package:blocx_core/src/blocs/list/use_cases/blocx_pagination_use_case.dart';

// After
import 'package:blocx_core/src/blocs/list/use_cases/blocx_paginated_use_case.dart';
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
import 'package:blocx_core/src/blocs/list/mixins/blocx_collection_bloc_infinite_mixin.dart';

// After
import 'package:blocx_core/src/blocs/list/mixins/blocx_collection_infinite_mixin.dart';
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
