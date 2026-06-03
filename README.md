<p align="center">
  <img src="https://raw.githubusercontent.com/abolfazlkhanmohammdi/blocx_core/main/assets/pub/logo.png" width="200" alt="blocx_core logo" />
</p>

<h1 align="center">blocx_core</h1>

<p align="center">
  Build production-ready Dart BLoCs for lists, forms, pagination, search, refresh, validation, selection, and screen side effects.
</p>

<p align="center">
  Pure Dart • Composable Mixins • Use-case Driven • flutter_bloc Compatible
</p>

---

# Why BlocX?

Most apps do not become hard to maintain because their business logic is complex. They become hard to maintain because every feature quietly rebuilds the same state-management infrastructure:

- loading the first page
- loading the next page
- detecting the end of pagination
- refreshing data
- searching with debounce
- preserving search pagination
- selecting and deselecting items
- deleting items with loading state
- highlighting and expanding rows
- syncing lists from streams
- validating form fields
- validating the full form on submit
- checking async uniqueness
- managing timed field errors
- surfacing failures as snackbars, pages, or navigation intents

`blocx_core` extracts those repeated patterns into composable Dart building blocks.

You still write your domain use cases. You still define your entities, inputs, repositories, and validators. BlocX handles the recurring BLoC infrastructure around them.

Instead of building a large custom BLoC for every list or form, you describe what the feature needs:

```dart
class UsersBloc extends BlocxCollectionBloc<User, void>
    with
        BlocxCollectionInfiniteMixin<User, void>,
        BlocxCollectionSearchableMixin<User, void>,
        BlocxCollectionRefreshableMixin<User, void>,
        BlocxCollectionSelectableMixin<User, void> {
  UsersBloc() : super();
}
```

For forms:

```dart
class SignUpBloc extends BlocxFormBloc<SignUpForm, void, SignUpField>
    with BlocxFormValidationMixin<SignUpForm, void, SignUpField> {
  SignUpBloc() : super(const SignUpForm());
}
```

The result is a consistent architecture where:

- use cases perform async business operations
- BLoCs own state and event orchestration
- mixins add focused capabilities
- screen side effects stay typed and UI-agnostic
- Flutter remains optional

