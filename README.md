<p align="center">
  <img src="https://raw.githubusercontent.com/abolfazlkhanmohammdi/blocx_core/main/assets/pub/logo.png" width="200" alt="blocx_core logo" />
</p>

<h1 align="center">blocx_core</h1>

<p align="center">
  Build production-ready list and form BLoCs with pagination, search, refresh, validation, and selection built in.
</p>

<p align="center">
  Pure Dart • Composable Mixins • flutter_bloc Compatible
</p>

---

# Why BlocX?

Most Flutter applications eventually build the same BLoCs over and over:

- Infinite scrolling lists
- Searchable lists
- Pull-to-refresh
- Item selection
- Expandable rows
- Form validation
- Async uniqueness checks
- Error handling

BlocX extracts these patterns into reusable, composable building blocks so you can focus on business logic instead of infrastructure.

---

# Before vs After

### Traditional flutter_bloc

```dart
class TodosBloc extends Bloc<TodosEvent, TodosState> {
  // 200+ lines of infrastructure code
}
```

### BlocX

```dart
class TodosBloc extends BlocxCollectionBloc<Todo, void>
        with
                BlocxCollectionInfiniteMixin<Todo, void>,
                BlocxCollectionSearchableMixin<Todo, void>,
                BlocxCollectionRefreshableMixin<Todo, void>,
                BlocxCollectionSelectableMixin<Todo, void> {}
```

The behavior is provided by the mixins. Your code stays focused on the domain.

---

# What You Get

## Lists

- Infinite scrolling
- Debounced search
- Search pagination
- Pull-to-refresh
- Selection and multi-selection
- Highlighting
- Expansion
- Scroll-to-item
- Stream synchronization

## Forms

- Validation
- Async uniqueness checks
- Multi-step forms
- Field-level errors
- Submission workflows

## Architecture

- Pure Dart
- No Flutter dependency
- flutter_bloc compatible
- Use-case driven
- Typed error handling
- Composable feature mixins

