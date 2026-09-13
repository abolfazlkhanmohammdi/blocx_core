<p align="center">
  <img src="https://raw.githubusercontent.com/abolfazlkhanmohammdi/blocx_core/main/assets/pub/logo.png" width="200" alt="blocx_core logo" />
</p>

<h1 align="center">blocx_core</h1>

<p align="center">
  Production-ready, pure Dart BLoC architecture for paginated collections, dynamic forms, validation, event broadcasting, and UI side-effects.
</p>

<p align="center">
  Pure Dart • Composable Mixins • Use-Case Driven • flutter_bloc Compatible
</p>

---

# Why BlocX?

State management in real-world apps rarely breaks because business logic is complex. It breaks because every feature repeatedly rebuilds the same boilerplate infrastructure:

- Loading initial pages and appending infinite pages
- Tracking reached-end state and scroll intents
- Pull-to-refresh and debounced search with page retention
- Collection item filtering, multi-selection, row expansion, and item highlighting
- Local and remote single/bulk item deletion
- Reactive list synchronization from streams
- Immutable form entities with per-field updates and full replacements
- Form validation modes (`none`, `onSubmit`, `onUserInteraction`, `always`)
- Async uniqueness checks and prefetching dropdown/reference data
- Timed and persistent field errors
- System-wide BLoC event broadcasting
- Surfacing errors and UI side-effects (snackbars, error pages, pop intents)

`blocx_core` extracts these recurring requirements into composable Dart mixins and tasks.

You write clean domain use cases and repositories. BlocX handles the state orchestration around them.

Instead of writing hundreds of lines of state-management code for every screen, you declare what capabilities your feature needs:

```dart
class ProductsBloc extends BlocxCollectionBloc<Product, void>
    with
        BlocxCollectionInfiniteMixin<Product, void>,
        BlocxCollectionSearchableMixin<Product, void>,
        BlocxCollectionFilterMixin<Product, void, ProductFilter>,
        BlocxCollectionRefreshableMixin<Product, void>,
        BlocxCollectionSelectableMixin<Product, void>,
        BlocxCollectionDeletableMixin<Product, void> {
  ProductsBloc() : super();
}
```

For forms:

```dart
class SignUpBloc extends BlocxFormBloc<SignUpForm, void, SignUpField>
    with
        BlocxFormValidationMixin<SignUpForm, void, SignUpField>,
        BlocxFormPrefetchMixin<SignUpForm, void, SignUpField>,
        BlocxUniqueFieldValidatorMixin<SignUpForm, void, SignUpField> {
  SignUpBloc() : super(const SignUpForm());
}
```

### Key Architectural Benefits

