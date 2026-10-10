<p align="center">
  <img src="https://raw.githubusercontent.com/abolfazlkhanmohammdi/blocx_core/main/assets/pub/logo.png" width="180" alt="blocx_core logo" />
</p>

<h1 align="center">blocx_core</h1>

<p align="center">
  <strong>Composable, Pure-Dart BLoC Architecture for Paginated Collections, Reactive Forms, Use-Case Orchestration & Real-Time Event Sync</strong>
</p>

<p align="center">
  <a href="https://pub.dev/packages/blocx_core"><img src="https://img.shields.io/pub/v/blocx_core.svg" alt="pub version" /></a>
  <a href="https://pub.dev/packages/blocx_core/score"><img src="https://img.shields.io/pub/points/blocx_core" alt="pub points" /></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/sdk-%3E%3D3.5.0%20%3C4.0.0-blue" alt="Dart SDK" /></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-green" alt="License: MIT" /></a>
</p>

<p align="center">
  <a href="#why-blocx_core">Why blocx_core?</a> •
  <a href="#the-blocx-ecosystem-better-together">BlocX Ecosystem</a> •
  <a href="#installation">Installation</a> •
  <a href="#use-cases--live-eventhub-sync">EventHub Sync</a> •
  <a href="#collection-bloc">Collection BLoC</a> •
  <a href="#form-bloc">Form BLoC</a> •
  <a href="https://pub.dev/packages/flutter_blocx">flutter_blocx UI →</a>
</p>

---

## Why `blocx_core`?

Real-world applications rarely become hard to maintain because domain rules are complex—they become hard to maintain because every screen quietly rebuilds the same state-management plumbing:

- Paginated loading, infinite scrolling, pull-to-refresh, and debounced search
- Multi-selection, row expansion, item highlighting, and optimistic/remote deletion
- Immutable form state, per-field/on-submit validation, async uniqueness checks, and multi-step wizards
- Keeping open list and form screens synchronized when an entity is created, updated, or deleted elsewhere
- Routing errors and side effects (snackbars, full-page errors, back navigation) without coupling BLoCs to Flutter `BuildContext`

**`blocx_core` turns all of that recurring plumbing into composable, pure-Dart BLoC mixins and typed UseCase tasks.**

### Before vs. After

<table>
<tr>
<th>Traditional BLoC (~350+ lines per screen)</th>
<th>With <code>blocx_core</code> (~25 lines)</th>
</tr>
<tr>
<td>

```dart
class ProductsBloc extends Bloc<Event, State> {
  // Manual offset, limit & hasNext flags
  // Manual search debounce & cancellation
  // Manual selectedIds / deletingIds sets
  // Manual stream subscriptions & cleanup
  // Manual try/catch error translation
  // Manual 12+ on<Event> handlers...
}
```

</td>
<td>

```dart
class ProductsBloc extends BlocxCollectionBloc<Product, void>
    with
        BlocxCollectionInfiniteMixin<Product, void>,
        BlocxCollectionRefreshableMixin<Product, void>,
        BlocxCollectionSearchableMixin<Product, void>,
        BlocxCollectionSelectableMixin<Product, void>,
        BlocxCollectionDeletableMixin<Product, void>,
        BlocxCollectionSyncStreamMixin<Product, void> {
  ProductsBloc({required this.eventHub}) : super();
  // Override only your UseCase tasks!
}
```

</td>
</tr>
</table>

---

## The BlocX Ecosystem: Better Together