> **Framework-agnostic.** `blocx_core` has no Flutter dependency. Pair it with [`flutter_blocx`](https://pub.dev/packages/flutter_blocx) for ready-made UI widgets built on top of this core.

---

# Is BlocX Right For Me?

Use BlocX if:

- You already use flutter_bloc
- You have many list screens
- You repeatedly implement pagination and search
- You want consistency across projects

You may not need BlocX if:

- Your application only contains a few simple screens
- You prefer Riverpod-style state management
- You want minimal abstractions

---

# Architecture Philosophy

BlocX is a composable application framework built on top of the BLoC pattern that removes repetitive state-management infrastructure while keeping business logic explicit.

Build only what your screen requires:

- Pagination
- Search
- Refresh
- Selection
- Highlighting
- Expansion
- Forms
- Validation

Nothing more.

---

## Table of Contents

- [Installation](#installation)
- [Architecture Overview](#architecture-overview)
- [Core Concepts](#core-concepts)
  - [BlocxBaseEntity](#BlocxBaseEntity)
  - [UseCase & UseCaseResult](#usecase--usecaseresult)
  - [Page\<T\>](#paget)
  - [BlocxCollectionBloc\<T, P\>](#blocxcollectionbloc)
  - [BlocxFormBloc\<F, P, E\>](#blocxformbloc)
  - [ScreenManagerCubit](#screenmanagercubit)
- [List BLoC](#list-bloc)
  - [Available Mixins](#available-list-mixins)
  - [Available Events](#available-list-events)
  - [Available States](#available-list-states)
- [Form BLoC](#form-bloc)
  - [BlocxBaseFormEntity](#blocxbaseformentity)
  - [Built-in Validators](#built-in-validators)
  - [Form Events](#form-events)
  - [Form States](#form-states)
  - [Form Mixins](#form-mixins)
- [Use Case Tasks](#use-case-tasks)
- [Error & Screen Management](#error--screen-management)
- [Quickstart: Paged & Searchable List](#quickstart-paged--searchable-list)
- [Quickstart: Form with Validation](#quickstart-form-with-validation)
- [Migrating from 0.7.x](#migrating-from-07x)
- [Contributing](#contributing)
- [License](#license)

---

## Installation

Add `blocx_core` to your `pubspec.yaml`:

```yaml
dependencies:
  blocx_core: ^0.8.3
```

Or install via the command line:

```sh
dart pub add blocx_core
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
│  extends BlocxCollectionBloc / BlocxFormBloc     │
│  with  <only the mixins you need>                │
└───────────────────┬─────────────────────────────┘
                    │ delegates async work to
┌───────────────────▼─────────────────────────────┐
│               Use Cases                          │
│  BlocxBaseUseCase → BlocxUseCaseResult<T>        │
│  BlocxPaginatedUseCase / BlocxSearchUseCase      │
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

### BlocxBaseEntity

All domain objects used with list blocs must extend `BlocxBaseEntity`. It provides stable identity and equality semantics based on a unique `id`.

```dart
class Product extends BlocxBaseEntity {
  @override
  final String id;

  final String name;
  final double price;

  const Product({required this.id, required this.name, required this.price});
}
```

The `identifier` getter (also on `BlocxBaseEntity`) is used internally for scroll-to operations.

---

### UseCase & UseCaseResult

Every piece of async business logic is encapsulated in a `BlocxBaseUseCase<Input, Output>` subclass. Use cases return a `BlocxUseCaseResult<Output>`, which is either a success carrying data or a failure carrying an error and stack trace.

```dart
class FetchProductUseCase extends BlocxBaseUseCase<String, Product> {
  final ProductRepository repo;
  FetchProductUseCase({required this.repo});

  @override
  Future<BlocxUseCaseResult<Product>> perform(String id) async {
    final data = await repo.getById(id);
    return success(data);
  }
}
```

> **Note:** Exception handling is built into `BlocxBaseUseCase.execute()` — you no longer need to wrap `perform()` in a try/catch. Unhandled exceptions are automatically converted to `BlocxUseCaseFailure`.

For paginated data, extend `BlocxPaginatedUseCase<Input, Output>` (where `Input` extends `BlocxPaginationInput`) or `BlocxSearchUseCase<Input, Output>` (where `Input` extends `BlocxSearchInput`, which adds `searchText`).

---

### BlocxPage\<T\>

`BlocxPage<T>` is the normalized container for a page of items returned by pagination use cases. It carries the list of items and signals whether the end of the data source has been reached.

```dart
// successResult() is a helper on BlocxPaginatedUseCase that
// wraps a List<T> into a BlocxPage<T> automatically.
return successResult(items: items, input: input);
```

`BlocxPage.hasNext` is derived automatically: the end of data is signalled when the number of items returned is less than the requested limit.

---

### BlocxCollectionBloc

`BlocxCollectionBloc<T, P>` is the central class for list state management, where `T` is your entity type and `P` is an optional payload type passed when loading the initial page (use `void` if no payload is needed).

Extend it and compose only the mixins you require. **Mixin initialization is automatic** — no manual `init*()` calls are needed in the constructor. Simply call `super()`:

```dart
class OrdersBloc extends BlocxCollectionBloc<Order, void>
    with BlocxCollectionInfiniteMixin<Order, void>,
         BlocxCollectionRefreshableMixin<Order, void> {
  OrdersBloc() : super();

  @override
  BlocxPaginatedUseCaseTask get paginationTask => BlocxPaginatedUseCaseTask(
    useCase: _getOrdersUseCase,
    inputBuilder: (offset, limit) =>
        BlocxPaginationInput(limit: limit, offset: offset),
  );
}
```

---

### BlocxFormBloc

`BlocxFormBloc<F, P, E>` manages a form backed by a `BlocxBaseFormEntity` subclass (`F`), an optional initialization payload (`P`), and an enum (`E`) that enumerates the form's fields.

---

### ScreenManagerCubit

`ScreenManagerCubit` is owned and managed internally by `BaseBloc` — you no longer need to construct or pass one explicitly. Simply call `super()` in your bloc's constructor:

```dart
class CounterBloc extends BaseBloc<CounterEvent, CounterState> {
  CounterBloc() : super(CounterStateInitial());
}
```

`ScreenManagerCubit` acts as a communication channel between your BLoC layer and the presentation layer. Instead of importing Flutter from within a BLoC, you emit typed intents that the UI listens to and renders.

Available intent methods (callable from any bloc):

| Method | Emitted State |
|---|---|
| `displaySnackBar(...)` | `ScreenManagerCubitStateDisplaySnackbar` |
| `displayErrorWidget(...)` | `ScreenManagerCubitStateDisplayErrorPage` |
| `displayErrorWidgetByErrorCode(...)` | `ScreenManagerCubitStateDisplayErrorPageByErrorCode` |
| `pop()` | `ScreenManagerCubitStatePop` |

---

## List BLoC

### Available List Mixins

Mix these into your `BlocxCollectionBloc` subclass.

| Mixin                               | Capability |
|-------------------------------------|---|
| `BlocxCollectionInfiniteMixin`      | Next-page loading, reached-end flag, scroll-triggered pagination |
| `BlocxCollectionSearchableMixin`    | Debounced search, search-next-page, search-refresh |
| `BlocxCollectionRefreshableMixin`   | Pull-to-refresh semantics |
| `BlocxCollectionSelectableMixin`    | Single and multi-item selection and deselection |
| `BlocxCollectionHighlightableMixin` | Highlight and clear-highlight on individual items |
| `BlocxCollectionExpandableMixin`    | Expand, collapse, and toggle expansion on individual items |
| `BlocxCollectionScrollableMixin`    | Programmatic scroll-to-item and scroll-to-identifier |
| `BlocxCollectionDeletableMixin`     | Remove single items, remove by ID, remove multiple items |
| `BlocxCollectionSyncStreamMixin`    | Sync list state from an external stream |

---

### Available List Events

| Event | Description |
|---|---|
| `BlocxCollectionEventLoadInitialPage<T, P>` | Load the first page of data |
| `BlocxCollectionEventLoadNextPage<T>` | Append the next page to the existing list |
| `BlocxCollectionEventRefreshData<T>` | Reload the list from the source |
| `BlocxCollectionEventSearch<T>` | Run a debounced search query |
| `BlocxCollectionEventSearchNextPage<T>` | Load the next page of search results |
| `BlocxCollectionEventSearchRefresh<T>` | Refresh the current search results |
| `BlocxCollectionEventClearSearch<T>` | Clear search and restore the base list |
| `BlocxCollectionEventSelectItem<T>` | Select a single item |
| `BlocxCollectionEventDeselectItem<T>` | Deselect a single item |
| `BlocxCollectionEventSelectMultipleItems<T>` | Select multiple items at once |
| `BlocxCollectionEventDeselectMultipleItems<T>` | Deselect multiple items at once |
| `BlocxCollectionEventClearSelection<T>` | Clear all selections |
| `BlocxCollectionEventHighlightItem<T>` | Highlight a specific item |
| `BlocxCollectionEventClearHighlightedItem<T>` | Clear the highlight on an item |
| `BlocxCollectionEventExpandItem<T>` | Expand an item's details |
| `BlocxCollectionEventCollapseItem<T>` | Collapse an item's details |
| `BlocxCollectionEventToggleItemExpansion<T>` | Toggle expansion state of an item |
| `BlocxCollectionEventScrollToItem<T>` | Scroll to a given item |
| `BlocxCollectionEventScrollToIdentifier<T>` | Scroll to an item by its identifier |
| `BlocxCollectionEventAddItem<T>` | Insert an item into the list |
| `BlocxCollectionEventUpdateItem<T>` | Replace an item in the list |
| `BlocxCollectionEventRemoveItem<T>` | Remove a single item |
| `BlocxCollectionEventRemoveItemById<T>` | Remove an item by its ID |
| `BlocxCollectionEventRemoveMultipleItems<T>` | Remove multiple items at once |
| `BlocxCollectionEventReplaceList<T>` | Replace the entire list |

---

### Available List States

| State | Description |
|---|---|
| `BlocxCollectionStateLoading<T>` | Initial load or refresh in progress |
| `BlocxCollectionStateLoaded<T>` | Data is available |
| `BlocxCollectionStateError<T>` | An error occurred while loading |
| `BlocxCollectionStateSelectionChanged<T>` | Selection has been updated |
| `BlocxCollectionStateScrollToItem<T>` | Scroll-to intent emitted |

Use the `ListStateExtensions` extension on `BlocxCollectionState<T>` for convenience accessors.

---

## Form BLoC

### BlocxBaseFormEntity

Your form's data model must extend `BlocxBaseFormEntity<F, E>`, where `F` is the form entity itself and `E` is an enum enumerating the form's fields. The entity must be immutable and implement two methods:

- **`updateByKey(E key, dynamic value)`** — returns a new instance with the named field updated. Typically delegates to `copyWith`.
- **`getValueByKey(E key)`** — returns the current value for the given field. Used for cross-field validation and debug-mode consistency checks.

```dart
enum ProfileField { name, email, phone }

class ProfileForm extends BlocxBaseFormEntity<ProfileForm, ProfileField> {
  final String name;
  final String email;
  final String phone;

  const ProfileForm({
    this.name = '',
    this.email = '',
    this.phone = '',
  });

  @override
  ProfileForm updateByKey(ProfileField key, dynamic value) => switch (key) {
    ProfileField.name  => copyWith(name: value),
    ProfileField.email => copyWith(email: value),
    ProfileField.phone => copyWith(phone: value),
  };

  @override
  dynamic getValueByKey(ProfileField key) => switch (key) {
    ProfileField.name  => name,
    ProfileField.email => email,
    ProfileField.phone => phone,
  };

  ProfileForm copyWith({String? name, String? email, String? phone}) =>
      ProfileForm(
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
      );
}
```

> **Tip — `freezed` integration:** `BlocxBaseFormEntity` works naturally with the [`freezed`](https://pub.dev/packages/freezed) package. Generate `copyWith`, `==`, and `hashCode` with `@freezed`, then implement only `updateByKey` and `getValueByKey` on top. This eliminates nearly all boilerplate for form entities.

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
| `BlocxFormInfoFetcherMixin` | Fetch remote data required before the form is ready |
| `BlocxFormSteppedMixin` | Multi-step form navigation (next, previous, go-to) |
| `BlocxUniqueFieldValidatorMixin` | Async server-side uniqueness validation per field |

---

## Use Case Tasks

`BlocxUseCaseTask` and `BlocxPaginatedUseCaseTask` pair a use case with a lazily evaluated input builder, so input is always constructed from the latest runtime state at execution time rather than at registration time.

### BlocxUseCaseTask

```dart
BlocxUseCaseTask(
  useCase: getUserUseCase,
  inputBuilder: () => GetUserInput(id: currentUserId),
);
```

### BlocxPaginatedUseCaseTask

Use this as the standard task type for `BlocxCollectionBloc.paginationTask`. The `inputBuilder` receives the current `offset` and `limit` (page size) at execution time:

```dart
@override
BlocxPaginatedUseCaseTask get paginationTask => BlocxPaginatedUseCaseTask(
  useCase: _getOrdersUseCase,
  inputBuilder: (offset, limit) =>
      BlocxPaginationInput(limit: limit, offset: offset),
);
```

To include extra fields from bloc state:

```dart
@override
BlocxPaginatedUseCaseTask get paginationTask => BlocxPaginatedUseCaseTask(
  useCase: _getOrdersUseCase,
  inputBuilder: (offset, limit) => GetOrdersInput(
    limit: limit,
    offset: offset,
    userId: payload!.id,
    status: currentFilter,
  ),
);
```

If initial load, next-page, and refresh each hit different endpoints, override `BlocxCollectionBloc.loadInitialPageTask` individually instead.

---

## Error & Screen Management

Any bloc can emit UI intents without importing Flutter. Error handling is built into `BaseBloc` — call `handleError` from event handlers to log and surface errors via the configured `errorDisplayPolicy` (snackbar by default):

```dart
} catch (e, st) {
  handleError(e, emit, stacktrace: st);
}
```

To display a full-page error instead, override `errorDisplayPolicy` in your bloc:

```dart
@override
ErrorDisplayPolicy get errorDisplayPolicy => ErrorDisplayPolicy.page;
```

Register a `BlocxErrorTranslator` once at app startup to map raw exceptions to human-readable `ReadableError` instances — blocs pick it up automatically.

The presentation layer listens to `ScreenManagerCubit` and handles each intent:

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

> **See a complete runnable example** in the [`flutter_blocx` example app](https://pub.dev/packages/flutter_blocx/example).

### 1. Define the Entity

```dart
import 'package:blocx_core/blocx_core.dart';

class Todo extends BlocxBaseEntity {
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
class FetchTodosUseCase extends BlocxPaginatedUseCase<BlocxPaginationInput, Todo> {
  final TodoRepository repo;
  FetchTodosUseCase({required this.repo});

  @override
  Future<BlocxUseCaseResult<BlocxPage<Todo>>> perform(BlocxPaginationInput input) async {
    final items = await repo.fetchPage(limit: input.limit, offset: input.offset);
    return successResult(items: items, input: input);
  }
}

class SearchTodosUseCase extends BlocxSearchUseCase<BlocxSearchInput, Todo> {
  final TodoRepository repo;
  SearchTodosUseCase({required this.repo});

  @override
  Future<BlocxUseCaseResult<BlocxPage<Todo>>> perform(BlocxSearchInput input) async {
    final items = await repo.search(
      query: input.searchText,
      limit: input.limit,
      offset: input.offset,
    );
    return successResult(items: items, input: input);
  }
}
```

### 4. Compose the BLoC

```dart
class TodosBloc extends BlocxCollectionBloc<Todo, void>
    with
        BlocxCollectionInfiniteMixin<Todo, void>,
        BlocxCollectionSearchableMixin<Todo, void>,
        BlocxCollectionRefreshableMixin<Todo, void>,
        BlocxCollectionSelectableMixin<Todo, void> {
  final TodoRepository repo;
  final FetchTodosUseCase _fetchUseCase;
  final SearchTodosUseCase _searchUseCase;

  TodosBloc({required this.repo})
      : _fetchUseCase = FetchTodosUseCase(repo: repo),
        _searchUseCase = SearchTodosUseCase(repo: repo),
        super() {
    add(BlocxCollectionEventLoadInitialPage<Todo, void>(payload: null));
  }

  @override
  BlocxPaginatedUseCaseTask get paginationTask => BlocxPaginatedUseCaseTask(
    useCase: _fetchUseCase,
    inputBuilder: (offset, limit) =>
        BlocxPaginationInput(limit: limit, offset: offset),
  );

  @override
  BlocxPaginatedUseCaseTask? get searchUseCaseTask => BlocxPaginatedUseCaseTask(
    useCase: _searchUseCase,
    inputBuilder: (offset, limit) => BlocxSearchInput(
      searchText: currentSearchText,
      limit: limit,
      offset: offset,
    ),
  );
}
```

> **Note:** `ScreenManagerCubit` is now owned internally by `BaseBloc`. The `screen` parameter has been removed from all constructors — just call `super()`. Mixin initialization is also automatic; no `initInfiniteList()`, `initSearch()`, or similar calls are needed.

### 5. Drive the BLoC

```dart
final bloc = TodosBloc(repo: myRepo);

// Pagination
bloc.add(BlocxCollectionEventLoadNextPage<Todo>());

// Search
bloc.add(BlocxCollectionEventSearch<Todo>(searchText: 'urgent'));
bloc.add(BlocxCollectionEventClearSearch<Todo>());

// Selection
bloc.add(BlocxCollectionEventSelectItem<Todo>(item: someTodo));
bloc.add(BlocxCollectionEventClearSelection<Todo>());

// Refresh
bloc.add(BlocxCollectionEventRefreshData<Todo>());
```

---

## Quickstart: Form with Validation

### 1. Define the Field Enum and Form Entity

```dart
import 'package:blocx_core/form_bloc.dart';

enum SignUpField { email, password, confirmPassword }

class SignUpForm extends BlocxBaseFormEntity<SignUpForm, SignUpField> {
  final String email;
  final String password;
  final String confirmPassword;

  const SignUpForm({
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
  });

  @override
  SignUpForm updateByKey(SignUpField key, dynamic value) => switch (key) {
    SignUpField.email           => copyWith(email: value),
    SignUpField.password        => copyWith(password: value),
    SignUpField.confirmPassword => copyWith(confirmPassword: value),
  };

  @override
  dynamic getValueByKey(SignUpField key) => switch (key) {
    SignUpField.email           => email,
    SignUpField.password        => password,
    SignUpField.confirmPassword => confirmPassword,
  };

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

> **Tip — `freezed` integration:** The `copyWith`, `==`, and `hashCode` methods above can be generated automatically by [`freezed`](https://pub.dev/packages/freezed). Annotate your form class with `@freezed` and implement only `updateByKey` and `getValueByKey` manually to eliminate the rest of the boilerplate.

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
  SignUpBloc() : super(const SignUpForm(), SignUpValidator());

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

## Migrating from 0.7.x

### Breaking: list bloc rename

`BlocxListBloc` has been renamed to `BlocxCollectionBloc`. Update your class declarations:

```dart
// Before
class TodosBloc extends BlocxListBloc<Todo, void> { ... }

// After
class TodosBloc extends BlocxCollectionBloc<Todo, void> { ... }
```

### Breaking: mixin renames

All collection mixin names have had the redundant `_bloc` segment removed for a cleaner, consistent naming scheme. Update your `with` clauses and any direct imports:

| Before (0.7.x) | After (0.8.0) |
|---|---|
| `BlocxInfiniteListBlocMixin` | `BlocxCollectionInfiniteMixin` |
| `BlocxSelectableListBlocMixin` | `BlocxCollectionSelectableMixin` |
| `BlocxRefreshableListBlocMixin` | `BlocxCollectionRefreshableMixin` |
| `BlocxSearchableListBlocMixin` | `BlocxCollectionSearchableMixin` |
| `BlocxDeletableListBlocMixin` | `BlocxCollectionDeletableMixin` |
| `BlocxExpandableListBlocMixin` | `BlocxCollectionExpandableMixin` |
| `BlocxHighlightableListBlocMixin` | `BlocxCollectionHighlightableMixin` |
| `BlocxScrollableListBlocMixin` | `BlocxCollectionScrollableMixin` |
| `BlocxListBlocSyncStreamMixin` | `BlocxCollectionSyncStreamMixin` |

Form mixins follow the same `blocx_form_*` prefix pattern:

| Before (0.7.x) | After (0.8.0) |
|---|---|
| `BlocxInfoFetcherFormMixin` | `BlocxFormInfoFetcherMixin` |
| `BlocxSteppedFormMixin` | `BlocxFormSteppedMixin` |

### Breaking: event and state renames

All list events and states have been renamed from `BlocxList*` to `BlocxCollection*`:

| Before (0.7.x) | After (0.8.0) |
|---|---|
| `BlocxListEventLoadInitialPage` | `BlocxCollectionEventLoadInitialPage` |
| `BlocxListEventLoadNextPage` | `BlocxCollectionEventLoadNextPage` |
| `BlocxListEventSearch` | `BlocxCollectionEventSearch` |
| `BlocxListEventRefreshData` | `BlocxCollectionEventRefreshData` |
| `BlocxListStateLoading` | `BlocxCollectionStateLoading` |
| `BlocxListStateLoaded` | `BlocxCollectionStateLoaded` |
| `BlocxListStateError` | `BlocxCollectionStateError` |
| *(and all remaining `BlocxList*` events/states)* | *(same pattern: replace `List` with `Collection`)* |

### Breaking: automatic mixin initialization

Manual `init*()` calls in bloc constructors are no longer needed. `BlocxCollectionBloc` detects which mixins are applied and initializes them automatically. Remove all `initInfiniteList()`, `initSearchable()`, `initRefresh()`, `initSelectable()`, and similar calls from your constructors.

### Breaking: constructor signature

The constructor no longer accepts `BlocxInfiniteListBloc` as a parameter. Remove it from your `super(...)` call:

```dart
// Before
TodosBloc({required this.repo}) : super(BlocxInfiniteListBloc()) { ... }

// After
TodosBloc({required this.repo}) : super() { ... }
```

### Breaking: use case API

`BlocxBaseUseCase` now takes two type parameters (`Input` and `Output`) and a `perform(Input)` method instead of a zero-argument `perform()`. Replace old use case patterns:

```dart
// Before
class FetchTodosUseCase extends BlocxPaginatedUseCase<Todo> {
  FetchTodosUseCase({required super.loadCount, required super.offset, ...});

  @override
  Future<UseCaseResult<Page<Todo>>> perform() async { ... }
}

// After
class FetchTodosUseCase extends BlocxPaginatedUseCase<BlocxPaginationInput, Todo> {
  @override
  Future<BlocxUseCaseResult<BlocxPage<Todo>>> perform(BlocxPaginationInput input) async {
    final items = await repo.fetchPage(limit: input.limit, offset: input.offset);
    return successResult(items: items, input: input);
  }
}
```

### Breaking: model renames

`BaseFormEntity` is now `BlocxBaseFormEntity`. Update all subclasses and type references.

`Page<T>` is now `BlocxPage<T>` and `UseCaseResult<T>` is now `BlocxUseCaseResult<T>`.

### Breaking: ScreenManagerCubit ownership

`ScreenManagerCubit` is now owned internally by `BaseBloc`. Remove the `screen` parameter from your bloc constructors and call sites:

```dart
// Before
MyBloc({required ScreenManagerCubit screen}) : super(screen, MyStateInitial());

// After
MyBloc() : super(MyStateInitial());
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
