# BlocX Fix Notes

## Baseline Results (T0.1) - 2026-10-09

### Environment
- **Dart SDK:** 3.12.0 (stable)
- **Flutter SDK:** 3.44.0 (channel stable)
- **Host OS:** Windows x64

### `blocx_core` Baseline
- **Formatting (`dart format --output=none --set-exit-if-changed .`):** Clean (136 files, 0 changed).
- **Analysis (`dart analyze --fatal-infos`):** Clean (No issues found).
- **Unit Tests (`dart test`):** 48/48 test assertions passed across 6 test files.
- **Example (`dart run example/blocx_core_example.dart`):** Executed successfully.

### `flutter_blocx` Baseline
- **Formatting (`dart format --output=none --set-exit-if-changed .`):** Clean (84 files, 0 changed).
- **Analysis (`flutter analyze --fatal-infos`):** Clean (No issues found).
- **Unit Tests (`flutter test`):** 4/4 tests passed.
- **Example Web Build (`flutter build web`):** Built successfully (`build/web`).
- **Example Test Note:** `example/test/widget_test.dart` contains stock counter smoke test expecting text '0', which fails on the BlocX example UI; noted for test harness cleanup.
