# blocx\_core

Composable BLoC building blocks for **lists** and **forms** in pure Dart. Use small, focused mixins to add paging, search, refresh, selection, and error surfacing to your own domain BLoCs and use-cases.

> Framework-agnostic core. Pair with **blocx\_flutter** for ready-made UI widgets.

---

## Installing

Use this package as a library in your Dart/Flutter project.

### Depend on it

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  blocx_core: ^0.5.0-beta
```

Or add via the command line:

```sh
dart pub add blocx_core
# or, if inside a Flutter app:
# flutter pub add blocx_core
```

### Import it

```dart
import 'package:blocx_core/blocx_core.dart';
```

---

## What you get

* **Mixins, not monoliths** – compose features: infinite paging, search, refresh, selection, highlight, expand, scroll-to.
* **Use cases** – `BaseUseCase<T>` returning `UseCaseResult<T>` for uniform success/failure handling.
* **Pagination primitives** – `Page<T>`, `PaginationUseCase<T, P>`, `SearchUseCase<T>`.
* **List bloc family** – `ListBloc<T, P>` + mixins for data, infinite, searchable, selectable, refreshable, etc.
* **Form bloc** – helpers for field state, validation, submit/reset.
* **Screen manager hooks** – forward snackbars, errors, and navigation intents via `ScreenManagerCubit` (UI layer chooses how to render).

---

## Concepts (short & sweet)

* **`BaseEntity`** – identity/equality for your domain types.\\
* **`UseCase` & `UseCaseResult`** – encapsulate async work; return success with data or failure with error/stack.\\
* **`Page<T>`** – normalized page of items; used by list/pagination use cases.\\
* **`ListBloc<T, P>`** – central list state + events; extend it and opt‑in via mixins:
  `ListBlocDataMixin`, `InfiniteListBlocMixin`, `SearchableListBlocMixin`, `RefreshableListBlocMixin`, `SelectableListBlocMixin` (and helpers like highlight/expand).\\
* **`FormBloc<F, P, E>`** – manage form fields, validation, submit/reset.\\
* **`ScreenManagerCubit`** – emit “display snackbar/error / pop” intents from your BLoC to the presentation layer.

---

## Quickstart: paged + searchable list

### 1) Entity

```dart
import 'package:blocx_core/blocx_core.dart';

class Todo extends BaseEntity { // equality by id
  @override
  final String id;
  final String title;
  const Todo({required this.id, required this.title});
}
```

### 2) Use cases

```dart
abstract class TodoRepo {
  Future<List<Todo>> fetch({required int limit, required int offset});
  Future<List<Todo>> search({required String q, required int limit, required int offset});
}

class FetchTodos extends PaginationUseCase<Todo, void> { // P is payload (void here)
  final TodoRepo repo;
  FetchTodos({required this.repo, required super.loadCount, required super.offset});

  @override
  Future<UseCaseResult<Page<Todo>>> perform() async {
    try {
      final items = await repo.fetch(limit: loadCount, offset: offset);
      return successResult(items);
    } catch (e, s) {
      return UseCaseResult.failure(e, stackTrace: s);
    }
  }
}

class SearchTodos extends SearchUseCase<Todo> {
  final TodoRepo repo;
  SearchTodos({required this.repo, required super.searchText, required super.loadCount, required super.offset});

  @override
  Future<UseCaseResult<Page<Todo>>> perform() async {
    try {
      final items = await repo.search(q: searchText, limit: loadCount, offset: offset);
      return successResult(items);
    } catch (e, s) {
      return UseCaseResult.failure(e, stackTrace: s);
    }
  }
}
```

### 3) Bloc (compose mixins)

```dart
class TodosBloc extends ListBloc<Todo, void>
    with
        ListBlocDataMixin<Todo, void>,
        InfiniteListBlocMixin<Todo, void>,
        SearchableListBlocMixin<Todo, void>,
        RefreshableListBlocMixin<Todo, void>,
        SelectableListBlocMixin<Todo, void> {
  final TodoRepo repo;

  TodosBloc({required this.repo, required ScreenManagerCubit screen}) : super(screen, InfiniteListBloc()) {
    initDataMixin();      // holds the list, exposes helpers
    initInfiniteList();   // handles next-page logic & flags
    initSearchable();     // debounced search flow
    initRefresh();        // pull-to-refresh semantics
    initSelectable();     // multi/single selection helpers
    add(ListEventLoadInitialPage<Todo, void>());
  }

  @override
  PaginationUseCase<Todo, void>? get loadInitialPageUseCase =>
      FetchTodos(repo: repo, loadCount: 20, offset: 0);

  @override
  PaginationUseCase<Todo, void>? get loadNextPageUseCase =>
      FetchTodos(repo: repo, loadCount: 20, offset: list.length);

  @override
  PaginationUseCase<Todo, void>? get refreshPageUseCase =>
      FetchTodos(repo: repo, loadCount: list.length, offset: 0);

  @override
  SearchUseCase<Todo>? searchUseCase(String q, {int? loadCount, int? offset}) =>
      SearchTodos(repo: repo, searchText: q, loadCount: loadCount ?? 20, offset: offset ?? 0);

  @override
  (String, String?) convertErrorToMessageAndTitle(Object error) =>
      ('Something went wrong: {error}', null);
}
```

### 4) Drive it (wherever you orchestrate)

```dart
final screen = ScreenManagerCubit();
final bloc = TodosBloc(repo: repo, screen: screen);

bloc.add(ListEventLoadInitialPage<Todo, void>());
bloc.add(ListEventLoadNextPage<Todo>());
bloc.add(ListEventSearch<Todo>(searchText: 'urgent'));
bloc.add(ListEventClearSearch<Todo>());
```

---

## Error & snackbar flow

Emit intents from any bloc by calling:
`displaySnackBar(...)`, `displayErrorWidget(...)`, `displayErrorWidgetByErrorCode(...)`, `pop()`.
Your presentation layer (Flutter or other) listens to `ScreenManagerCubit` and renders snackbars, pages, or navigation.
---

## Contributing

* Document public APIs with dartdoc.
* Keep lints green: `dart format . && dart analyze`.
* Add tests for each new mixin path or event/state transition.

---

## License

This project is licensed under the terms described in `LICENSE` at the repository root.
