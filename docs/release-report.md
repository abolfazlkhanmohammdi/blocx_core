# BlocX Core 1.1.0 Release Report

**Package:** `blocx_core`  
**Version:** `1.1.0`  
**Release Date:** 2026-10-10  
**Target Branch:** `develop`

---

## 1. Executive Summary

BlocX Core 1.1.0 stabilizes and completes cursor-based pagination capabilities across all collection flows (initial fetch, pagination continuation, and pull-to-refresh), resolves CI matrix compatibility with upstream lint rules, refactors pagination internals for maintainability, and documents runtime behaviors and limitations.

All changes strictly adhere to semantic versioning with zero breaking changes to public APIs.

---

## 2. CI Root Cause Analysis & Resolution

### Root Cause
The CI pipeline previously failed on the `3.5.0` SDK matrix entry during `dart pub get` with:
```
The current Dart SDK version is 3.5.0.
Because blocx_core depends on lints ^6.1.0 which requires SDK version >=3.8.0 <4.0.0, version solving failed.
```
`lints ^6.1.0` enforces a Dart SDK floor of `^3.8.0`. Specifying `sdk: ">=3.5.0 <4.0.0"` in `pubspec.yaml` was incompatible with transitively locked dev dependencies.

### Resolution
- Raised SDK floor in `pubspec.yaml` to `">=3.8.0 <4.0.0"`.
- Aligned GitHub Actions CI workflow (`.github/workflows/ci.yml`) matrix to `['3.8.0', 'stable']`.
- Updated Dart SDK badge in `README.md` to reflect `>=3.8.0`.
- Formatted entire repository to conform with Dart 3.12 formatting rules.

---

## 3. Tasks Completed

### Task T1: CI Alignment & SDK Floor
- **Commit:** `a7b759b` (`ci(core): make CI green and align SDK floor with dependencies`)
- Raised SDK constraint to `sdk: ">=3.8.0 <4.0.0"`.
- Updated CI matrix to test minimum supported SDK `3.8.0` and latest `stable`.
- Verified formatting across all files.

### Task T2: Cursor Pagination End-of-List Termination
- **Commit:** `21e61ad` (`fix(core): treat a missing cursor as end of list in cursor pagination`)
- Corrected cursor pagination termination semantics so a missing or empty `nextCursor` marks `isLast = true`.
- Updated `BlocxCursorPaginatedUseCase.successResult` to default `hasNext` from `hasNext ?? (nextCursor != null && nextCursor.isNotEmpty)`.
- Updated `_fetchInitialPageWithCursor` and `_fetchNextPageWithCursor` to compute `isLast = !page.hasNext || page.nextCursor == null || page.nextCursor!.isEmpty`.
- Added defensive guard in `_fetchNextPageWithCursor` to avoid calling `task.execute` when cursor is null or empty.
- Documented cursor pagination contract in `BlocxPage` dartdocs.
- Added 7 unit tests in `test/collection/cursor_pagination_test.dart` following Red -> Green TDD.

### Task T3: Cursor Pagination in Pull-to-Refresh
- **Commit:** `bce70b8` (`feat(core): support cursor pagination in pull-to-refresh`)
- Added `refreshPageCursorTask` getter and `_fetchRefreshPageWithCursor` in `BlocxCollectionRefreshableMixin`.
- Implemented cursor-over-offset precedence when refreshing.
- Updated `UnimplementedError` to advise providing `refreshPageCursorTask`.
- Added 4 unit tests in `test/collection/cursor_refresh_test.dart` covering initial load, refresh, failure, and search delegation following Red -> Green TDD.

### Task T4: Refactoring Pagination Application & Error Handling
- **Commit:** `d76907e` (`refactor(core): share initial-load error and apply logic between offset and cursor paths`)
- Extracted `_emitInitialLoadError` and `_applyInitialPage` in `BlocxCollectionCoreMixin`.
- Unified error dispatch and state construction across offset-based and cursor-based initial loads.

### Task T5: Documentation & Changelog Updates
- **Commit:** `a07808e` (`docs(core): document cursor pagination, sorted insertion, clearError and limitations`)
- Added comprehensive documentation for Cursor pagination, Sorted insertion (`sortComparator`), Dismissing full-page errors (`clearError()`), and architectural Limitations to `README.md`.
- Updated `CHANGELOG.md` with release notes and timestamps for `[1.1.0]` and `[1.0.1]`.

### Task T6: Final Quality Gate Verification
- Verified all quality gates locally:
  - `dart format --output=none --set-exit-if-changed .` $\rightarrow$ 0 files changed.
  - `dart analyze --fatal-infos` $\rightarrow$ 0 issues found.
  - `dart test` $\rightarrow$ 103 tests passed (100% pass rate).
  - `dart pub publish --dry-run` $\rightarrow$ 0 warnings, 0 errors.

---

## 4. Quality Gate Results Summary

| Gate | Command | Result |
| :--- | :--- | :--- |
| Code Formatting | `dart format --output=none --set-exit-if-changed .` | PASSED (0 changed) |
| Static Analysis | `dart analyze --fatal-infos` | PASSED (0 issues) |
| Automated Tests | `dart test` | PASSED (103 passing tests) |
| Packaging Validation | `dart pub publish --dry-run` | PASSED (0 warnings) |
