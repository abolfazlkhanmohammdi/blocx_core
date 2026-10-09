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

## Architectural Notes & Critique Review (C8)

### 1. `BlocxBaseEntity` Identity vs. Equality
- In `blocx_core`, entities identify themselves via the contractual `identifier` getter. This getter is used by collection extension helpers (`replaceItem`, `removeById`, `indexById`), deduplication logic (`addItem`), selection sets, and live stream sync.
- `BlocxBaseEntity` intentionally leaves `operator ==` and `hashCode` untouched (defaulting to standard Dart `Object` identity) so developers can freely use `equatable`, `freezed`, or custom field equality without conflict. Documentation comments in `base_entity.dart` and `README.md` have been aligned to reflect this.

### 2. `resolveCommandEntities` Signature
- In `BlocxBaseUseCase`, `resolveCommandEntities(Input input, Output output)` takes two parameters (`input` and `output`). A legacy README mention showing three arguments was corrected.

### 3. Collection Search Model
- `BlocxCollectionSearchableMixin` filters and displays results in the collection's single active list while marking state flags (`isSearching: true`). When the search is cleared, the normal initial list is reloaded via `clearSearch()`. Documentation in `blocx_collection_bloc.dart` previously referred to a "separate result list" and has been updated to clarify that search operates directly on the collection list.

### 4. Mixin Composition Architecture
- Collection mixins are registered via type checks (`this is BlocxCollection...Mixin`) during BLoC initialization. This provides automatic zero-configuration registration for the 10 built-in mixins. Custom collection behaviors can be implemented either by extending or overriding mixin hooks or via custom BLoC event transformers.