`blocx_core` is the **pure-Dart domain and state layer** of the BlocX ecosystem. For Flutter apps, pair it with **[`flutter_blocx`](https://pub.dev/packages/flutter_blocx)**—the official Flutter UI companion package that connects directly to your `blocx_core` BLoCs with zero `BlocConsumer`, `ScrollController`, or `TextEditingController` boilerplate.

| Layer | Package | What It Gives You |
| :--- | :--- | :--- |
| **Domain & State (Pure Dart)** | **[`blocx_core`](https://pub.dev/packages/blocx_core)** *(you are here)* | `BlocxCollectionBloc`, `BlocxFormBloc`, 15+ composable mixins, 35+ validators, `BlocxBaseUseCase`, `BlocxEventHub` live sync, `ScreenManagerCubit` |
| **Presentation & Widgets (Flutter)** | **[`flutter_blocx`](https://pub.dev/packages/flutter_blocx)** | `BlocxCollectionWidget`, `BlocxFormWidget`, `InfiniteList` / `InfiniteGrid` / `AnimatedInfiniteList`, `BlocxCollectionItem`, `BlocxFormTextField`, `BlocxFormDropdown`, `BlocxScreenManagerState`, `BlocxErrorWidget`, `ConfirmActionWidget` |

> **Building a Flutter app?** Install both [`blocx_core`](https://pub.dev/packages/blocx_core) and [`flutter_blocx`](https://pub.dev/packages/flutter_blocx) together to get a complete, end-to-end architecture from domain UseCases all the way to animated lists, grids, and validated forms.

---

## Feature Highlights

### 📦 Collections & Paginated Lists (`package:blocx_core/collection_bloc.dart`)
- **Offset/Limit Pagination & Infinite Scroll**: Built-in `BlocxPage<T>` tracking and `BlocxCollectionInfiniteMixin`.
- **Debounced Search & Dynamic Filters**: `BlocxCollectionSearchableMixin` and `BlocxCollectionFilterMixin` with automatic page resets.
- **Interactive Item States**: Single/multi-selection (`SelectableMixin`), row expansion (`ExpandableMixin`), temporary row highlighting (`HighlightableMixin`), and programmatic scroll-to-item (`ScrollableMixin`).
- **Single & Bulk Deletion**: Local or remote deletion with per-item loading indicators (`DeletableMixin`).
- **Live EventHub Sync**: Automatically insert, update, or remove items in real time when UseCases broadcast CRUD commands (`SyncStreamMixin`).

### 📝 Reactive Forms & Validation (`package:blocx_core/form_bloc.dart`)
- **Strongly Typed Form Entities**: Immutable `BlocxBaseFormEntity<F, E>` keyed by a field ` enum`.
- **4 Validation Modes**: `none`, `onSubmit`, `onUserInteraction`, and `always`.
- **35+ Built-in Validators**: Ready-made validators for `String`, `int`, `double`, `DateTime`, `List`, `File`, `Phone`, and cross-field matching.
- **Advanced Form Mixins**: Debounced server-side uniqueness checks (`BlocxUniqueFieldValidatorMixin`), reference data prefetching (`BlocxFormPrefetchMixin`), multi-step wizards (`BlocxFormSteppedMixin`), and live entity sync (`BlocxFormSyncStreamMixin`).

### ⚡ UseCases, EventHub & Screen Side Effects (`package:blocx_core/blocx_core.dart`)
- **Standardized UseCases**: `BlocxBaseUseCase`, `BlocxPaginatedUseCase`, and `BlocxSearchUseCase` with automatic exception-to-`BlocxUseCaseResult` conversion.
- **Unidirectional Command EventHub**: UseCases broadcast `BlocxCommandType` (`create`, `read`, `update`, `delete`) events to `BlocxEventHub`; BLoCs subscribe and update their states automatically.
- **UI-Agnostic Side Effects**: `ScreenManagerCubit` lets pure-Dart BLoCs trigger snackbars, full-page errors, and navigation pops without importing Flutter.

---

## Installation

Add `blocx_core` to your `pubspec.yaml`:

```yaml
dependencies:
  blocx_core: ^1.1.0
```

Or via the CLI:

```sh
dart pub add blocx_core
```

> **Using Flutter?** Add [`flutter_blocx`](https://pub.dev/packages/flutter_blocx) alongside `blocx_core`:
> ```sh
> flutter pub add blocx_core flutter_blocx
> ```

### Barrel Imports

Import only what your file needs:

```dart
// 1. Core: Entities, UseCases, Tasks, EventHub, ScreenManagerCubit, Error Translation, Localization
import 'package:blocx_core/blocx_core.dart';

// 2. Collections: BlocxCollectionBloc, Collection Events/States, BlocxPage, and all 10 Collection Mixins
import 'package:blocx_core/collection_bloc.dart';

// 3. Forms: BlocxFormBloc, Form Events/States, BlocxBaseFormEntity, Validators, and all 5 Form Mixins
import 'package:blocx_core/form_bloc.dart';
```

---

## Architecture Overview

```txt
┌──────────────────────────────────────────────────────────────────────┐
│                         UseCases (Domain)                            │
│  BlocxBaseUseCase / BlocxPaginatedUseCase / BlocxSearchUseCase       │
└───────────────┬──────────────────────────────────────┬───────────────┘
                │ returns BlocxUseCaseResult           │ broadcasts CRUD commands
                ▼                                      ▼
┌───────────────────────────────────┐    ┌─────────────────────────────┐
│     Your BLoC (State Layer)       │    │        BlocxEventHub        │
│  BlocxCollectionBloc + Mixins     │◄───│  create / read / update /   │
│  BlocxFormBloc + Mixins           │    │  delete BlocxEntityEvents   │
└───────────────┬───────────────────┘    └─────────────────────────────┘
                │ emits state & ScreenManagerCubit intents
                ▼
┌──────────────────────────────────────────────────────────────────────┐
│                    UI Layer (flutter_blocx)                          │
│  BlocxCollectionWidget / BlocxFormWidget / BlocxScreenManagerState   │
└──────────────────────────────────────────────────────────────────────┘
```

---

## Core Concepts: Entities, UseCases & Live EventHub Sync

### 1. Domain Entities (`BlocxBaseEntity`)

Every domain model managed by a collection or broadcasted through `BlocxEventHub` extends `BlocxBaseEntity` and provides a unique `identifier`:

```dart
import 'package:blocx_core/blocx_core.dart';

class ProductEntity extends BlocxBaseEntity {
  final String id;
  final String name;
  final double price;
  final bool isAvailable;

  const ProductEntity({
    required this.id,
    required this.name,
    required this.price,
    this.isAvailable = true,
  });

  @override
  String get identifier => id;
}
```

> **Note on Equality:** `BlocxBaseEntity` defines `identifier` for collection matching, deduplication, and sync. `BlocxBaseEntity` does not override `operator ==` or `hashCode` by default to avoid interfering with custom value equality solutions (such as `equatable` or `freezed`) or reference equality semantics. Subclasses may implement `operator ==` and `hashCode` if value-based equality is needed.

### 2. UseCases & Automatic `BlocxEventHub` Command Broadcasting

In `blocx_core`, **only UseCases emit app-wide domain events—BLoCs never emit them**.
When you pass an `eventHub` and `commandType` (or `commandTypes`) to a `BlocxBaseUseCase`, calling `await useCase.execute(input)` automatically broadcasts `BlocxEntityEvent`s for every affected entity as soon as `perform(input)` succeeds:

```dart
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/collection_bloc.dart';

// Paginated Read UseCase (defaults to BlocxCommandType.read)
class LoadProductsUseCase extends BlocxPaginatedUseCase<BlocxPaginatedInput, ProductEntity> {
  final ProductRepository repository;

  LoadProductsUseCase(this.repository, {super.eventHub});

  @override
  Future<BlocxUseCaseResult<BlocxPage<ProductEntity>>> perform(
    BlocxPaginatedInput input,
  ) async {
    final items = await repository.fetchPage(offset: input.offset, limit: input.limit);
    return success(BlocxPage(items: items, offset: input.offset, limit: input.limit));
  }
}

// Create / Update UseCase (Output is ProductEntity -> auto-resolved for EventHub)
class SaveProductUseCase extends BlocxBaseUseCase<ProductEntity, ProductEntity> {
  final ProductRepository repository;

  SaveProductUseCase(this.repository, {required bool isCreate, super.eventHub})
      : super(
          commandType: isCreate ? BlocxCommandType.create : BlocxCommandType.update,
        );

  @override
  Future<BlocxUseCaseResult<ProductEntity>> perform(ProductEntity input) async {
    final saved = await repository.save(input);
    return success(saved);
  }
}

// Delete UseCase (Input is ProductEntity, Output is bool -> auto-resolved from Input)
class DeleteProductUseCase extends BlocxBaseUseCase<ProductEntity, bool> {
  final ProductRepository repository;

  DeleteProductUseCase(this.repository, {super.eventHub})
      : super(commandType: BlocxCommandType.delete);

  @override
  Future<BlocxUseCaseResult<bool>> perform(ProductEntity input) async {
    await repository.delete(input.id);
    return success(true);
  }
}
```

> **Tip:** A single UseCase can also emit multiple commands by passing `commandTypes: const [BlocxCommandType.update, BlocxCommandType.read]` to `super(...)`, or customize entity extraction by overriding `resolveCommandEntities(input, output)`.

---

## Collection BLoC

`BlocxCollectionBloc<Entity, Payload>` orchestrates list/grid state. Compose it with any of the **10 built-in collection mixins**:

| Mixin | Capability Added |
| :--- | :--- |
| `BlocxCollectionInfiniteMixin<T, P>` | Infinite scrolling (`paginationTask` / `loadNextPageTask`) |
| `BlocxCollectionRefreshableMixin<T, P>` | Pull-to-refresh list reload (`refreshTask`) |
| `BlocxCollectionSearchableMixin<T, P>` | Debounced search & paginated search results (`searchUseCaseTask`) |
| `BlocxCollectionFilterMixin<T, P, F>` | Strongly typed filter state (`currentFilter`) with automatic reload |
| `BlocxCollectionSelectableMixin<T, P>` | Single/multi-selection (`selectedItems`) with optional remote sync |
| `BlocxCollectionDeletableMixin<T, P>` | Single & bulk deletion (`deleteItemTask`, `deleteMultipleItemsTask`) |
| `BlocxCollectionHighlightableMixin<T, P>` | Row highlight state (`highlightedItems`) |
| `BlocxCollectionExpandableMixin<T, P>` | Single or multi-row expansion (`expandedItems`) |
| `BlocxCollectionScrollableMixin<T, P>` | Programmatic scroll-to-item with optional highlight after scroll |
| `BlocxCollectionSyncStreamMixin<T, P>` | Real-time list updates from `BlocxEventHub` or custom entity streams |

### Quickstart: Paginated, Searchable, Deletable & Live-Synced Collection BLoC

```dart
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/collection_bloc.dart';

class ProductsCollectionBloc extends BlocxCollectionBloc<ProductEntity, void>
    with
        BlocxCollectionInfiniteMixin<ProductEntity, void>,
        BlocxCollectionRefreshableMixin<ProductEntity, void>,
        BlocxCollectionSearchableMixin<ProductEntity, void>,
        BlocxCollectionSelectableMixin<ProductEntity, void>,
        BlocxCollectionDeletableMixin<ProductEntity, void>,
        BlocxCollectionSyncStreamMixin<ProductEntity, void> {
  final LoadProductsUseCase loadProductsUseCase;
  final BlocxSearchUseCase<BlocxSearchInput, ProductEntity> searchProductsUseCase;
  final DeleteProductUseCase deleteProductUseCase;

  @override
  final BlocxEventHub eventHub;

  ProductsCollectionBloc({
    required this.loadProductsUseCase,
    required this.searchProductsUseCase,
    required this.deleteProductUseCase,
    required this.eventHub,
  }) : super();

  // Shared pagination task used by initial load, infinite scroll, and pull-to-refresh
  @override
  BlocxPaginatedUseCaseTask<BlocxPaginatedInput, ProductEntity>? get paginationTask {
    return BlocxPaginatedUseCaseTask<BlocxPaginatedInput, ProductEntity>(
      useCase: loadProductsUseCase,
      inputBuilder: (offset, limit) => BlocxPaginatedInput(offset: offset, limit: limit),
    );
  }

  @override
  BlocxPaginatedUseCaseTask<BlocxSearchInput, ProductEntity>? get searchUseCaseTask {
    return BlocxPaginatedUseCaseTask<BlocxSearchInput, ProductEntity>(
      useCase: searchProductsUseCase,
      inputBuilder: (offset, limit) => BlocxSearchInput(
        searchText: searchText,
        offset: offset,
        limit: limit,
      ),
    );
  }

  @override
  BlocxUseCaseTask<Object?, bool>? deleteItemTask(ProductEntity item) {
    return BlocxUseCaseTask<ProductEntity, bool>(
      useCase: deleteProductUseCase,
      inputBuilder: () => item,
    );
  }

  // Optional filter for live EventHub synchronization:
  @override
  bool shouldSyncEntity(ProductEntity entity, BlocxCommandType command) {
    if (command == BlocxCommandType.delete) return true;
    return entity.isAvailable;
  }
}
```

---

## Form BLoC

`BlocxFormBloc<F, P, E>` manages form data (`F extends BlocxBaseFormEntity<F, E>`), edit-mode hydration payload (`P`), and field keys (`E extends Enum`). Compose it with any of the **5 built-in form mixins**:

| Mixin | Capability Added |
| :--- | :--- |
| `BlocxFormValidationMixin<F, P, E>` | Per-field and full-form validation (`none`, `onSubmit`, `onUserInteraction`, `always`) |
| `BlocxUniqueFieldValidatorMixin<F, P, E>` | Debounced async uniqueness checks per field (e.g. username/email availability) |
| `BlocxFormPrefetchMixin<F, P, E>` | Prefetch remote reference data (e.g. dropdown options) before form interaction |
| `BlocxFormSteppedMixin<F, P, E>` | Multi-step wizard progression (`currentStep`, `totalSteps`) |
| `BlocxFormSyncStreamMixin<F, P, E, WatchedEntity>` | Live form updates when the watched entity is modified—and auto-`pop()` if deleted |

### Quickstart: Validated Edit Form BLoC with Live Sync

```dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/form_bloc.dart';

enum ProductFormField { name, price }

class ProductFormEntity extends BlocxBaseFormEntity<ProductFormEntity, ProductFormField> {
  final String id;
  final String name;
  final double price;

  const ProductFormEntity({this.id = 'new', this.name = '', this.price = 0.0});

  @override
  String get identifier => id;

  ProductFormEntity copyWith({String? id, String? name, double? price}) =>
      ProductFormEntity(
        id: id ?? this.id,
        name: name ?? this.name,
        price: price ?? this.price,
      );

  @override
  ProductFormEntity updateByKey(ProductFormField key, dynamic value) => switch (key) {
        ProductFormField.name => copyWith(name: value as String? ?? ''),
        ProductFormField.price => copyWith(price: (value as num?)?.toDouble() ?? 0.0),
      };

  @override
  dynamic getValueByKey(ProductFormField key) => switch (key) {
        ProductFormField.name => name,
        ProductFormField.price => price,
      };

  @override
  String? getFormattedValueByKey(ProductFormField key) => getValueByKey(key)?.toString();
}

class ProductFormValidator extends BlocxFormValidator<ProductFormEntity, ProductFormField> {
  @override
  List<ProductFormField> formKeys() => ProductFormField.values;

  @override
  List<BlocxFieldValidator<ProductFormEntity, ProductFormField, dynamic>> getValidatorsByKey(
    ProductFormEntity formData,
    ProductFormField key,
  ) =>
      switch (key) {
        ProductFormField.name => [
            BlocxStringRequiredValidator(),
            const BlocxStringMinLengthValidator(3),
          ],
        ProductFormField.price => [
            BlocxDoubleRequiredValidator(),
            BlocxDoublePositiveValidator(),
          ],
      };
}

class ProductFormBloc
    extends BlocxFormBloc<ProductFormEntity, ProductEntity, ProductFormField>
    with
        BlocxFormValidationMixin<ProductFormEntity, ProductEntity, ProductFormField>,
        BlocxFormSyncStreamMixin<ProductFormEntity, ProductEntity, ProductFormField,
            ProductEntity> {
  final SaveProductUseCase saveProductUseCase;

  @override
  final BlocxEventHub eventHub;

  @override
  final BlocxFormValidator<ProductFormEntity, ProductFormField> validator =
      ProductFormValidator();

  ProductFormBloc({
    required this.saveProductUseCase,
    required this.eventHub,
  }) : super(const ProductFormEntity());

  @override
  List<ProductFormField> get formKeysList => ProductFormField.values;

  @override
  FormValidationMode get formValidationMode => FormValidationMode.onUserInteraction;

  @override
  FutureOr<ProductFormEntity> applyPayloadToFormData(ProductEntity payload) {
    return formData.copyWith(id: payload.id, name: payload.name, price: payload.price);
  }

  @override
  BlocxUseCaseTask<Object?, Object?> get submitUseCaseTask {
    return BlocxUseCaseTask<ProductEntity, ProductEntity>(
      useCase: saveProductUseCase,
      inputBuilder: () => ProductEntity(
        id: formData.id,
        name: formData.name,
        price: formData.price,
      ),
    );
  }

  @override
  FutureOr<bool> onFormSubmitted(
    Emitter<BlocxFormState<ProductFormEntity, ProductFormField>> emit,
    BlocxUseCaseResult<Object?> result,
  ) {
    displayInfoSnackbar('Product saved successfully!');
    return true;
  }

  @override
  FutureOr<ProductFormEntity?> mapSyncedEntityToFormData(
    ProductEntity entity,
    BlocxCommandType command,
  ) {
    return formData.copyWith(id: entity.id, name: entity.name, price: entity.price);
  }
}
```

### Built-in Field Validators (`package:blocx_core/form_bloc.dart`)

- **String**: `BlocxStringRequiredValidator`, `BlocxStringMinLengthValidator(minLength)`, `BlocxStringMaxLengthValidator(maxLength)`, `BlocxStringLengthRangeValidator(minLength: ..., maxLength: ...)`, `BlocxStringExactLengthValidator(length)`, `BlocxStringEmailValidator`, `BlocxStringNumericValidator`, `BlocxStringAlphanumericValidator`, `BlocxStringUrlValidator`, `BlocxStringMatchValidator(otherKey)`
- **Integer**: `BlocxIntegerRequiredValidator`, `BlocxIntegerMinValueValidator(minValue)`, `BlocxIntegerMaxValueValidator(maxValue)`, `BlocxIntegerPositiveValidator`, `BlocxIntegerNonZeroValidator`, `BlocxIntegerRangeValidator(minValue, maxValue)`, `BlocxIntegerGreaterThanFieldValidator(otherKey)`, `BlocxIntegerLessThanFieldValidator(otherKey)`
- **Double**: `BlocxDoubleRequiredValidator`, `BlocxDoubleMinValueValidator(minValue)`, `BlocxDoubleMaxValueValidator(maxValue)`, `BlocxDoublePositiveValidator`, `BlocxDoubleRangeValidator(minValue, maxValue)`
- **DateTime**: `BlocxDateTimeRequiredValidator`, `BlocxDateTimeMinValidator(minDate)`, `BlocxDateTimeMaxValidator(maxDate)`, `BlocxDateTimeRangeValidator(minDate: ..., maxDate: ...)`, `BlocxDateTimeAfterFieldValidator(otherKey)`, `BlocxDateTimeBeforeFieldValidator(otherKey)`
- **Phone**: `BlocxPhoneRequiredValidator`, `BlocxPhoneBasicFormatValidator`, `BlocxPhoneE164Validator`, `BlocxPhoneMinLengthValidator(minDigits)`, `BlocxPhoneMaxLengthValidator(maxDigits)`
- **List, File & Object**: `BlocxListRequiredValidator`, `BlocxListMinItemsValidator(minItems)`, `BlocxListMaxItemsValidator(maxItems)`, `BlocxListUniqueItemsValidator`, `BlocxFileRequiredValidator`, `BlocxFileMaxSizeValidator(maxBytes)`, `BlocxRequiredFieldValidator`

---

## Screen Side Effects, Error Translation & Localization

Every `BlocxBaseBloc` (including `BlocxCollectionBloc` and `BlocxFormBloc`) owns an internal `ScreenManagerCubit` to trigger UI side effects cleanly from pure Dart:

```dart
// Inside any BlocxBaseBloc subclass:
displayInfoSnackbar('Saved!', title: 'Success');
displayWarningSnackbar('Connection is slow');
displayErrorSnackbar('Could not delete item');
displayErrorWidget(ReadableError(title: 'Offline', message: 'Check your connection'));
pop(); // Instructs the UI screen to pop the current route
```

Customize global error translation and localization at app startup:

```dart
// Global singletons (default):
BlocxErrorTranslator.instance = MyCustomErrorTranslator();
BlocXLocalizations.localizations = MyCustomLocalizations();

// Or inject per BLoC instance:
final bloc = ProductsBloc(
  errorTranslator: MyCustomErrorTranslator(),
  localizations: MyCustomLocalizations(),
);
```

---

## Unit Testing with `package:blocx_core/testing.dart`

`blocx_core` includes a dedicated testing library with pre-built test doubles and fakes so you can write fast, deterministic unit tests for your domain logic and BLoCs without boilerplate:

```dart
import 'package:blocx_core/testing.dart';
import 'package:test/test.dart';

void main() {
  test('collection loads and syncs with FakePaginatedSource and BlocxTestEventHub', () async {
    final eventHub = BlocxTestEventHub();
    final source = FakePaginatedSource<BlocxTestEntity>(
      items: [
        const BlocxTestEntity(id: '1', name: 'Item 1'),
        const BlocxTestEntity(id: '2', name: 'Item 2'),
      ],
    );

    final useCase = FakePaginatedUseCase<BlocxTestEntity>(source: source);
    // Test collection blocs, sync streams, and entity mutations effortlessly!
  });
}
```

Available test utilities:
- `BlocxTestEventHub`: In-memory synchronous event hub with recorded events.
- `BlocxTestEntity` & `BlocxTestFormEntity`: Lightweight test entities.
- `FakePaginatedSource` & `FakePaginatedUseCase`: Offset/limit paginated source.
- `FakeCursorPaginatedSource` & `FakeCursorPaginatedUseCase`: Cursor-based paginated source.
- `FakeSearchUseCase`: In-memory searchable use case test double.
- `FakeUseCase` & `MockUseCase`: Generic use-case stubs.

---

## Render Your BLoCs in Flutter with `flutter_blocx`

Don't write repetitive `BlocConsumer`, `ScrollController`, or `TextEditingController` glue code in Flutter! Pair `blocx_core` with **[`flutter_blocx`](https://pub.dev/packages/flutter_blocx)** ([GitHub](https://github.com/abolfazlkhanmohammdi/flutter_blocx)):

- **`BlocxCollectionWidget` & `BlocxCollectionWidgetState`**: Automatically wires `ProductsCollectionBloc` to animated lists, infinite grids, slivers, pull-to-refresh, `BlocxSearchField`, and `BlocxCollectionItem` cards.
- **`BlocxFormWidget` & `BlocxFormWidgetState`**: Automatically manages `TextEditingController`s and `FocusNode`s, binds `textField()`, `dropdown()`, `checkbox()`, and `BlocxFormButtonRow`, and handles edit-mode hydration.
- **`BlocxScreenManagerState`**: Automatically listens to `ScreenManagerCubit` to show `BlocxSnackBar`, render `BlocxErrorWidget` with retry callbacks, and pop routes.

👉 **[Explore `flutter_blocx` on pub.dev](https://pub.dev/packages/flutter_blocx)**

---

## Included AI Coding Skill

This repository includes an AI agent skill at [`skills/blocx-core/SKILL.md`](skills/blocx-core/SKILL.md) (compatible with Claude Code, Antigravity, and Cursor) containing full architectural rules, blueprints, and progressive-disclosure reference guides for `blocx_core`.

---

## Contributing & License

Contributions, issues, and feature requests are welcome at the [issue tracker](https://github.com/abolfazlkhanmohammdi/blocx_core/issues).

Released under the **MIT License**.
