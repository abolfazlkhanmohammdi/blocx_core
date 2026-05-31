# Changelog

---

## [0.8.1] - 2026-05-31

### Changed

- **README terminology alignment**
  - Renamed documentation references from `BaseEntity` to `BlocxBaseEntity`.
  - Renamed documentation references from `BlocxPaginationUseCase` to `BlocxPaginatedUseCase`.
  - Updated examples and code snippets to use the current API naming.
  - Simplified the collection mixins capability table and removed outdated `init*()` references.

- **`BlocxPaginatedUseCaseTask` type constraints**
  - Tightened generic bounds to require a `BlocxPaginatedUseCase<Input, dynamic>` instead of a generic `BlocxBaseUseCase`, improving compile-time type safety and ensuring task/use-case compatibility.

---

## [0.8.0] - 2026-05-31

### Added

- **`BlocxPaginatedUseCaseTask`** — new task class that pairs a paginated `BlocxPaginatedUseCase` with a `PaginationInputBuilder`, receiving the current `limit` and `offset` at execution time. This is the standard task type for `BlocxCollectionBloc.paginationTask` and supports per-operation overrides via `loadInitialPageTask`.
- **`BaseBloc` documentation** — comprehensive dartdoc covering:
  - Internal `ScreenManagerCubit` ownership (consumers no longer need to construct or pass one).
  - Error handling via `handleError` and `errorDisplayPolicy` (snackbar by default, overridable to full-page).
  - Navigation via `pop`.
  - Custom error presentation via `BlocxErrorTranslator` registered at app startup.
- **`InputBuilder` type alias** — replaces the inline function type in `BlocxUseCaseTask`, improving readability and reuse.

### Changed

- **Mixin export naming — list** (`list_bloc.dart`): removed `_bloc` segment from all collection mixin export paths for a flatter, consistent naming scheme:
  - `blocx_collection_bloc_infinite_mixin` → `blocx_collection_infinite_mixin`
  - `blocx_collection_bloc_selectable_mixin` → `blocx_collection_selectable_mixin`
  - `blocx_list_bloc_sync_stream_mixin` → `blocx_collection_sync_stream_mixin`
  - `blocx_collection_bloc_deletable_mixin` → `blocx_collection_deletable_mixin`
  - `blocx_collection_bloc_expandable_mixin` → `blocx_collection_expandable_mixin`
  - `blocx_collection_bloc_highlightable_mixin` → `blocx_collection_highlightable_mixin`
  - `blocx_collection_bloc_refreshable_mixin` → `blocx_collection_refreshable_mixin`
  - `blocx_collection_bloc_scrollable_mixin` → `blocx_collection_scrollable_mixin`
  - `blocx_collection_bloc_searchable_mixin` → `blocx_collection_searchable_mixin`

- **Mixin export naming — form** (`form_bloc.dart`): standardised exports to the `blocx_form_*` prefix pattern:
  - `blocx_info_fetcher_form_mixin` → `blocx_form_info_fetcher_mixin`
  - `blocx_stepped_form_mixin` → `blocx_form_stepped_mixin`

- **Model export rename** (`form_bloc.dart`):
  - `base_form_entity.dart` → `blocx_base_form_entity.dart`

- **`BlocxUseCaseTask` docs** — condensed and clarified; class-level doc now explains lazy `inputBuilder` evaluation; inline field comments tightened.

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

_See repository history for earlier entries._