- **Pure Dart**: Zero dependency on Flutter. Runs on VM, Web, Server, or CLI.
- **Composable**: Opt into only the features you need using mixins.
- **Use-Case Driven**: Business logic stays inside `BlocxBaseUseCase` and `BlocxUseCaseTask`.
- **UI-Agnostic Side Effects**: `ScreenManagerCubit` emits typed intents (snackbars, navigation, error pages) that any UI layer can render.
- **`flutter_bloc` Native**: Integrates seamlessly with standard BLoC packages and ready-made widgets from [`flutter_blocx`](https://pub.dev/packages/flutter_blocx).

---

# Before vs After

### Traditional BLoC

```dart
class TodosBloc extends Bloc<TodosEvent, TodosState> {
  // Manual page offset tracking
  // Manual limit & end-of-list detection
  // Search debouncing logic
  // Refresh & initial load state merging
  // Selection set management
  // Delete loading state & item filtering
  // Error handling & exception catching boilerplate
  // Repetitive event handler registrations
}
```

### BlocX

```dart
class TodosBloc extends BlocxCollectionBloc<Todo, void>
    with
        BlocxCollectionInfiniteMixin<Todo, void>,
        BlocxCollectionSearchableMixin<Todo, void>,
        BlocxCollectionRefreshableMixin<Todo, void>,
        BlocxCollectionSelectableMixin<Todo, void> {
  TodosBloc() : super();

  @override
  BlocxPaginatedUseCaseTask<BlocxPaginatedInput, Todo>? get paginationTask {
    return BlocxPaginatedUseCaseTask<BlocxPaginatedInput, Todo>(
      useCase: fetchTodosUseCase,
      inputBuilder: (offset, limit) => BlocxPaginatedInput(offset: offset, limit: limit),
    );
  }
}
```

Mixins provide all the orchestration. Your code remains purely domain-focused.

---

# What You Get

## 📦 Collections & Lists (`collection_bloc.dart`)

- **Initial Load & Pagination**: Cursor/offset-based page fetching with `BlocxPage<T>`.
- **Infinite Scrolling**: Automated next-page loading via `BlocxInfiniteListBloc`.
- **Debounced Search**: Debounced query execution, search pagination, and search refresh.
- **Filtering**: Apply dynamic filters with automatic initial-page reloads.
- **Pull-to-Refresh**: Refresh lists while managing pagination offset reset.
- **Selection & Multi-Select**: Single/multi-selection with optional remote server sync.
- **Highlighting & Expansion**: Temporarily highlight items and toggle expandable row states.
- **Scroll Intents**: Programmatically request scrolling to an item or identifier in the UI.
- **Single & Bulk Deletion**: Animated item removal with rollback support on remote failure.
- **Reactive Streams**: Sync collection state dynamically from external streams.

## 📝 Forms (`form_bloc.dart`)

- **Immutable Entities**: Strongly typed fields mapped to enum keys with `BlocxBaseFormEntity`.
- **Validation Modes**: `none`, `onSubmit`, `onUserInteraction`, and `always`.
- **40+ Built-in Validators**: Comprehensive validators for String, DateTime, Double, Integer, List, File, Phone, and Object types.
- **Data Prefetching**: Load auxiliary reference data (e.g. dropdown options) before rendering.
- **Async Uniqueness Checks**: Debounced server-side unique field validation.
- **Timed & Persistent Errors**: Programmatically attach temporary or persistent field errors.
- **Multi-Step Wizards**: Step-by-step navigation with forward/backward validation checks.

## 🛠️ Architecture & Infrastructure (`blocx_core.dart`)

- **Typed Use Case Tasks**: `BlocxUseCaseTask<Input, Output>` and `BlocxPaginatedUseCaseTask<Input, Output>`.
- **Result Containers**: `BlocxUseCaseResult<T>` and normalized `BlocxPage<T>`.
- **Global Error Translation**: Map exceptions to human-readable `ReadableError` instances.
- **Screen Manager**: Emit snackbars, error pages, and pop intents directly from BLoCs.
- **Event Bus (`BlocxEventHubMixin`)**: Decoupled cross-BLoC communication with `BlocxAppEvent`.

---

# Table of Contents

- [Installation](#installation)
- [Architecture Overview](#architecture-overview)
- [Core Concepts](#core-concepts)
  - [BlocxBaseEntity](#blocxbaseentity)
  - [UseCase & UseCaseResult](#usecase--usecaseresult)
  - [Use Case Tasks](#use-case-tasks)
  - [BlocxPage](#blocxpage)
  - [ScreenManagerCubit & Errors](#screenmanagercubit--errors)
  - [Cross-BLoC Event Bus](#cross-bloc-event-bus)
- [Collection BLoC](#collection-bloc)
  - [BlocxCollectionBloc](#blocxcollectionbloc)
  - [Collection Mixins](#collection-mixins)
  - [Collection Tasks](#collection-tasks)
  - [Collection Events & States](#collection-events--states)
- [Form BLoC](#form-bloc)
  - [BlocxBaseFormEntity](#blocxbaseformentity)
  - [BlocxFormBloc](#blocxformbloc)
  - [Form Validation Modes](#form-validation-modes)
  - [Built-in Validators](#built-in-validators)
  - [Form Mixins](#form-mixins)
  - [Form Events & States](#form-events--states)
- [Quickstarts](#quickstarts)
  - [Paged, Searchable & Selectable List](#quickstart-paged-searchable--selectable-list)
  - [Form with Validation & Prefetching](#quickstart-form-with-validation--prefetching)
- [Migrating to 0.9.0](#migrating-to-090)
- [License](#license)

---

## Installation

Add `blocx_core` to your `pubspec.yaml`:

```yaml
dependencies:
  blocx_core: ^0.9.0
```

Or run:

```sh
dart pub add blocx_core
```

### Barrel Imports

```dart
// Base types, use cases, results, screen manager, errors, event hub.
import 'package:blocx_core/blocx_core.dart';

// Collection bloc, events, states, mixins, page, paginated use cases.
import 'package:blocx_core/collection_bloc.dart';

// Form bloc, events, states, mixins, validators, form entity.
import 'package:blocx_core/form_bloc.dart';
```

**SDK Requirement:** Dart `>=3.5.0`

---

## Architecture Overview

```txt
┌─────────────────────────────────────────────────────┐
│                  Your Domain BLoC                    │
│  BlocxCollectionBloc / BlocxFormBloc + mixins        │
└───────────────────────┬─────────────────────────────┘
                        │ executes via tasks
┌───────────────────────▼─────────────────────────────┐
│                    Use Cases                         │
│  BlocxBaseUseCase<Input, Output>                     │
│  BlocxPaginatedUseCase<Input, Entity>                │
│  BlocxSearchUseCase<Input, Entity>                   │
└───────────────────────┬─────────────────────────────┘
                        │ returns
┌───────────────────────▼─────────────────────────────┐
│                    Results                           │
│  BlocxUseCaseResult<T>                               │
│  BlocxPage<T>                                        │
└───────────────────────┬─────────────────────────────┘
                        │ emits UI intents through
┌───────────────────────▼─────────────────────────────┐
│                ScreenManagerCubit                    │
│  snackbars / error pages / navigation intents       │
└─────────────────────────────────────────────────────┘
```

---

## Core Concepts

### BlocxBaseEntity

Collection domain models must extend `BlocxBaseEntity` to supply a stable `identifier`:

```dart
class Product extends BlocxBaseEntity {
  final String id;
  final String title;
  final double price;

  const Product({
    required this.id,
    required this.title,
    required this.price,
  });

  @override
  String get identifier => id;
}
```

The `identifier` is used for selection, highlighting, expansion, deletion, and scrolling.

---

### UseCase & UseCaseResult

Represent business operations with `BlocxBaseUseCase<Input, Output>`:

```dart
class FetchProductUseCase extends BlocxBaseUseCase<String, Product> {
  final ProductRepository repo;

  FetchProductUseCase(this.repo);

  @override
  Future<BlocxUseCaseResult<Product>> perform(String id) async {
    final product = await repo.getById(id);
    return success(product);
  }
}
```

Calling `execute(input)` automatically catches unhandled errors and converts them to `BlocxUseCaseFailure`.

---

### Use Case Tasks

Tasks bundle a use case with a lazy input builder so inputs read the latest state at execution time.

#### Standard Task

```dart
BlocxUseCaseTask<CreateUserInput, User>(
  useCase: createUserUseCase,
  inputBuilder: () => CreateUserInput(
    name: formData.name,
    email: formData.email,
  ),
);
```

#### Paginated Task

```dart
BlocxPaginatedUseCaseTask<GetOrdersInput, Order>(
  useCase: getOrdersUseCase,
  inputBuilder: (offset, limit) => GetOrdersInput(
    offset: offset,
    limit: limit,
    status: currentStatus,
  ),
);
```

---

### BlocxPage

Normalized pagination response model:

```dart
class BlocxPage<T> {
  final List<T> items;
  final int offset;
  final int limit;

  bool get hasNext => limit == items.length;
}
```

`hasNext` evaluates to `true` when the returned item count equals `limit`.

---

### ScreenManagerCubit & Errors

`BaseBloc` manages an internal `ScreenManagerCubit` to surface UI side-effects cleanly:

```dart
// Emit a snackbar
displaySnackBar('Changes saved.', BlocXSnackbarType.success);

// Show full page error
displayErrorWidget(
  error: ReadableError(title: 'Error', message: 'Failed to load details.'),
);

// Request UI back navigation
pop();
```

Register a global error translator at app initialization:

```dart
BlocxErrorTranslator.instance = AppErrorTranslator();
```

---

### Cross-BLoC Event Bus

Communicate across BLoCs without tight coupling using `BlocxEventHubMixin` and `BlocxAppEvent`:

```dart
class UserUpdatedEvent extends BlocxAppEvent {
  final User user;
  UserUpdatedEvent(this.user);
}

class OrdersBloc extends BlocxCollectionBloc<Order, void>
    with BlocxEventHubMixin {
  final BlocxEventHub eventHub;

  OrdersBloc(this.eventHub) {
    systemEventsOfType<UserUpdatedEvent>().listen((event) {
      add(BlocxCollectionEventRefreshData());
    });
  }
}
```

---

## Collection BLoC

### BlocxCollectionBloc

`BlocxCollectionBloc<T, P>` is the base class for manageing lists:

- `T`: Entity type extending `BlocxBaseEntity`.
- `P`: Payload type passed on initial load (`void` if not needed).

```dart
class OrdersBloc extends BlocxCollectionBloc<Order, void>
    with
        BlocxCollectionInfiniteMixin<Order, void>,
        BlocxCollectionRefreshableMixin<Order, void> {
  OrdersBloc() : super();

  @override
  BlocxPaginatedUseCaseTask<GetOrdersInput, Order>? get paginationTask {
    return BlocxPaginatedUseCaseTask<GetOrdersInput, Order>(
      useCase: getOrdersUseCase,
      inputBuilder: (offset, limit) => GetOrdersInput(offset: offset, limit: limit),
    );
  }
}
```

---

### Collection Mixins

| Mixin | Functionality |
|---|---|
| `BlocxCollectionInfiniteMixin<T, P>` | Infinite scrolling and next-page loading |
| `BlocxCollectionSearchableMixin<T, P>` | Debounced search with search-result pagination |
| `BlocxCollectionFilterMixin<T, P, F>` | Apply active filter objects to collection requests |
| `BlocxCollectionRefreshableMixin<T, P>` | Pull-to-refresh list resetting |
| `BlocxCollectionSelectableMixin<T, P>` | Single & multi-item selection with optional remote sync |
| `BlocxCollectionHighlightableMixin<T, P>` | Highlight and unhighlight rows |
| `BlocxCollectionExpandableMixin<T, P>` | Expand and collapse items |
| `BlocxCollectionScrollableMixin<T, P>` | Programmatic scroll-to-item intents |
| `BlocxCollectionDeletableMixin<T, P>` | Single and bulk item deletion |
| `BlocxCollectionSyncStreamMixin<T, P>` | Real-time state synchronization from a Dart stream |

---

### Collection Tasks

```dart
// Shared Pagination Task
@override
BlocxPaginatedUseCaseTask<GetProductsInput, Product>? get paginationTask {
  return BlocxPaginatedUseCaseTask<GetProductsInput, Product>(
    useCase: getProductsUseCase,
    inputBuilder: (offset, limit) => GetProductsInput(offset: offset, limit: limit),
  );
}

// Search Task
@override
BlocxPaginatedUseCaseTask<BlocxSearchInput, Product>? get searchUseCaseTask {
  return BlocxPaginatedUseCaseTask<BlocxSearchInput, Product>(
    useCase: searchProductsUseCase,
    inputBuilder: (offset, limit) => BlocxSearchInput(
      searchText: searchText,
      offset: offset,
      limit: limit,
    ),
  );
}

// Single Delete Task Factory
@override
BlocxUseCaseTask<DeleteProductInput, bool>? deleteItemTask(Product item) {
  return BlocxUseCaseTask<DeleteProductInput, bool>(
    useCase: deleteProductUseCase,
    inputBuilder: () => DeleteProductInput(id: item.id),
  );
}
```

---

### Collection Events & States

#### Events
- `BlocxCollectionEventLoadInitialPage<T, P>`
- `BlocxCollectionEventLoadNextPage<T>`
- `BlocxCollectionEventRefreshData<T>`
- `BlocxCollectionEventSearch<T>`
- `BlocxCollectionEventFilter<T, F>`
- `BlocxCollectionEventSelectItem<T>`
- `BlocxCollectionEventDeselectItem<T>`
- `BlocxCollectionEventRemoveItem<T>`
- `BlocxCollectionEventScrollToItem<T>`

#### States
- `BlocxCollectionStateLoading<T>`
- `BlocxCollectionStateLoaded<T>`
- `BlocxCollectionStateError<T>`
- `BlocxCollectionStateSelectionChanged<T>`

---

## Form BLoC

### BlocxBaseFormEntity

Form models must extend `BlocxBaseFormEntity<F, E>` where `F` is the entity and `E` is an enum of field keys:

```dart
enum ProfileField { name, email, phone }

class ProfileForm extends BlocxBaseFormEntity<ProfileForm, ProfileField> {
  final String name;
  final String email;
  final String phone;

  const ProfileForm({this.name = '', this.email = '', this.phone = ''});

  @override
  ProfileForm updateByKey(ProfileField key, dynamic value) {
    return switch (key) {
      ProfileField.name => copyWith(name: value as String),
      ProfileField.email => copyWith(email: value as String),
      ProfileField.phone => copyWith(phone: value as String),
    };
  }

  @override
  dynamic getValueByKey(ProfileField key) {
    return switch (key) {
      ProfileField.name => name,
      ProfileField.email => email,
      ProfileField.phone => phone,
    };
  }

  ProfileForm copyWith({String? name, String? email, String? phone}) {
    return ProfileForm(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }

  @override
  String get identifier => 'profile_form';
}
```

---

### BlocxFormBloc

`BlocxFormBloc<F, P, E>` manages form lifecycle, field updates, validation, and submission:

```dart
class ProfileFormBloc extends BlocxFormBloc<ProfileForm, void, ProfileField>
    with BlocxFormValidationMixin<ProfileForm, void, ProfileField> {
  ProfileFormBloc() : super(const ProfileForm());

  @override
  BlocxFormValidator<ProfileForm, ProfileField> get validator => ProfileFormValidator();

  @override
  List<ProfileField> get formKeysList => ProfileField.values;

  @override
  FormValidationMode get formValidationMode => FormValidationMode.onSubmit;

  @override
  BlocxUseCaseTask<UpdateProfileInput, UserProfile> get submitUseCaseTask {
    return BlocxUseCaseTask<UpdateProfileInput, UserProfile>(
      useCase: updateProfileUseCase,
      inputBuilder: () => UpdateProfileInput(
        name: formData.name,
        email: formData.email,
        phone: formData.phone,
      ),
    );
  }
}
```

---

### Form Validation Modes

| Mode | Behavior |
|---|---|
| `FormValidationMode.none` | Disables validation |
| `FormValidationMode.onSubmit` | Validates the full form only on submit |
| `FormValidationMode.onUserInteraction` | Validates changed fields while editing; validates full form on submit |
| `FormValidationMode.always` | Validates full form on every field change and submit |

---

### Built-in Validators

All exported from `package:blocx_core/form_bloc.dart`:

- **String**: `BlocxStringRequiredValidator`, `BlocxStringMinLengthValidator`, `BlocxStringMaxLengthValidator`, `BlocxStringLengthRangeValidator`, `BlocxStringExactLengthValidator`, `BlocxStringEmailValidator`, `BlocxStringNumericValidator`, `BlocxStringAlphanumericValidator`, `BlocxStringUrlValidator`, `BlocxStringMatchValidator`
- **DateTime**: `BlocxDateTimeRequiredValidator`, `BlocxDateTimeMinValidator`, `BlocxDateTimeMaxValidator`, `BlocxDateTimeRangeValidator`, `BlocxDateTimeAfterFieldValidator`, `BlocxDateTimeBeforeFieldValidator`
- **Double**: `BlocxDoubleRequiredValidator`, `BlocxDoubleMinValueValidator`, `BlocxDoubleMaxValueValidator`, `BlocxDoublePositiveValidator`, `BlocxDoubleRangeValidator`
- **Integer**: `BlocxIntegerRequiredValidator`, `BlocxIntegerMinValueValidator`, `BlocxIntegerMaxValueValidator`, `BlocxIntegerPositiveValidator`, `BlocxIntegerNonZeroValidator`, `BlocxIntegerRangeValidator`, `BlocxIntegerGreaterThanFieldValidator`, `BlocxIntegerLessThanFieldValidator`
- **List**: `BlocxListRequiredValidator`, `BlocxListMinItemsValidator`, `BlocxListMaxItemsValidator`, `BlocxListUniqueItemsValidator`
- **File**: `BlocxFileRequiredValidator`, `BlocxFileMaxSizeValidator`
- **Phone**: `BlocxPhoneRequiredValidator`, `BlocxPhoneBasicFormatValidator`, `BlocxPhoneE164Validator`, `BlocxPhoneMinLengthValidator`, `BlocxPhoneMaxLengthValidator`
- **Object**: `BlocxRequiredFieldValidator`

---

### Form Mixins

| Mixin | Capability |
|---|---|
| `BlocxFormValidationMixin<F, P, E>` | Form field & full-form validation |
| `BlocxFormPrefetchMixin<F, P, E>` | Prefetch auxiliary reference data before form load |
| `BlocxUniqueFieldValidatorMixin<F, P, E>` | Async uniqueness validation per field |
| `BlocxFormErrorsMixin<F, P, E>` | Persistent and timed field error messages |
| `BlocxFormSteppedMixin<F, P, E>` | Multi-step wizard navigation |

#### Prefetch Example

```dart
@override
Map<ProfileField, BlocxUseCaseTask<Object?, Object?>> get requiredInitialInfoTasks => {
  ProfileField.phone: BlocxUseCaseTask<Object?, Object?>(
    useCase: getCountriesUseCase,
    inputBuilder: () => null,
  ),
};
```

---

### Form Events & States

#### Events
- `BlocxFormEventInit<P>`
- `BlocxFormEventPrefetchRequiredInfo`
- `BlocxFormEventUpdateData<E>`
- `BlocxFormEventUpdateFormData<P>`
- `BlocxFormEventSubmit`
- `BlocxFormEventSetTimedErrorToField<E>`

#### States
- `BlocxFormStateInitial<F, E>`
- `BlocxFormStateLoaded<F, E>`
- `BlocxFormStateSubmittingForm<F, E>`
- `BlocxFormStateFormSubmitted<F, E>`

---

## Quickstarts

### Quickstart: Paged, Searchable & Selectable List

```dart
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/collection_bloc.dart';

class Todo extends BlocxBaseEntity {
  final String id;
  final String title;

  const Todo({required this.id, required this.title});

  @override
  String get identifier => id;
}

class FetchTodosUseCase extends BlocxPaginatedUseCase<BlocxPaginatedInput, Todo> {
  final TodoRepository repo;
  FetchTodosUseCase(this.repo);

  @override
  Future<BlocxUseCaseResult<BlocxPage<Todo>>> perform(BlocxPaginatedInput input) async {
    final items = await repo.fetchPage(limit: input.limit, offset: input.offset);
    return successResult(items: items, input: input);
  }
}

class TodosBloc extends BlocxCollectionBloc<Todo, void>
    with
        BlocxCollectionInfiniteMixin<Todo, void>,
        BlocxCollectionSearchableMixin<Todo, void>,
        BlocxCollectionSelectableMixin<Todo, void> {
  final FetchTodosUseCase fetchTodosUseCase;

  TodosBloc(this.fetchTodosUseCase) : super();

  @override
  BlocxPaginatedUseCaseTask<BlocxPaginatedInput, Todo>? get paginationTask {
    return BlocxPaginatedUseCaseTask<BlocxPaginatedInput, Todo>(
      useCase: fetchTodosUseCase,
      inputBuilder: (offset, limit) => BlocxPaginatedInput(offset: offset, limit: limit),
    );
  }
}
```

---

### Quickstart: Form with Validation & Prefetching

```dart
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/form_bloc.dart';

enum SignUpField { email, password }

class SignUpForm extends BlocxBaseFormEntity<SignUpForm, SignUpField> {
  final String email;
  final String password;

  const SignUpForm({this.email = '', this.password = ''});

  @override
  SignUpForm updateByKey(SignUpField key, dynamic value) {
    return switch (key) {
      SignUpField.email => SignUpForm(email: value as String, password: password),
      SignUpField.password => SignUpForm(email: email, password: value as String),
    };
  }

  @override
  dynamic getValueByKey(SignUpField key) => key == SignUpField.email ? email : password;

  @override
  String get identifier => 'sign_up_form';
}

class SignUpValidator extends BlocxFormValidator<SignUpForm, SignUpField> {
  @override
  List<SignUpField> formKeys() => SignUpField.values;

  @override
  List<BlocxFieldValidator<SignUpForm, SignUpField, dynamic>> getValidatorsByKey(
    SignUpForm formData,
    SignUpField key,
  ) {
    return switch (key) {
      SignUpField.email => [
          BlocxStringRequiredValidator<SignUpForm, SignUpField>(),
          BlocxStringEmailValidator<SignUpForm, SignUpField>(),
        ],
      SignUpField.password => [
          BlocxStringRequiredValidator<SignUpForm, SignUpField>(),
          BlocxStringMinLengthValidator<SignUpForm, SignUpField>(minLength: 8),
        ],
    };
  }
}

class SignUpBloc extends BlocxFormBloc<SignUpForm, void, SignUpField>
    with BlocxFormValidationMixin<SignUpForm, void, SignUpField> {
  final CreateAccountUseCase createAccountUseCase;

  SignUpBloc(this.createAccountUseCase) : super(const SignUpForm());

  @override
  BlocxFormValidator<SignUpForm, SignUpField> get validator => SignUpValidator();

  @override
  List<SignUpField> get formKeysList => SignUpField.values;

  @override
  FormValidationMode get formValidationMode => FormValidationMode.onSubmit;

  @override
  BlocxUseCaseTask<CreateAccountInput, Account> get submitUseCaseTask {
    return BlocxUseCaseTask<CreateAccountInput, Account>(
      useCase: createAccountUseCase,
      inputBuilder: () => CreateAccountInput(email: formData.email, password: formData.password),
    );
  }
}
```

---

## Migrating to 0.9.0

### Update Barrel Imports

Replace imports of `list_bloc.dart` with `collection_bloc.dart`:

```dart
// Before
import 'package:blocx_core/list_bloc.dart';

// After
import 'package:blocx_core/collection_bloc.dart';
```

### Update Form Prefetch Mixin Name

`BlocxFormInfoFetcherMixin` has been renamed to `BlocxFormPrefetchMixin`:

```dart
// Before
class ProfileFormBloc extends BlocxFormBloc<ProfileForm, void, ProfileField>
    with BlocxFormInfoFetcherMixin<ProfileForm, void, ProfileField> { ... }

// After
class ProfileFormBloc extends BlocxFormBloc<ProfileForm, void, ProfileField>
    with BlocxFormPrefetchMixin<ProfileForm, void, ProfileField> { ... }
```

### Update Typed UseCase Tasks

`BlocxUseCaseTask` and `BlocxPaginatedUseCaseTask` use input/output type parameters:

```dart
// Before
BlocxUseCaseTask<CreateUserUseCase, CreateUserInput>(
  useCase: createUserUseCase,
  inputBuilder: () => CreateUserInput(...),
);

// After
BlocxUseCaseTask<CreateUserInput, User>(
  useCase: createUserUseCase,
  inputBuilder: () => CreateUserInput(...),
);
```

---

## License

`blocx_core` is released under the MIT License.
