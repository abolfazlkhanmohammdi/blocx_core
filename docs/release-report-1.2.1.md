# Release Report: blocx_core 1.2.1

Date: 2026-10-11
Repository: `abolfazlkhanmohammdi/blocx_core`
Branch: `develop`
Target Release: `1.2.1`

---

## 1. Work Package Execution Status

| Work Package | Title | Status | Commit / Notes |
| :--- | :--- | :--- | :--- |
| **WP0** | Preflight Verification | **DONE** | Pub.dev at 1.2.0; test suite clean (130 tests); 1.2.0 release commit verified at `fc5175c` (merged PR #16 from `138b0d5`). |
| **WP1** | Documentation Accuracy & Readme Guard | **DONE** | Commits `b5a97c5` and `539f62b`. Corrected all inaccurate snippets, added `tool/check_readme.dart`, allowlist, forbidden list, and CI step. |
| **WP6** | Token-Free Release Workflows | **DONE** | Commit `84b55b8`. Updated `release.yml` and `publish.yml` to Appendix A1 & A2 (token-free, OIDC via `workflow_dispatch`). Verified 0 occurrences of `RELEASE_TOKEN`. |
| **WP7** | Version Bump, Changelog & Report | **DONE** | Bumped version to `1.2.1` in `pubspec.yaml`, updated `CHANGELOG.md` with `## [1.2.1] - 2026-10-11`, generated release report. |

---

## 2. Quality Gate Verification

### Baseline (WP0):
- `dart format --output=none --set-exit-if-changed .`: Passed (0 files changed)
- `dart analyze --fatal-infos`: Passed (0 issues found)
- `dart test`: Passed (130 test cases)

### Final Gate (WP7):
- `dart format --output=none --set-exit-if-changed .`: Passed (0 files changed)
- `dart analyze --fatal-infos`: Passed (0 issues found)
- `dart test`: Passed (130 test cases)
- `dart run tool/check_readme.dart`: Passed (22 symbols verified, 0 forbidden tokens)

---

## 3. README Corrections Applied (Beyond Basic Spec)

1. Replaced nonexistent `refreshTask` with `refreshPageUseCaseTask` (and `refreshPageCursorTask`).
2. Corrected filter methods from non-existent property `currentFilter` to `setFilter(...)` and `getFilter()`.
3. Replaced `highlightedItems` and `expandedItems` with `highlightedItemIds` and `expandedItemIds`.
4. Corrected collection insertion event to `BlocxCollectionEventAddItem`.
5. Fixed stepped form entity properties: `currentStep` / `totalSteps` -> `stepIndex` / `maxStep`.
6. Removed references to `MockUseCase` in favor of standard mock patterns.
7. Corrected fake cursor pagination helper `FakeCursorPaginatedSource` -> `FakePaginatedSource`.
8. Replaced short mixin abbreviations with their fully qualified names (`BlocxCollectionCoreMixin`, `BlocxFormCoreMixin`, `BlocxCollectionSearchMixin`, etc.).

---

## 4. Owner Actions Required

1. **Re-point published tags on origin (once before merging release PR):**
   ```bash
   git tag v1.2.0 fc5175c && git push origin v1.2.0
   git push origin --delete v1.1.0 v1.0.1
   ```
2. **Confirm Pub.dev Automated Publishing:**
   Verify at https://pub.dev/packages/blocx_core/admin that automated publishing is enabled with tag pattern `v{{version}}` and environment `pub.dev`.
3. **Merge Release PR:**
   Merge the `develop` -> `main` Release PR. The workflow will run CI, check changelog, create tag `v1.2.1`, and trigger `publish.yml`.
4. **Approve Publishing:**
   Approve the `pub.dev` deployment environment on GitHub Actions.
5. **Fallback (if dispatch run rejected by pub.dev):**
   ```bash
   git push origin --delete v1.2.1
   git tag v1.2.1 <main-commit-hash> && git push origin v1.2.1
   ```
