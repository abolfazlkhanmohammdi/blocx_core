# Release Report: blocx_core 1.2.0

**Package:** `blocx_core`  
**Version:** `1.2.0`  
**Date:** 2026-10-11  
**Branch:** `develop`  

## 1. Summary of Changes

### Round 1 Changes (F1 - F7)
- **F1 / K1 (Generation-safe pagination reset):** Prevented stuck `isLoadingNextPage` when `loadGeneration` increments during an in-flight pagination request (`nextLoadGeneration()` always clears `isLoadingNextPage = false` and notifies bottom loader).
- **F2 / K2 (Local offset tracking):** Eliminated local pagination offset drift when entities are inserted or removed locally (`_localOffsetDelta` tracking with `noteLocalInsert()`, `noteLocalRemoval()`, and `adjustOffsetForLocalChanges()` across initial load, next page, search, and refresh).
- **F3 / K3 (Insert deduplication):** Deduplicated entity insertions in `insertToList()`: bulk inserts check `identifier` against existing items and replace existing matches in-place while inserting new items at the target position.
- **F4 / K4 (Form event concurrency):** Concurrency and event transformers for `BlocxFormCoreMixin`: registered `Init` with `restartable()`, `UpdateData` with `sequential()`, `Submit` with `droppable()`, `UpdateFormData` with `restartable()`, and `SyncFormData` with `sequential()`; guarded `initForm` against cancelled emissions (`if (emit.isDone) return`).
- **F5 / K5 (Search next page guards):** Guarded `searchNextPage` against redundant in-flight triggers: verifies `!hasReachedEnd && !isLoadingNextPage`, tracks `isLoadingNextPage` with generation-safe `try/finally`, and verifies search guards when delegating from `loadNextPage`.
- **F6 / K6 (Localized delete feedback):** Localized delete confirmation and failure snackbars: added default getters `itemDeleted` and `itemDeleteFailed` to `BlocXLocalizations`, and updated `deletion/mixin.dart` to use localized strings instead of hardcoded English.
- **F7 / K7 (Error reporting hook):** Added `reportError(Object error, StackTrace? stackTrace)` hook to `BlocxBaseBloc`, called automatically from `handleError` before UI translation, enabling crash reporting forwarding without coupling to UI layers.

### Round 2 Changes (C-A - C-H)
- **C-A (Static Analysis Cleanliness):** Eliminated dead-code warnings and deprecated member usages across Dart stable and SDK 3.8.0.
- **C-B (Offset Drift for Appended Items):** Extended `noteLocalInsert` with `bool isAppended` parameter so that items appended to the tail of the list do not incorrectly shift pagination fetch offsets.
- **C-C (Strengthened Invariant Tests):** Expanded randomized property/fuzz tests across seeds 1 through 30 verifying collection order, deduplication, and pagination invariants.
- **C-D (Stepped Form Boundary Guards):** Added safety boundary checks to `goToNextStep`, `goToPreviousStep`, and `goToStep` in `BlocxFormSteppedMixin` to prevent index out of bounds exceptions.
- **C-E (Prune Removed Item State & Localized Bulk Actions):** Added `pruneItemState(String identifier)` removing deleted items from `selectedItemIds`, `beingSelectedItemIds`, `highlightedItemIds`, and `expandedItemIds`. Added localized strings for bulk operations (`itemsDeleted`, `itemsDeleteFailed`, `itemsDeletedPartially`, `selectItemFailed`, `deselectItemFailed`) to `BlocXLocalizations`.
- **C-F (Null Unique-Field Check Guard):** Evaluated `useCaseIsUniqueValueAvailable` before emitting pending state and setting in-flight tokens in `BlocxFormCoreMixin._checkUniqueValue`, preventing unresolvable pending validation tokens when no unique check usecase is defined.
- **C-G (Linear-time insertToList Deduplication):** Refactored `insertToList` deduplication to $O(N + M)$ using a hash map lookup instead of nested $O(N \times M)$ linear scans.
- **C-H (Deterministic Event Pumping in Tests):** Replaced all real `Future.delayed` sleeps in collection, form, and stream test suites with deterministic `pumpEventQueue()`, `Completer`, or `fakeAsync` coordination.

### CI/CD
- Installed GitHub Actions workflows (`ci.yml`, `release.yml`, `publish.yml`) with automated gate on PR/merge and OIDC trusted publishing on tag push.

## 2. Gate Verification
- **Formatting:** `dart format --output=none --set-exit-if-changed .` -> **PASSED** (0 changed files).
- **Static Analysis:** `dart analyze --fatal-infos` -> **PASSED** (0 issues).
- **Unit Tests:** `dart test` -> **PASSED** (130 tests passed, zero real sleeps).
- **Package Dry Run:** `dart pub publish --dry-run` -> **PASSED** (0 warnings).

## 3. Breaking Changes
- **None.** All public APIs remain backward-compatible with 1.1.0.
