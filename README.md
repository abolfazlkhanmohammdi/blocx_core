<p align="center">
  <img src="https://raw.githubusercontent.com/abolfazlkhanmohammdi/blocx_core/main/assets/pub/logo.png" width="200" alt="blocx_core logo" />
</p>

<h1 align="center">blocx_core</h1>

<p align="center">
  Composable BLoC building blocks for lists and forms in pure Dart.<br/>
  Framework-agnostic. Minimal boilerplate. Maximum control.
</p>

<p align="center">
  <a href="https://pub.dev/packages/blocx_core"><img src="https://img.shields.io/pub/v/blocx_core.svg" alt="pub version"/></a>
  <a href="https://pub.dev/packages/blocx_core"><img src="https://img.shields.io/pub/points/blocx_core" alt="pub points"/></a>
  <a href="https://pub.dev/packages/blocx_core"><img src="https://img.shields.io/badge/platform-dart%20%7C%20flutter-blue" alt="platform"/></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-green" alt="license"/></a>
</p>

---

## Overview

`blocx_core` is a Dart-only library that provides composable, mixin-based primitives for building BLoC-pattern state management layers in Dart and Flutter applications.

Rather than shipping monolithic blocs that bundle every feature together, `blocx_core` lets you opt in to only the capabilities you need — infinite scrolling, search, pull-to-refresh, selection, expansion, highlight, and more — by mixing lightweight, focused mixins into your own domain blocs.