`blocx_core` is pure Dart. Pair it with [`flutter_blocx`](https://pub.dev/packages/flutter_blocx) when you want ready-made Flutter widgets and screen host classes on top of this core package.

---

# Before vs After

### Traditional BLoC

```dart
class TodosBloc extends Bloc<TodosEvent, TodosState> {
  // pagination flags
  // loading flags
  // refresh handling
  // search debounce
  // selected item ids
  // delete loading ids
  // error routing
  // repetitive event handlers
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
      inputBuilder: (offset, limit) {
        return BlocxPaginatedInput(offset: offset, limit: limit);
      },
    );
  }
}
```

The behavior is provided by the mixins. Your code stays focused on the domain.

---

# What You Get

## Lists and Collections

- Initial page loading
- Infinite scrolling
- Debounced search
- Search pagination
- Search refresh
- Pull-to-refresh
- Selection and multi-selection
- Optional remote selection sync
- Highlighting
- Expansion
- Scroll-to-item intents
- Single and bulk deletion
- Stream synchronization
- Typed paginated use case tasks

## Forms

- Immutable form entities
- Field update events
- Full form replacement
- Submit workflows
- Submit-time validation
- Validation modes
- Field-level errors
- Timed field errors
- Async uniqueness checks
- Required info fetching
- Multi-step forms
- Typed submit use case tasks

## Architecture

- Pure Dart
- No Flutter dependency
- `bloc` / `flutter_bloc` compatible
- Use-case driven
- Typed results
- Typed error handling
- Composable feature mixins
- UI side effects through `ScreenManagerCubit`

---

# Is BlocX Right For Me?

Use BlocX if:

- you already use the BLoC pattern
- you have many list, grid, CRUD, or admin-style screens
- you repeatedly implement pagination, search, refresh, and selection
- your forms need validation, submit guards, and async checks
- you want use cases and UI side effects separated
- you want consistency across features and projects

You may not need BlocX if:

- your app has only a few simple screens
- your state is mostly local widget state
- you prefer a minimal state-management layer
- you do not want mixin-based composition

---

# Architecture Philosophy

BlocX is intentionally composable.

A collection bloc does not automatically search, refresh, select, delete, expand, highlight, or scroll. You opt into only the capabilities your feature needs:

```dart
class ProductsBloc extends BlocxCollectionBloc<Product, void>
    with
        BlocxCollectionInfiniteMixin<Product, void>,
        BlocxCollectionRefreshableMixin<Product, void> {
  ProductsBloc() : super();
}
```

A form bloc does not automatically validate, fetch required info, check unique fields, or become stepped. You compose those features explicitly:

```dart
class ProfileFormBloc extends BlocxFormBloc<ProfileForm, ProfilePayload, ProfileField>
    with
        BlocxFormValidationMixin<ProfileForm, ProfilePayload, ProfileField>,
        BlocxFormInfoFetcherMixin<ProfileForm, ProfilePayload, ProfileField> {
  ProfileFormBloc() : super(const ProfileForm());
}
```

The package gives you infrastructure. You keep control over the feature.

---

## Table of Contents

- [Installation](#installation)
- [Architecture Overview](#architecture-overview)
- [Core Concepts](#core-concepts)
  - [BlocxBaseEntity](#blocxbaseentity)
  - [UseCase & UseCaseResult](#usecase--usecaseresult)
  - [Use Case Tasks](#use-case-tasks)
  - [BlocxPage](#blocxpaget)
  - [ScreenManagerCubit](#screenmanagercubit)
- [Collection BLoC](#collection-bloc)
  - [BlocxCollectionBloc](#blocxcollectionbloc)
  - [Collection Mixins](#collection-mixins)
  - [Collection Tasks](#collection-tasks)
  - [Collection Events](#collection-events)
  - [Collection States](#collection-states)
- [Form BLoC](#form-bloc)
  - [BlocxBaseFormEntity](#blocxbaseformentity)
  - [BlocxFormBloc](#blocxformbloc)
  - [Form Validation](#form-validation)
  - [Built-in Validators](#built-in-validators)
  - [Form Mixins](#form-mixins)
  - [Form Events](#form-events)
  - [Form States](#form-states)
- [Error & Screen Management](#error--screen-management)
- [Quickstart: Paged & Searchable List](#quickstart-paged--searchable-list)
- [Quickstart: Form with Validation](#quickstart-form-with-validation)
- [Migrating to 0.8.4](#migrating-to-084)
- [Migrating from 0.7.x](#migrating-from-07x)
- [Contributing](#contributing)
- [License](#license)

---

## Installation

Add `blocx_core` to your `pubspec.yaml`:

```yaml
dependencies:
  blocx_core: ^0.8.4
```

Or install via the command line:

```sh
dart pub add blocx_core
```

Import the library:

```dart
// Base types, use cases, results, screen manager, errors.
import 'package:blocx_core/blocx_core.dart';

// Collection-specific bloc, events, states, mixins, page, paginated use cases.
import 'package:blocx_core/list_bloc.dart';

// Form-specific bloc, events, states, mixins, validators, form entity.
import 'package:blocx_core/form_bloc.dart';
```

**Requirements:** Dart SDK `>=3.5.0`

---

## Architecture Overview

`blocx_core` is organised around four layers:

```txt
┌─────────────────────────────────────────────────────┐
│                  Your Domain BLoC                    │
│  BlocxCollectionBloc / BlocxFormBloc + mixins        │
└───────────────────────┬─────────────────────────────┘
                        │ executes
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
│  snackbar / error page / pop intents                 │
│  rendered by your Flutter layer or another UI layer  │
└─────────────────────────────────────────────────────┘
```

---

## Core Concepts

### BlocxBaseEntity

All domain objects used with collection blocs must extend `BlocxBaseEntity`. It provides stable identity semantics through `identifier`.

```dart
class Product extends BlocxBaseEntity {
  final String id;
  final String name;
  final double price;

  const Product({
    required this.id,
    required this.name,
    required this.price,
  });

  @override
  String get identifier => id;
}
```

The `identifier` is used internally for selection, highlighting, deletion, expansion, and scroll-to-item behavior.

---

### UseCase & UseCaseResult

Every async business operation should be represented by a `BlocxBaseUseCase<Input, Output>`.

Use cases expose `perform(input)` and are executed through `execute(input)`. Exception handling is built into `execute`; unhandled exceptions become `BlocxUseCaseFailure`.

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

`BlocxUseCaseResult<Output>` is either:

- success with `data`
- failure with `error` and `stackTrace`

---

### Use Case Tasks

Tasks pair a use case with a lazily evaluated input builder.

This matters because form data, selected items, filters, search text, payloads, and pagination values often change after the bloc is created.

### BlocxUseCaseTask

Use `BlocxUseCaseTask<Input, Output>` for normal operations.

```dart
BlocxUseCaseTask<CreateUserInput, User>(
  useCase: createUserUseCase,
  inputBuilder: () {
    return CreateUserInput(
      name: formData.name,
      email: formData.email,
    );
  },
);
```

Execute it with:

```dart
final result = await task.execute();
```

### BlocxPaginatedUseCaseTask

Use `BlocxPaginatedUseCaseTask<Input, Output>` for paginated operations.

`Input` must extend `BlocxPaginatedInput`. `Output` must extend `BlocxBaseEntity`.

```dart
BlocxPaginatedUseCaseTask<GetOrdersInput, Order>(
  useCase: getOrdersUseCase,
  inputBuilder: (offset, limit) {
    return GetOrdersInput(
      offset: offset,
      limit: limit,
      status: currentStatus,
    );
  },
);
```

Execute it with:

```dart
final result = await task.execute(offset: 0, limit: 20);
```

---

### BlocxPage\<T\>

`BlocxPage<T>` is the normalized container for paginated items.

```dart
class BlocxPage<T> {
  final List<T> items;
  final int offset;
  final int limit;

  bool get hasNext => limit == items.length;
}
```

`hasNext` returns `true` when the number of returned items equals the requested `limit`. If fewer items are returned, pagination is considered complete.

---

### ScreenManagerCubit

`ScreenManagerCubit` is owned internally by `BaseBloc`. You do not construct or pass one manually.

It lets BLoCs emit UI intents without importing Flutter:

| Method | Intent |
|---|---|
| `displaySnackBar(...)` | Show a snackbar or toast |
| `displayErrorWidget(...)` | Show a full-page error |
| `displayErrorWidgetByErrorCode(...)` | Show an error page from a typed error code |
| `pop()` | Request navigation pop |

```dart
displaySnackBar(
  message: 'Item deleted successfully.',
  type: BlocXSnackbarType.success,
);

displayErrorWidget(
  error: ReadableError(
    title: 'Not Found',
    message: 'The requested item could not be loaded.',
  ),
);

pop();
```

The UI layer decides how these intents are rendered.

---

## Collection BLoC

### BlocxCollectionBloc

`BlocxCollectionBloc<T, P>` is the base class for collection state management.

- `T` is the item entity type.
- `P` is an optional payload type used for initial loading.

Use `void` when no payload is needed.

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
      inputBuilder: (offset, limit) {
        return GetOrdersInput(
          offset: offset,
          limit: limit,
        );
      },
    );
  }
}
```

Mixin initialization is automatic. Do not call `initInfiniteList()`, `initSearch()`, `initRefresh()`, or similar methods manually.

---

### Collection Mixins

Mix these into a `BlocxCollectionBloc` subclass.

| Mixin | Capability |
|---|---|
| `BlocxCollectionInfiniteMixin<T, P>` | Next-page loading and reached-end tracking |
| `BlocxCollectionSearchableMixin<T, P>` | Debounced search, search pagination, and search refresh |
| `BlocxCollectionRefreshableMixin<T, P>` | Pull-to-refresh behavior |
| `BlocxCollectionSelectableMixin<T, P>` | Single and multi-item selection |
| `BlocxCollectionHighlightableMixin<T, P>` | Highlight and clear-highlight behavior |
| `BlocxCollectionExpandableMixin<T, P>` | Expand, collapse, and toggle item expansion |
| `BlocxCollectionScrollableMixin<T, P>` | Scroll-to-item and scroll-to-identifier intents |
| `BlocxCollectionDeletableMixin<T, P>` | Single delete, delete by id, and bulk delete |
| `BlocxCollectionSyncStreamMixin<T, P>` | Sync collection state from an external stream |

---

### Collection Tasks

#### Shared pagination

Use `paginationTask` when initial load, next-page load, and refresh use the same endpoint.

```dart
@override
BlocxPaginatedUseCaseTask<GetProductsInput, Product>? get paginationTask {
  return BlocxPaginatedUseCaseTask<GetProductsInput, Product>(
    useCase: getProductsUseCase,
    inputBuilder: (offset, limit) {
      return GetProductsInput(
        offset: offset,
        limit: limit,
        categoryId: payload?.categoryId,
      );
    },
  );
}
```

#### Separate initial, next-page, or refresh tasks

Override these only when an operation needs a different endpoint or input shape:

```dart
@override
BlocxPaginatedUseCaseTask<GetProductsInput, Product>? get loadInitialPageTask {
  return paginationTask;
}

@override
BlocxPaginatedUseCaseTask<GetProductsInput, Product>? get loadNextPageTask {
  return paginationTask;
}

@override
BlocxPaginatedUseCaseTask<GetProductsInput, Product>? get refreshPageUseCaseTask {
  return paginationTask;
}
```

#### Search

Search uses `searchUseCaseTask`. Its input should extend `BlocxSearchInput`.

```dart
@override
BlocxPaginatedUseCaseTask<BlocxSearchInput, Product>? get searchUseCaseTask {
  return BlocxPaginatedUseCaseTask<BlocxSearchInput, Product>(
    useCase: searchProductsUseCase,
    inputBuilder: (offset, limit) {
      return BlocxSearchInput(
        searchText: searchText,
        offset: offset,
        limit: limit,
      );
    },
  );
}
```

#### Delete

Delete uses task factories so each feature can build the input its API requires.

```dart
@override
BlocxUseCaseTask<DeleteProductInput, bool>? deleteItemTask(Product item) {
  return BlocxUseCaseTask<DeleteProductInput, bool>(
    useCase: deleteProductUseCase,
    inputBuilder: () {
      return DeleteProductInput(id: item.id);
    },
  );
}
```

For bulk delete:

```dart
@override
BlocxUseCaseTask<DeleteProductsInput, bool>? deleteMultipleItemsTask(
  List<Product> items,
) {
  return BlocxUseCaseTask<DeleteProductsInput, bool>(
    useCase: deleteProductsUseCase,
    inputBuilder: () {
      return DeleteProductsInput(
        ids: items.map((item) => item.id).toList(),
      );
    },
  );
}
```

#### Remote selection sync

Selection can be local only, or synced remotely.

```dart
@override
bool get syncWithServerOnSelection => true;

@override
BlocxUseCaseTask<SelectProductInput, bool>? selectItemTask(Product item) {
  return BlocxUseCaseTask<SelectProductInput, bool>(
    useCase: selectProductUseCase,
    inputBuilder: () => SelectProductInput(id: item.id),
  );
}

@override
BlocxUseCaseTask<DeselectProductInput, bool>? deselectItemTask(Product item) {
  return BlocxUseCaseTask<DeselectProductInput, bool>(
    useCase: deselectProductUseCase,
    inputBuilder: () => DeselectProductInput(id: item.id),
  );
}
```

---

### Collection Events

| Event | Description |
|---|---|
| `BlocxCollectionEventLoadInitialPage<T, P>` | Load the first page |
| `BlocxCollectionEventLoadNextPage<T>` | Append the next page |
| `BlocxCollectionEventRefreshData<T>` | Refresh the collection |
| `BlocxCollectionEventSearch<T>` | Run a debounced search query |
| `BlocxCollectionEventSearchNextPage<T>` | Load the next page of search results |
| `BlocxCollectionEventSearchRefresh<T>` | Refresh current search results |
| `BlocxCollectionEventClearSearch<T>` | Clear search and restore base list |
| `BlocxCollectionEventSelectItem<T>` | Select one item |
| `BlocxCollectionEventDeselectItem<T>` | Deselect one item |
| `BlocxCollectionEventSelectMultipleItems<T>` | Select multiple items |
| `BlocxCollectionEventDeselectMultipleItems<T>` | Deselect multiple items |
| `BlocxCollectionEventClearSelection<T>` | Clear all selection |
| `BlocxCollectionEventHighlightItem<T>` | Highlight one item |
| `BlocxCollectionEventClearHighlightedItem<T>` | Clear item highlight |
| `BlocxCollectionEventExpandItem<T>` | Expand one item |
| `BlocxCollectionEventCollapseItem<T>` | Collapse one item |
| `BlocxCollectionEventToggleItemExpansion<T>` | Toggle item expansion |
| `BlocxCollectionEventScrollToItem<T>` | Emit scroll-to-item state |
| `BlocxCollectionEventScrollToIdentifier<T>` | Emit scroll-to-identifier state |
| `BlocxCollectionEventAddItem<T>` | Insert an item |
| `BlocxCollectionEventUpdateItem<T>` | Replace an item |
| `BlocxCollectionEventRemoveItem<T>` | Remove one item |
| `BlocxCollectionEventRemoveItemById<T>` | Remove one item by identifier |
| `BlocxCollectionEventRemoveMultipleItems<T>` | Remove multiple items |
| `BlocxCollectionEventReplaceList<T>` | Replace the full list |

---

### Collection States

| State | Description |
|---|---|
| `BlocxCollectionStateLoading<T>` | Initial loading state |
| `BlocxCollectionStateLoaded<T>` | Collection data is available |
| `BlocxCollectionStateError<T>` | Collection loading failed |
| `BlocxCollectionStateSelectionChanged<T>` | Selection changed |
| `BlocxCollectionStateScrollToItem<T>` | UI should scroll to a specific item |

Use collection state extensions for convenience accessors where available.

---

## Form BLoC

### BlocxBaseFormEntity

A form entity must extend `BlocxBaseFormEntity<F, E>`.

- `F` is the form entity type itself.
- `E` is an enum that identifies each field.

The entity should be immutable.

```dart
enum ProfileField {
  name,
  email,
  phone,
}

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

  ProfileForm copyWith({
    String? name,
    String? email,
    String? phone,
  }) {
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

`updateByKey` is used by `BlocxFormEventUpdateData`.

`getValueByKey` is used for reading values, validation, and initial hydration by UI packages such as `flutter_blocx`.

---

### BlocxFormBloc

`BlocxFormBloc<F, P, E>` manages a form.

- `F` is your form entity.
- `P` is an optional initialization payload.
- `E` is your field enum.

```dart
class ProfileFormBloc
    extends BlocxFormBloc<ProfileForm, UserProfile, ProfileField>
    with BlocxFormValidationMixin<ProfileForm, UserProfile, ProfileField> {
  ProfileFormBloc() : super(const ProfileForm());

  @override
  FutureOr<ProfileForm> applyPayloadToFormData(UserProfile payload) {
    return ProfileForm(
      name: payload.name,
      email: payload.email,
      phone: payload.phone,
    );
  }

  @override
  BlocxUseCaseTask<UpdateProfileInput, UserProfile> get submitUseCaseTask {
    return BlocxUseCaseTask<UpdateProfileInput, UserProfile>(
      useCase: updateProfileUseCase,
      inputBuilder: () {
        return UpdateProfileInput(
          name: formData.name,
          email: formData.email,
          phone: formData.phone,
        );
      },
    );
  }

  @override
  BlocxFormValidator<ProfileForm, ProfileField> get validator {
    return ProfileFormValidator();
  }

  @override
  List<ProfileField> get formKeysList {
    return ProfileField.values;
  }

  @override
  FormValidationMode get formValidationMode {
    return FormValidationMode.onSubmit;
  }
}
```

Submit flow:

1. full-form validation is requested
2. validation mode decides what actually runs
3. `isFormSubmittable` blocks invalid or busy forms
4. `doBeforeSubmit` runs
5. submit use case task executes
6. `onFormSubmitted` runs
7. `BlocxFormStateFormSubmitted` is emitted

---

### Form Validation

`BlocxFormValidationMixin` delegates rules to a `BlocxFormValidator`.

Validation timing is controlled by `formValidationMode`:

| Mode | Behavior |
|---|---|
| `FormValidationMode.none` | No validation |
| `FormValidationMode.onSubmit` | Full-form validation only on submit/full-validation requests |
| `FormValidationMode.onUserInteraction` | Field validation while editing; full-form validation on submit |
| `FormValidationMode.always` | Full-form validation on every update and submit |

```dart
class ProfileFormValidator
    extends BlocxFormValidator<ProfileForm, ProfileField> {
  @override
  List<ProfileField> formKeys() {
    return ProfileField.values;
  }

  @override
  List<BlocxFieldValidator<ProfileForm, ProfileField, dynamic>>
      getValidatorsByKey(ProfileForm formData, ProfileField key) {
    return switch (key) {
      ProfileField.name => [
          BlocxStringRequiredValidator<ProfileForm, ProfileField>(),
          BlocxStringMinLengthValidator<ProfileForm, ProfileField>(
            minLength: 2,
          ),
        ],
      ProfileField.email => [
          BlocxStringRequiredValidator<ProfileForm, ProfileField>(),
          BlocxStringEmailValidator<ProfileForm, ProfileField>(),
        ],
      ProfileField.phone => [
          BlocxPhoneBasicFormatValidator<ProfileForm, ProfileField>(),
        ],
    };
  }
}
```

---

### Built-in Validators

Validators are exported from `form_bloc.dart`.

#### String validators

| Validator |
|---|
| `BlocxStringRequiredValidator` |
| `BlocxStringMinLengthValidator` |
| `BlocxStringMaxLengthValidator` |
| `BlocxStringExactLengthValidator` |
| `BlocxStringLengthRangeValidator` |
| `BlocxStringEmailValidator` |
| `BlocxStringRegexValidator` |
| `BlocxStringNumericValidator` |
| `BlocxStringAlphanumericValidator` |
| `BlocxStringUrlValidator` |
| `BlocxStringMatchValidator` |

#### DateTime validators

| Validator |
|---|
| `BlocxDateTimeRequiredValidator` |
| `BlocxDateTimeMinValidator` |
| `BlocxDateTimeMaxValidator` |
| `BlocxDateTimeRangeValidator` |
| `BlocxDateTimeAfterFieldValidator` |
| `BlocxDateTimeBeforeFieldValidator` |

#### Double validators

| Validator |
|---|
| `BlocxDoubleRequiredValidator` |
| `BlocxDoubleMinValueValidator` |
| `BlocxDoubleMaxValueValidator` |
| `BlocxDoublePositiveValidator` |
| `BlocxDoubleRangeValidator` |

#### Integer validators

| Validator |
|---|
| `BlocxIntegerRequiredValidator` |
| `BlocxIntegerMinValueValidator` |
| `BlocxIntegerMaxValueValidator` |
| `BlocxIntegerPositiveValidator` |
| `BlocxIntegerNonZeroValidator` |
| `BlocxIntegerRangeValidator` |
| `BlocxIntegerGreaterThanFieldValidator` |
| `BlocxIntegerLessThanFieldValidator` |

#### List validators

| Validator |
|---|
| `BlocxListRequiredValidator` |
| `BlocxListMinItemsValidator` |
| `BlocxListMaxItemsValidator` |
| `BlocxListUniqueItemsValidator` |

#### File validators

| Validator |
|---|
| `BlocxFile` |
| `BlocxFileRequiredValidator` |
| `BlocxFileMaxSizeValidator` |

#### Phone number validators

| Validator |
|---|
| `BlocxPhoneRequiredValidator` |
| `BlocxPhoneBasicFormatValidator` |
| `BlocxPhoneE164Validator` |
| `BlocxPhoneMinLengthValidator` |
| `BlocxPhoneMaxLengthValidator` |

---

### Form Mixins

| Mixin | Capability |
|---|---|
| `BlocxFormValidationMixin<F, P, E>` | Per-field and full-form validation |
| `BlocxFormErrorsMixin<F, P, E>` | Programmatic persistent and timed errors |
| `BlocxFormInfoFetcherMixin<F, P, E>` | Fetch remote data required before form interaction |
| `BlocxFormSteppedMixin<F, P, E>` | Multi-step form navigation |
| `BlocxUniqueFieldValidatorMixin<F, P, E>` | Async uniqueness validation per field |

#### Required info fetching

```dart
@override
Map<ProfileField, BlocxUseCaseTask<Object?, Object?>>
    get requiredInitialInfoTasks {
  return {
    ProfileField.phone: BlocxUseCaseTask<Object?, Object?>(
      useCase: getPhoneMetadataUseCase,
      inputBuilder: () => null,
    ),
  };
}
```

#### Unique-field validation

```dart
@override
List<ProfileField> get uniqueFieldKeys {
  return [ProfileField.email];
}

@override
BlocxUseCaseTask<CheckEmailInput, bool>? useCaseIsUniqueValueAvailable(
  ProfileField key,
  dynamic value,
) {
  if (key != ProfileField.email) return null;

  return BlocxUseCaseTask<CheckEmailInput, bool>(
    useCase: checkEmailUseCase,
    inputBuilder: () {
      return CheckEmailInput(email: value as String);
    },
  );
}
```

---

### Form Events

| Event | Description |
|---|---|
| `BlocxFormEventInit<P>` | Initialize the form, optionally with a payload |
| `BlocxFormEventFetchRequiredInfo` | Fetch remote data required by the form |
| `BlocxFormEventUpdateData<E>` | Update one field |
| `BlocxFormEventUpdateFormData<P>` | Replace the full form data object |
| `BlocxFormEventSubmit` | Validate and submit |
| `BlocxFormEventSetErrorToField<E>` | Set a persistent field error |
| `BlocxFormEventSetTimedErrorToField<E>` | Set a temporary field error |
| `BlocxFormEventClearFieldError<E>` | Clear a field error |
| `BlocxFormEventCheckUniqueValue<E>` | Check async uniqueness |
| `BlocxFormEventNextStep` | Go to next step |
| `BlocxFormEventPreviousStep` | Go to previous step |
| `BlocxFormEventGoToStep` | Jump to a specific step |

---

### Form States

| State | Description |
|---|---|
| `BlocxFormStateInitial<F, E>` | Form not initialized |
| `BlocxFormStateLoaded<F, E>` | Form loaded and interactive |
| `BlocxFormStateFormUpdated<F, E>` | Field value or form data updated |
| `BlocxFormStateApplyInitialDataToForm<F, E>` | Initial data should be applied to UI controls |
| `BlocxFormStateSubmittingForm<F, E>` | Submit in progress |
| `BlocxFormStateFormSubmitted<F, E>` | Submit succeeded |

---

## Error & Screen Management

Any bloc can emit UI intents without importing Flutter.

Error handling is built into `BaseBloc`. Call `handleError` from event handlers to log and surface errors through the configured `errorDisplayPolicy`.

```dart
try {
  // work
} catch (error, stackTrace) {
  handleError(error, emit, stacktrace: stackTrace);
}
```

To display a full-page error instead of a snackbar, override:

```dart
@override
ErrorDisplayPolicy get errorDisplayPolicy => ErrorDisplayPolicy.page;
```

Register a `BlocxErrorTranslator` once at app startup to map raw exceptions to human-readable `ReadableError` instances.

```dart
BlocxErrorTranslator.instance = AppErrorTranslator();
```

The presentation layer listens to `ScreenManagerCubit` and decides how to render each state.

---

## Quickstart: Paged & Searchable List

This example wires up a paginated, searchable, refreshable, and selectable `Todo` collection.

### 1. Define the entity

```dart
import 'package:blocx_core/blocx_core.dart';

class Todo extends BlocxBaseEntity {
  final String id;
  final String title;
  final bool completed;

  const Todo({
    required this.id,
    required this.title,
    this.completed = false,
  });

  @override
  String get identifier => id;
}
```

### 2. Define the repository contract

```dart
abstract class TodoRepository {
  Future<List<Todo>> fetchPage({
    required int limit,
    required int offset,
  });

  Future<List<Todo>> search({
    required String query,
    required int limit,
    required int offset,
  });
}
```

### 3. Implement use cases

```dart
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/list_bloc.dart';

class FetchTodosUseCase
    extends BlocxPaginatedUseCase<BlocxPaginatedInput, Todo> {
  final TodoRepository repo;

  FetchTodosUseCase(this.repo);

  @override
  Future<BlocxUseCaseResult<BlocxPage<Todo>>> perform(
    BlocxPaginatedInput input,
  ) async {
    final items = await repo.fetchPage(
      limit: input.limit,
      offset: input.offset,
    );

    return successResult(items: items, input: input);
  }
}

class SearchTodosUseCase extends BlocxSearchUseCase<BlocxSearchInput, Todo> {
  final TodoRepository repo;

  SearchTodosUseCase(this.repo);

  @override
  Future<BlocxUseCaseResult<BlocxPage<Todo>>> perform(
    BlocxSearchInput input,
  ) async {
    final items = await repo.search(
      query: input.searchText,
      limit: input.limit,
      offset: input.offset,
    );

    return successResult(items: items, input: input);
  }
}
```

### 4. Compose the collection bloc

```dart
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/list_bloc.dart';

class TodosBloc extends BlocxCollectionBloc<Todo, void>
    with
        BlocxCollectionInfiniteMixin<Todo, void>,
        BlocxCollectionSearchableMixin<Todo, void>,
        BlocxCollectionRefreshableMixin<Todo, void>,
        BlocxCollectionSelectableMixin<Todo, void> {
  final FetchTodosUseCase fetchTodosUseCase;
  final SearchTodosUseCase searchTodosUseCase;

  TodosBloc({
    required this.fetchTodosUseCase,
    required this.searchTodosUseCase,
  }) : super();

  @override
  BlocxPaginatedUseCaseTask<BlocxPaginatedInput, Todo>? get paginationTask {
    return BlocxPaginatedUseCaseTask<BlocxPaginatedInput, Todo>(
      useCase: fetchTodosUseCase,
      inputBuilder: (offset, limit) {
        return BlocxPaginatedInput(
          offset: offset,
          limit: limit,
        );
      },
    );
  }

  @override
  BlocxPaginatedUseCaseTask<BlocxSearchInput, Todo>? get searchUseCaseTask {
    return BlocxPaginatedUseCaseTask<BlocxSearchInput, Todo>(
      useCase: searchTodosUseCase,
      inputBuilder: (offset, limit) {
        return BlocxSearchInput(
          searchText: searchText,
          offset: offset,
          limit: limit,
        );
      },
    );
  }

  @override
  bool get isSingleSelect => false;
}
```

### 5. Drive the collection bloc

```dart
final bloc = TodosBloc(
  fetchTodosUseCase: FetchTodosUseCase(repo),
  searchTodosUseCase: SearchTodosUseCase(repo),
);

bloc.add(BlocxCollectionEventLoadInitialPage<Todo, void>(payload: null));
bloc.add(BlocxCollectionEventLoadNextPage<Todo>());
bloc.add(BlocxCollectionEventSearch<Todo>(searchText: 'urgent'));
bloc.add(BlocxCollectionEventClearSearch<Todo>());
bloc.add(BlocxCollectionEventRefreshData<Todo>());
bloc.add(BlocxCollectionEventSelectItem<Todo>(item: someTodo));
bloc.add(BlocxCollectionEventClearSelection<Todo>());
```

> For ready-made Flutter list widgets, use [`flutter_blocx`](https://pub.dev/packages/flutter_blocx).

---

## Quickstart: Form with Validation

### 1. Define the field enum and form entity

```dart
import 'package:blocx_core/form_bloc.dart';

enum SignUpField {
  email,
  password,
  confirmPassword,
}

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
  SignUpForm updateByKey(SignUpField key, dynamic value) {
    return switch (key) {
      SignUpField.email => copyWith(email: value as String),
      SignUpField.password => copyWith(password: value as String),
      SignUpField.confirmPassword => copyWith(
          confirmPassword: value as String,
        ),
    };
  }

  @override
  dynamic getValueByKey(SignUpField key) {
    return switch (key) {
      SignUpField.email => email,
      SignUpField.password => password,
      SignUpField.confirmPassword => confirmPassword,
    };
  }

  SignUpForm copyWith({
    String? email,
    String? password,
    String? confirmPassword,
  }) {
    return SignUpForm(
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
    );
  }

  @override
  String get identifier => 'sign_up_form';
}
```

### 2. Define the validator

```dart
class SignUpValidator extends BlocxFormValidator<SignUpForm, SignUpField> {
  @override
  List<SignUpField> formKeys() {
    return SignUpField.values;
  }

  @override
  List<BlocxFieldValidator<SignUpForm, SignUpField, dynamic>>
      getValidatorsByKey(SignUpForm formData, SignUpField key) {
    return switch (key) {
      SignUpField.email => [
          BlocxStringRequiredValidator<SignUpForm, SignUpField>(),
          BlocxStringEmailValidator<SignUpForm, SignUpField>(),
        ],
      SignUpField.password => [
          BlocxStringRequiredValidator<SignUpForm, SignUpField>(),
          BlocxStringMinLengthValidator<SignUpForm, SignUpField>(
            minLength: 8,
          ),
        ],
      SignUpField.confirmPassword => [
          BlocxStringRequiredValidator<SignUpForm, SignUpField>(),
          BlocxStringMatchValidator<SignUpForm, SignUpField>(
            SignUpField.password,
          ),
        ],
    };
  }
}
```

### 3. Define the submit use case

```dart
class CreateAccountInput {
  final String email;
  final String password;

  const CreateAccountInput({
    required this.email,
    required this.password,
  });
}

class Account {
  final String id;
  final String email;

  const Account({
    required this.id,
    required this.email,
  });
}

class CreateAccountUseCase
    extends BlocxBaseUseCase<CreateAccountInput, Account> {
  final AuthRepository repo;

  CreateAccountUseCase(this.repo);

  @override
  Future<BlocxUseCaseResult<Account>> perform(
    CreateAccountInput input,
  ) async {
    final account = await repo.createAccount(
      email: input.email,
      password: input.password,
    );

    return success(account);
  }
}
```

### 4. Compose the form bloc

```dart
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/form_bloc.dart';

class SignUpBloc extends BlocxFormBloc<SignUpForm, void, SignUpField>
    with BlocxFormValidationMixin<SignUpForm, void, SignUpField> {
  final CreateAccountUseCase createAccountUseCase;

  SignUpBloc({
    required this.createAccountUseCase,
  }) : super(const SignUpForm());

  @override
  BlocxFormValidator<SignUpForm, SignUpField> get validator {
    return SignUpValidator();
  }

  @override
  List<SignUpField> get formKeysList {
    return SignUpField.values;
  }

  @override
  FormValidationMode get formValidationMode {
    return FormValidationMode.onSubmit;
  }

  @override
  BlocxUseCaseTask<CreateAccountInput, Account> get submitUseCaseTask {
    return BlocxUseCaseTask<CreateAccountInput, Account>(
      useCase: createAccountUseCase,
      inputBuilder: () {
        return CreateAccountInput(
          email: formData.email,
          password: formData.password,
        );
      },
    );
  }
}
```

### 5. Drive the form bloc

```dart
final bloc = SignUpBloc(
  createAccountUseCase: CreateAccountUseCase(repo),
);

bloc.add(BlocxFormEventInit<void>());

bloc.add(
  BlocxFormEventUpdateData<SignUpField>(
    key: SignUpField.email,
    data: 'user@example.com',
  ),
);

bloc.add(
  BlocxFormEventUpdateData<SignUpField>(
    key: SignUpField.password,
    data: 'password123',
  ),
);

bloc.add(BlocxFormEventSubmit());
```

> For ready-made Flutter form widgets, use [`flutter_blocx`](https://pub.dev/packages/flutter_blocx).

---

## Migrating to 0.8.4

### Replace `BlocxPaginationInput` with `BlocxPaginatedInput`

```dart
// Before
class GetUsersInput extends BlocxPaginationInput {
  const GetUsersInput({
    required super.limit,
    required super.offset,
  });
}

// After
class GetUsersInput extends BlocxPaginatedInput {
  const GetUsersInput({
    required super.limit,
    required super.offset,
  });
}
```

### Update paginated use case imports

```dart
// Before
import 'package:blocx_core/src/blocs/list/use_cases/blocx_pagination_use_case.dart';

// After
import 'package:blocx_core/src/blocs/list/use_cases/blocx_paginated_use_case.dart';
```

Prefer the public barrel:

```dart
import 'package:blocx_core/list_bloc.dart';
```

### Update normal use case tasks

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

### Update paginated tasks

```dart
@override
BlocxPaginatedUseCaseTask<GetUsersInput, User>? get paginationTask {
  return BlocxPaginatedUseCaseTask<GetUsersInput, User>(
    useCase: getUsersUseCase,
    inputBuilder: (offset, limit) {
      return GetUsersInput(
        offset: offset,
        limit: limit,
      );
    },
  );
}
```

### Update search tasks

```dart
@override
BlocxPaginatedUseCaseTask<BlocxSearchInput, User>? get searchUseCaseTask {
  return BlocxPaginatedUseCaseTask<BlocxSearchInput, User>(
    useCase: searchUsersUseCase,
    inputBuilder: (offset, limit) {
      return BlocxSearchInput(
        searchText: searchText,
        offset: offset,
        limit: limit,
      );
    },
  );
}
```

### Update delete configuration

```dart
// Before
@override
BlocxBaseUseCase<User, bool>? get deleteItemUseCase => deleteUserUseCase;

// After
@override
BlocxUseCaseTask<DeleteUserInput, bool>? deleteItemTask(User item) {
  return BlocxUseCaseTask<DeleteUserInput, bool>(
    useCase: deleteUserUseCase,
    inputBuilder: () => DeleteUserInput(id: item.id),
  );
}
```

### Update remote selection sync

```dart
@override
BlocxUseCaseTask<SelectUserInput, bool>? selectItemTask(User item) {
  return BlocxUseCaseTask<SelectUserInput, bool>(
    useCase: selectUserUseCase,
    inputBuilder: () => SelectUserInput(id: item.id),
  );
}

@override
BlocxUseCaseTask<DeselectUserInput, bool>? deselectItemTask(User item) {
  return BlocxUseCaseTask<DeselectUserInput, bool>(
    useCase: deselectUserUseCase,
    inputBuilder: () => DeselectUserInput(id: item.id),
  );
}
```

### Update form submit tasks

```dart
@override
BlocxUseCaseTask<CreateAccountInput, Account> get submitUseCaseTask {
  return BlocxUseCaseTask<CreateAccountInput, Account>(
    useCase: createAccountUseCase,
    inputBuilder: () {
      return CreateAccountInput(
        email: formData.email,
        password: formData.password,
      );
    },
  );
}
```

### Note form submit behavior

Form submission now requests full validation before `doBeforeSubmit`.

The submit use case is blocked when:

- validation errors exist
- required form info is still loading
- unique-field validation is still running

`FormValidationMode` still decides what validation actually runs.

---

## Migrating from 0.7.x

### List bloc rename

`BlocxListBloc` was renamed to `BlocxCollectionBloc`.

```dart
// Before
class TodosBloc extends BlocxListBloc<Todo, void> {}

// After
class TodosBloc extends BlocxCollectionBloc<Todo, void> {}
```

### Collection mixin renames

| Before | After |
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

### Form mixin renames

| Before | After |
|---|---|
| `BlocxInfoFetcherFormMixin` | `BlocxFormInfoFetcherMixin` |
| `BlocxSteppedFormMixin` | `BlocxFormSteppedMixin` |

### Event and state renames

All list events and states were renamed from `BlocxList*` to `BlocxCollection*`.

| Before | After |
|---|---|
| `BlocxListEventLoadInitialPage` | `BlocxCollectionEventLoadInitialPage` |
| `BlocxListEventLoadNextPage` | `BlocxCollectionEventLoadNextPage` |
| `BlocxListEventSearch` | `BlocxCollectionEventSearch` |
| `BlocxListEventRefreshData` | `BlocxCollectionEventRefreshData` |
| `BlocxListStateLoading` | `BlocxCollectionStateLoading` |
| `BlocxListStateLoaded` | `BlocxCollectionStateLoaded` |
| `BlocxListStateError` | `BlocxCollectionStateError` |

### Automatic mixin initialization

Manual mixin initialization is no longer needed.

```dart
// Before
TodosBloc() : super() {
  initInfiniteList();
  initSearch();
  initRefresh();
}

// After
TodosBloc() : super();
```

### Constructor changes

`ScreenManagerCubit` and `BlocxInfiniteListBloc` are owned internally.

```dart
// Before
TodosBloc({
  required ScreenManagerCubit screen,
}) : super(screen, BlocxInfiniteListBloc());

// After
TodosBloc() : super();
```

### Model renames

| Before | After |
|---|---|
| `BaseFormEntity` | `BlocxBaseFormEntity` |
| `Page<T>` | `BlocxPage<T>` |
| `UseCaseResult<T>` | `BlocxUseCaseResult<T>` |
| `BlocxPaginationInput` | `BlocxPaginatedInput` |

---

## Contributing

Contributions are welcome.

- Run `dart format .` before committing.
- Ensure `dart analyze` reports no issues.
- Add or update tests for every new mixin, event, state, or validator.
- Run `dart test` before opening a pull request.
- All public APIs must include dartdoc comments.
- Keep pull requests focused: one feature or fix per PR.

---

## License

This project is licensed under the MIT License. See the [`LICENSE`](LICENSE) file at the repository root for details.