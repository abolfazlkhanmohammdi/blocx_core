# Release Report: blocx_core 1.2.0

**Package:** `blocx_core`  
**Version:** `1.2.0`  
**Date:** 2026-10-10  
**Branch:** `release/1.2.0-prep`  

## 1. Summary of Changes
- **F1 / K1:** Prevented stuck `isLoadingNextPage` when `loadGeneration` increments during an in-flight pagination request (`nextLoadGeneration()` always clears `isLoadingNextPage = false` and notifies bottom loader).
- **F2 / K2:** Eliminated local pagination offset drift when entities are inserted or removed locally (`_localOffsetDelta` tracking with `noteLocalInsert()`, `noteLocalRemoval()`, and `adjustOffsetForLocalChanges()` across initial load, next page, search, and refresh).
- **F3 / K3:** Deduplicated entity insertions in `insertToList()`: bulk inserts check `identifier` against existing items and replace existing matches in-place while inserting new items at the target position.
- **F4 / K4:** Concurrency and event transformers for `BlocxFormCoreMixin`: registered `Init` with `restartable()`, `UpdateData` with `sequential()`, `Submit` with `droppable()`, `UpdateFormData` with `restartable()`, and `SyncFormData` with `sequential()`; guarded `initForm` against cancelled emissions (`if (emit.isDone) return`).
- **F5 / K5:** Guarded `searchNextPage` against redundant in-flight triggers: verifies `!hasReachedEnd && !isLoadingNextPage`, tracks `isLoadingNextPage` with generation-safe `try/finally`, and verifies search guards when delegating from `loadNextPage`.
- **F6 / K6:** Localized delete confirmation and failure snackbars: added default getters `itemDeleted` and `itemDeleteFailed` to `BlocXLocalizations`, and updated `deletion/mixin.dart` to use localized strings instead of hardcoded English.
- **F7 / K7:** Added `reportError(Object error, StackTrace? stackTrace)` hook to `BlocxBaseBloc`, called automatically from `handleError` before UI translation, enabling crash reporting forwarding without coupling to UI layers.
- **CI/CD:** Installed GitHub Actions workflows (`ci.yml`, `release.yml`, `publish.yml`) with automated gate on PR/merge and OIDC trusted publishing on tag push.

## 2. Gate Verification
- **Formatting:** `dart format --output=none --set-exit-if-changed .` -> **PASSED** (0 changed files).
- **Static Analysis:** `dart analyze --fatal-infos` -> **PASSED** (0 issues).
- **Unit Tests:** `dart test` -> **PASSED** (117 tests passed).
- **Package Dry Run:** `dart pub publish --dry-run` -> **PASSED** (Only benign uncommitted files warning prior to commit).

## 3. Breaking Changes
- **None.** All public APIs remain backward-compatible with 1.1.0.