> **Framework-agnostic.** `blocx_core` has no Flutter dependency. Pair it with [`flutter_blocx`](https://pub.dev/packages/flutter_blocx) for ready-made UI widgets built on top of this core.

---

## Table of Contents

- [Installation](#installation)
- [Architecture Overview](#architecture-overview)
- [Core Concepts](#core-concepts)
  - [BaseEntity](#baseentity)
  - [UseCase & UseCaseResult](#usecase--usecaseresult)
  - [Page\<T\>](#paget)
  - [BlocxListBloc\<T, P\>](#blocxlistbloc)
  - [BlocxFormBloc\<F, P, E\>](#blocxformbloc)
  - [ScreenManagerCubit](#screenmanagercubit)
- [List BLoC](#list-bloc)
  - [Available Mixins](#available-list-mixins)
  - [Available Events](#available-list-events)
  - [Available States](#available-list-states)
- [Form BLoC](#form-bloc)
  - [BaseFormEntity](#baseformentity)
  - [Built-in Validators](#built-in-validators)
  - [Form Events](#form-events)
  - [Form States](#form-states)
  - [Form Mixins](#form-mixins)
- [Error & Screen Management](#error--screen-management)
- [Quickstart: Paged & Searchable List](#quickstart-paged--searchable-list)
- [Quickstart: Form with Validation](#quickstart-form-with-validation)
- [Migrating from 0.6.x](#migrating-from-06x)
- [Contributing](#contributing)
- [License](#license)

---

## Installation

Add `blocx_core` to your `pubspec.yaml`:

```yaml
dependencies:
  blocx_core: ^0.7.0
```

Or install via the command line:

```sh
dart pub add blocx_core
# Inside a Flutter project:
flutter pub add blocx_core
```

Import the library:

```dart
import 'package:blocx_core/blocx_core.dart';
// For form-specific types:
import 'package:blocx_core/form_bloc.dart';
```

**Requirements:** Dart SDK `>=3.5.0`

---

## Architecture Overview

`blocx_core` is organised around three pillars:

```
┌─────────────────────────────────────────────────┐
│                  Your Domain BLoC                │
│  extends BlocxListBloc / BlocxFormBloc           │
│  with  <only the mixins you need>                │
└───────────────────┬─────────────────────────────┘
                    │ delegates async work to
┌───────────────────▼─────────────────────────────┐
│               Use Cases                          │
│  BlocxBaseUseCase → UseCaseResult<T>             │
│  BlocxPaginationUseCase / SearchUseCase          │
└───────────────────┬─────────────────────────────┘
                    │ UI intents via
┌───────────────────▼─────────────────────────────┐
│           ScreenManagerCubit                     │
│  Emits snackbar / error-page / pop intents       │
│  UI layer decides how to render them             │
└─────────────────────────────────────────────────┘
```

---

## Core Concepts

### BaseEntity

All domain objects used with list blocs must extend `BaseEntity`. It provides stable identity and equality semantics based on a unique `id`.

```dart
class Product extends BaseEntity {
  @override
  final String id;

  final String name;
  final double price;

  const Product({required this.id, required this.name, required this.price});
}
```

The `identifier` getter (also on `BaseEntity`) is used internally for scroll-to operations.

---

### UseCase & UseCaseResult

Every piece of async business logic is encapsulated in a `BlocxBaseUseCase<T>` subclass. Use cases return a `UseCaseResult<T>`, which is either a success carrying data or a failure carrying an error and optional stack trace.

```dart
class FetchProducts extends BlocxBaseUseCase<List<Product>> {
  final ProductRepository repo;
  FetchProducts({required this.repo});

  @override
  Future<UseCaseResult<List<Product>>> perform() async {
    try {
      final data = await repo.getAll();
      return UseCaseResult.success(data);
    } catch (e, s) {
      return UseCaseResult.failure(e, stackTrace: s);
    }
  }
}
```

For paginated data, extend `BlocxPaginationUseCase<T>` (which adds `loadCount` and `offset` parameters) or `SearchUseCase<T>` (which additionally provides `searchText`).

---

### Page\<T\>

`Page<T>` is the normalized container for a page of items returned by pagination use cases. It carries the list of items and signals whether the end of the data source has been reached.

```dart
// successResult() is a helper on BlocxPaginationUseCase that
// wraps a List<T> into a Page<T> automatically.
return successResult(items);

// To signal the last page:
return successResult(items, isLastPage: true);
```

---

### BlocxListBloc

`BlocxListBloc<T, P>` is the central class for list state management, where `T` is your entity type and `P` is an optional payload type passed when loading the initial page (use `void` if no payload is needed).

Extend it and compose only the mixins you require. Each mixin is initialized via a corresponding `init*()` call in the constructor.

---

### BlocxFormBloc

`BlocxFormBloc<F, P, E>` manages a form backed by a `BaseFormEntity` subclass (`F`), an optional initialization payload (`P`), and an enum (`E`) that enumerates the form's fields.

---

### ScreenManagerCubit

`ScreenManagerCubit` acts as a communication channel between your BLoC layer and the presentation layer. Instead of importing Flutter from within a BLoC, you emit typed intents that the UI listens to and renders.

Available intent methods (callable from any bloc):

| Method | Emitted State |
|---|---|
| `displaySnackBar(...)` | `ScreenManagerCubitStateDisplaySnackbar` |
| `displayErrorWidget(...)` | `ScreenManagerCubitStateDisplayErrorPage` |
| `displayErrorWidgetByErrorCode(...)` | `ScreenManagerCubitStateDisplayErrorPageByErrorCode` |
| `pop()` | `ScreenManagerCubitStatePop` |

Every bloc constructed in this library accepts a `ScreenManagerCubit` instance and exposes the above helpers for you to call directly inside your event handlers.

---

## List BLoC

### Available List Mixins

Mix these into your `BlocxListBloc` subclass. Call the corresponding `init*()` method in your constructor.

| Mixin | `init` call | Capability |
|---|---|---|
| `BlocxInfiniteListBlocMixin` | `initInfiniteList()` | Next-page loading, reached-end flag, scroll-triggered pagination |
| `BlocxSearchableListBlocMixin` | `initSearchable()` | Debounced search, search-next-page, search-refresh |
| `BlocxRefreshableListBlocMixin` | `initRefresh()` | Pull-to-refresh semantics |
| `BlocxSelectableListBlocMixin` | `initSelectable()` | Single and multi-item selection and deselection |
| `BlocxHighlightableListBlocMixin` | _(auto)_ | Highlight and clear-highlight on individual items |
| `BlocxExpandableListBlocMixin` | _(auto)_ | Expand, collapse, and toggle expansion on individual items |
| `BlocxScrollableListBlocMixin` | _(auto)_ | Programmatic scroll-to-item and scroll-to-identifier |
| `BlocxDeletableListBlocMixin` | _(auto)_ | Remove single items, remove by ID, remove multiple items |
| `BlocxListBlocSyncStreamMixin` | _(auto)_ | Sync list state from an external stream |

---

### Available List Events

| Event | Description |
|---|---|
| `BlocxListEventLoadInitialPage<T, P>` | Load the first page of data |
| `BlocxListEventLoadNextPage<T>` | Append the next page to the existing list |
| `BlocxListEventRefreshData<T>` | Reload the list from the source |
| `BlocxListEventSearch<T>` | Run a debounced search query |
| `BlocxListEventSearchNextPage<T>` | Load the next page of search results |
| `BlocxListEventSearchRefresh<T>` | Refresh the current search results |
| `BlocxListEventClearSearch<T>` | Clear search and restore the base list |
| `BlocxListEventSelectItem<T>` | Select a single item |
| `BlocxListEventDeselectItem<T>` | Deselect a single item |
| `BlocxListEventSelectMultipleItems<T>` | Select multiple items at once |
| `BlocxListEventDeselectMultipleItems<T>` | Deselect multiple items at once |
| `BlocxListEventClearSelection<T>` | Clear all selections |
| `BlocxListEventHighlightItem<T>` | Highlight a specific item |
| `BlocxListEventClearHighlightedItem<T>` | Clear the highlight on an item |
| `BlocxListEventExpandItem<T>` | Expand an item's details |
| `BlocxListEventCollapseItem<T>` | Collapse an item's details |
| `BlocxListEventToggleItemExpansion<T>` | Toggle expansion state of an item |
| `BlocxListEventScrollToItem<T>` | Scroll to a given item |
| `BlocxListEventScrollToIdentifier<T>` | Scroll to an item by its identifier |
| `BlocxListEventAddItem<T>` | Insert an item into the list |
| `BlocxListEventUpdateItem<T>` | Replace an item in the list |
| `BlocxListEventRemoveItem<T>` | Remove a single item |
| `BlocxListEventRemoveItemById<T>` | Remove an item by its ID |
| `BlocxListEventRemoveMultipleItems<T>` | Remove multiple items at once |
| `BlocxListEventReplaceList<T>` | Replace the entire list |

---

### Available List States

| State | Description |
|---|---|
| `BlocxListStateLoading<T>` | Initial load or refresh in progress |
| `BlocxListStateLoaded<T>` | Data is available |
| `BlocxListStateError<T>` | An error occurred while loading |
| `BlocxListStateSelectionChanged<T>` | Selection has been updated |
| `BlocxListStateScrollToItem<T>` | Scroll-to intent emitted |

Use the `ListStateExtensions` extension on `BlocxListState<T>` for convenience accessors.

---

## Form BLoC

### BaseFormEntity

Your form's data model must extend `BaseFormEntity<F, E>`, where `F` is the form entity itself and `E` is an enum enumerating the form's fields. The entity must be immutable and implement `copyWith`.

```dart
enum ProfileField { name, email, phone }

class ProfileForm extends BaseFormEntity<ProfileForm, ProfileField> {
  final String name;
  final String email;
  final String phone;

  const ProfileForm({
    this.name = '',
    this.email = '',
    this.phone = '',
  });

  @override
  ProfileForm copyWith({String? name, String? email, String? phone}) =>
      ProfileForm(
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
      );
}
```

---

### Built-in Validators

Validators extend `BlocxFieldValidator<T>` and are composed per field inside a `BlocxFormValidator` subclass.

| Validator | Description |
|---|---|
| `BlocxRequiredValidator` | Field must not be null or empty |
| `BlocxMinLengthValidator` | String must have at least N characters |
| `BlocxMaxLengthValidator` | String must not exceed N characters |
| `BlocxExactLengthValidator` | String must be exactly N characters |
| `BlocxLengthRangeValidator` | String length within `[min, max]` |
| `BlocxRegexValidator` | String must match a regular expression |
| `BlocxMinValueValidator<T>` | Numeric value >= min |
| `BlocxMaxValueValidator<T>` | Numeric value <= max |
| `BlocxRangeValueValidator` | Numeric value within `[min, max]` |
| `BlocxMinDateValidator` | DateTime not before `minDate` |
| `BlocxMaxDateValidator` | DateTime not after `maxDate` |
| `BlocxDateRangeValidator` | DateTime within `[minDate, maxDate]` |
| `BlocxMatchFieldValidator<T>` | Field value must match another field's value |
| `BlocxConditionalRequiredValidator` | Required only when a condition is true |

---

### Form Events

| Event | Description |
|---|---|
| `BlocxFormEventInit<P>` | Initialize the form, optionally with a payload |
| `BlocxFormEventFetchRequiredInfo` | Fetch any data the form depends on before rendering |
| `BlocxFormEventUpdateData<E>` | Update the value of a single field |
| `BlocxFormEventUpdateFormData<P>` | Replace the entire form data object |
| `BlocxFormEventSubmit` | Validate and submit the form |
| `BlocxFormEventSetErrorToField<E>` | Manually set an error on a specific field |
| `BlocxFormEventSetTimedErrorToField<E>` | Set a time-limited error on a field |
| `BlocxFormEventClearFieldError<E>` | Clear the error on a specific field |
| `BlocxFormEventCheckUniqueValue<E>` | Trigger async uniqueness check for a field |
| `BlocxFormEventNextStep` | Advance to the next step (stepped forms) |
| `BlocxFormEventPreviousStep` | Return to the previous step (stepped forms) |
| `BlocxFormEventGoToStep` | Jump to a specific step (stepped forms) |

---

### Form States

| State | Description |
|---|---|
| `BlocxFormStateInitial<F, E>` | Form not yet initialized |
| `BlocxFormStateLoaded<F, E>` | Form loaded and ready for interaction |
| `BlocxFormStateFormUpdated<F, E>` | A field value or error has changed |
| `BlocxFormStateApplyInitialDataToForm<F, E>` | Initial data applied to the form |
| `BlocxFormStateSubmittingForm<F, E>` | Submission in progress |
| `BlocxFormStateFormSubmitted<F, E>` | Submission completed successfully |

---

### Form Mixins

| Mixin | Capability |
|---|---|
| `BlocxFormValidationMixin` | Per-field and whole-form validation |
| `BlocxFormErrorsMixin` | Programmatic error setting and clearing |
| `BlocxInfoFetcherFormMixin` | Fetch remote data required before the form is ready |
| `BlocxSteppedFormMixin` | Multi-step form navigation (next, previous, go-to) |
| `BlocxUniqueFieldValidatorMixin` | Async server-side uniqueness validation per field |

---

## Error & Screen Management

Any bloc that receives a `ScreenManagerCubit` can emit UI intents without importing Flutter. The presentation layer listens to the cubit's stream and handles each state:

```dart
// Inside a BLoC event handler:
displaySnackBar(
  message: 'Item deleted successfully.',
  type: BlocXSnackbarType.success,
);

displayErrorWidget(
  error: ReadableError(title: 'Not Found', message: 'The resource could not be loaded.'),
);

pop();
```

```dart
// In your Flutter widget or BlocListener:
BlocListener<ScreenManagerCubit, ScreenManagerCubitState>(
  bloc: screenCubit,
  listener: (context, state) {
    if (state is ScreenManagerCubitStateDisplaySnackbar) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message)),
      );
    } else if (state is ScreenManagerCubitStatePop) {
      Navigator.of(context).pop();
    }
  },
);
```

`BlocXErrorCode` and `BlocXSnackbarType` enums give you typed control over the intent payload.

---

## Quickstart: Paged & Searchable List

The following example wires up a fully paginated, searchable, refreshable, and selectable list for a `Todo` entity.

### 1. Define the Entity

```dart
import 'package:blocx_core/blocx_core.dart';

class Todo extends BaseEntity {
  @override
  final String id;
  final String title;
  final bool completed;

  const Todo({required this.id, required this.title, this.completed = false});
}
```

### 2. Define the Repository Contract

```dart
abstract class TodoRepository {
  Future<List<Todo>> fetchPage({required int limit, required int offset});
  Future<List<Todo>> search({required String query, required int limit, required int offset});
}
```

### 3. Implement Use Cases

```dart
class FetchTodosUseCase extends BlocxPaginationUseCase<Todo> {
  final TodoRepository repo;

  FetchTodosUseCase({
    required this.repo,
    required super.loadCount,
    required super.offset,
  });

  @override
  Future<UseCaseResult<Page<Todo>>> perform() async {
    try {
      final items = await repo.fetchPage(limit: loadCount, offset: offset);
      return successResult(items);
    } catch (e, s) {
      return UseCaseResult.failure(e, stackTrace: s);
    }
  }
}

class SearchTodosUseCase extends SearchUseCase<Todo> {
  final TodoRepository repo;

  SearchTodosUseCase({
    required this.repo,
    required super.searchText,
    required super.loadCount,
    required super.offset,
  });

  @override
  Future<UseCaseResult<Page<Todo>>> perform() async {
    try {
      final items = await repo.search(
        query: searchText,
        limit: loadCount,
        offset: offset,
      );
      return successResult(items);
    } catch (e, s) {
      return UseCaseResult.failure(e, stackTrace: s);
    }
  }
}
```

### 4. Compose the BLoC

```dart
class TodosBloc extends BlocxListBloc<Todo, void>
    with
        BlocxInfiniteListBlocMixin<Todo, void>,
        BlocxSearchableListBlocMixin<Todo, void>,
        BlocxRefreshableListBlocMixin<Todo, void>,
        BlocxSelectableListBlocMixin<Todo, void> {
  final TodoRepository repo;

  TodosBloc({required this.repo, required ScreenManagerCubit screen})
      : super(screen, BlocxInfiniteListBloc()) {
    initInfiniteList();
    initSearchable();
    initRefresh();
    initSelectable();
    add(BlocxListEventLoadInitialPage<Todo, void>());
  }

  @override
  BlocxPaginationUseCase<Todo>? get loadInitialPageUseCase =>
      FetchTodosUseCase(repo: repo, loadCount: 20, offset: 0);

  @override
  BlocxPaginationUseCase<Todo>? get loadNextPageUseCase =>
      FetchTodosUseCase(repo: repo, loadCount: 20, offset: list.length);

  @override
  BlocxPaginationUseCase<Todo>? get refreshPageUseCase =>
      FetchTodosUseCase(repo: repo, loadCount: list.length, offset: 0);

  @override
  SearchUseCase<Todo>? searchUseCase(String q, {int? loadCount, int? offset}) =>
      SearchTodosUseCase(
        repo: repo,
        searchText: q,
        loadCount: loadCount ?? 20,
        offset: offset ?? 0,
      );

  @override
  (String, String?) convertErrorToMessageAndTitle(Object error) =>
      ('Failed to load todos. Please try again.', null);
}
```

### 5. Drive the BLoC

```dart
final screen = ScreenManagerCubit();
final bloc = TodosBloc(repo: myRepo, screen: screen);

// Pagination
bloc.add(BlocxListEventLoadNextPage<Todo>());

// Search
bloc.add(BlocxListEventSearch<Todo>(searchText: 'urgent'));
bloc.add(BlocxListEventClearSearch<Todo>());

// Selection
bloc.add(BlocxListEventSelectItem<Todo>(item: someTodo));
bloc.add(BlocxListEventClearSelection<Todo>());

// Refresh
bloc.add(BlocxListEventRefreshData<Todo>());
```

---

## Quickstart: Form with Validation

### 1. Define the Field Enum and Form Entity

```dart
import 'package:blocx_core/form_bloc.dart';

enum SignUpField { email, password, confirmPassword }

class SignUpForm extends BaseFormEntity<SignUpForm, SignUpField> {
  final String email;
  final String password;
  final String confirmPassword;

  const SignUpForm({
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
  });

  @override
  SignUpForm copyWith({
    String? email,
    String? password,
    String? confirmPassword,
  }) =>
      SignUpForm(
        email: email ?? this.email,
        password: password ?? this.password,
        confirmPassword: confirmPassword ?? this.confirmPassword,
      );
}
```

### 2. Define the Validator

```dart
class SignUpValidator extends BlocxFormValidator<SignUpForm, SignUpField> {
  @override
  Map<SignUpField, List<BlocxFieldValidator>> get validators => {
        SignUpField.email: [
          BlocxRequiredValidator(),
          BlocxRegexValidator(
            pattern: r'^[^@]+@[^@]+\.[^@]+$',
            errorMessage: 'Enter a valid email address.',
          ),
        ],
        SignUpField.password: [
          BlocxRequiredValidator(),
          BlocxMinLengthValidator(minLength: 8),
        ],
        SignUpField.confirmPassword: [
          BlocxRequiredValidator(),
          BlocxMatchFieldValidator<String>(
            otherFieldValue: (form) => form.password,
            errorMessage: 'Passwords do not match.',
          ),
        ],
      };
}
```

### 3. Implement the FormBloc

```dart
class SignUpBloc extends BlocxFormBloc<SignUpForm, void, SignUpField>
    with BlocxFormValidationMixin<SignUpForm, void, SignUpField> {
  SignUpBloc({required ScreenManagerCubit screen})
      : super(screen, const SignUpForm(), SignUpValidator());

  @override
  Future<void> onSubmit(SignUpForm form) async {
    // Perform submission logic, e.g. call a use case.
    // Call displaySnackBar or pop() on success/failure.
  }
}
```

### 4. Interact with the FormBloc

```dart
// Update a field value:
bloc.add(BlocxFormEventUpdateData<SignUpField>(
  field: SignUpField.email,
  value: 'user@example.com',
));

// Submit the form:
bloc.add(BlocxFormEventSubmit());
```

---

## Migrating from 0.6.x

Version 0.7.0 lowers the minimum Dart SDK requirement from `3.10` to `3.5`, broadening compatibility with existing projects. No public API changes are introduced. Upgrade your constraint:

```yaml
dependencies:
  blocx_core: ^0.7.0
```

---

## Contributing

Contributions are welcome. Please follow these guidelines:

- **Code style:** Run `dart format .` before committing. All lints in `analysis_options.yaml` must pass (`dart analyze`).
- **Documentation:** All public APIs must be documented with dartdoc comments.
- **Tests:** Add or update tests for every new mixin, event, state, or validator. Run `dart test` to verify the full test suite passes.
- **Pull requests:** Keep changes focused. One feature or fix per pull request.

---

## License

This project is licensed under the MIT License. See the [`LICENSE`](LICENSE) file at the repository root for details.