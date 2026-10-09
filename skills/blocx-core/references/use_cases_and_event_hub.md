# UseCases, Tasks & EventHub Reference (`blocx_core`)

## Table of Contents
1. [`BlocxBaseEntity`](#1-blocxbaseentity)
2. [`BlocxBaseUseCase<Input, Output>` (`perform` vs `execute`)](#2-blocxbaseusecaseinput-output-perform-vs-execute)
3. [`BlocxUseCaseResult<Output>`](#3-blocxusecaseresultoutput)
4. [`BlocxPaginatedUseCase`, `BlocxPaginatedInput` & `BlocxPage`](#4-blocxpaginatedusecase-blocxpaginatedinput--blocxpage)
5. [`BlocxSearchUseCase` & `BlocxSearchInput`](#5-blocxsearchusecase--blocxsearchinput)
6. [`BlocxUseCaseTask` & `BlocxPaginatedUseCaseTask`](#6-blocxusecasetask--blocxpaginatedusecasetask)
7. [`BlocxEventHub`, `BlocxCommandType` & Entity Command Broadcasting](#7-blocxeventhub-blocxcommandtype--entity-command-broadcasting)
8. [`BlocxEventHubMixin` (Listener-Only BLoC Mixin)](#8-blocxeventhubmixin-listener-only-bloc-mixin)

---

## 1. `BlocxBaseEntity`

Import: `import 'package:blocx_core/blocx_core.dart';`

All domain items managed by `BlocxCollectionBloc` or broadcast as entity events via `BlocxEventHub` must extend `BlocxBaseEntity`:

```dart
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

  ProductEntity copyWith({
    String? id,
    String? name,
    double? price,
    bool? isAvailable,
  }) {
    return ProductEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}
```
- **Equality**: `BlocxBaseEntity` overrides `operator ==` and `hashCode` using `identifier` (and `runtimeType`). Two instances with the same `identifier` are considered the same item when replacing, removing, selecting, or syncing items in collections.

---

## 2. `BlocxBaseUseCase<Input, Output>` (`perform` vs `execute`)

```dart
abstract class BlocxBaseUseCase<Input, Output> {
  const BlocxBaseUseCase({
    BlocxEventHub? eventHub,
    BlocxCommandType? commandType,
    List<BlocxCommandType>? commandTypes,
  });

  BlocxEventHub? get eventHub;
  BlocxCommandType? get commandType;
  List<BlocxCommandType> get commandTypes;

  @nonVirtual
  Future<BlocxUseCaseResult<Output>> execute(Input input);

  @protected
  Future<BlocxUseCaseResult<Output>> perform(Input input);

  @protected
  BlocxUseCaseResult<Output> success(Output data) => BlocxUseCaseSuccess(data);

  @protected
  FutureOr<BlocxUseCaseResult<Output>> failureResult(Object error, StackTrace stackTrace) =>
      BlocxUseCaseFailure<Output>(error, stackTrace);

  void handleError(Object error, StackTrace stackTrace) {}

  @protected
  void handleBroadcastError(Object error, StackTrace stackTrace) {}
}
```

### Implementing a UseCase
- **Always override `perform(Input input)`** (never `call` or `execute`).
- Inside `perform`, return `success(myOutput)`. You may throw exceptions freely inside `perform`—`execute(input)` catches all unhandled exceptions, calls `handleError(error, stackTrace)`, and returns `failureResult(error, stackTrace)`.
- **Broadcasting isolation**: If `perform` succeeds, entity resolution and EventHub broadcasting are executed inside an isolated `try/catch`. Any error during broadcasting calls `handleBroadcastError` (which defaults to `handleError`) without failing the use case result.
- **Callers always invoke `await useCase.execute(input)`**.

```dart
class CreateProductUseCase extends BlocxBaseUseCase<ProductEntity, ProductEntity> {
  CreateProductUseCase({super.eventHub})
      : super(commandType: BlocxCommandType.create);

  @override
  Future<BlocxUseCaseResult<ProductEntity>> perform(ProductEntity input) async {
    return success(input);
  }
}
```

---

## 3. `BlocxUseCaseResult<Output>`

`BlocxUseCaseResult<T>` has two concrete subtypes: `BlocxUseCaseSuccess<T>(T data)` and `BlocxUseCaseFailure<T>(dynamic error, [StackTrace? stackTrace])`.

### Properties & Methods
- `bool get isSuccess` / `bool get isFailure`
- `T? get data` (returns `data` on success, `null` on failure)
- `T get dataOrThrow` (returns `data` on success, throws `error!` on failure)
- `dynamic get error` (returns `error` on failure, `null` on success)
- `StackTrace? get stackTrace`
- `R when<R>({required R Function(T data) onSuccess, required R Function(dynamic error, StackTrace? stackTrace) onFailure})`:
  ```dart
  result.when(
    onSuccess: (data) => ...,
    onFailure: (error, stackTrace) => ...,
  );
  ```

---

## 4. `BlocxPaginatedUseCase`, `BlocxPaginatedInput` & `BlocxPage`

Import: `import 'package:blocx_core/collection_bloc.dart';`

### `BlocxPaginatedInput`
```dart
class BlocxPaginatedInput {
  final int offset;
  final int limit;

  const BlocxPaginatedInput({required this.offset, required this.limit});

  BlocxPaginatedInput copyWith({int? offset, int? limit});
}
```
When your paginated endpoint needs custom filter parameters, extend `BlocxPaginatedInput`:
```dart
class LoadProductsInput extends BlocxPaginatedInput {
  final String? categoryId;

  const LoadProductsInput({
    required super.offset,
    required super.limit,
    this.categoryId,
  });

  @override
  LoadProductsInput copyWith({int? offset, int? limit, String? categoryId}) {
    return LoadProductsInput(
      offset: offset ?? this.offset,
      limit: limit ?? this.limit,
      categoryId: categoryId ?? this.categoryId,
    );
  }
}
```

### `BlocxPage<Entity>`
```dart
class BlocxPage<T> {
  final List<T> items;
  final int offset;
  final int limit;

  const BlocxPage({
    required this.items,
    required this.offset,
    required this.limit,
  });

  /// Returns `true` when `limit == items.length`.
  bool get hasNext => limit == items.length;
}
```
> **Important**: `BlocxPage` constructor requires `items`, `offset`, and `limit`. `hasNext` is a computed getter (`limit == items.length`), NOT a constructor parameter.

### `BlocxPaginatedUseCase<Input extends BlocxPaginatedInput, Entity extends BlocxBaseEntity>`
Extends `BlocxBaseUseCase<Input, BlocxPage<Entity>>`.
- Defaults `commandType` to `BlocxCommandType.read`.
- Overrides `resolveCommandEntities` to extract `output.items`.

```dart
class LoadProductsUseCase extends BlocxPaginatedUseCase<LoadProductsInput, ProductEntity> {
  final ProductRepository repository;

  LoadProductsUseCase({required this.repository, super.eventHub});

  @override
  Future<BlocxUseCaseResult<BlocxPage<ProductEntity>>> perform(LoadProductsInput input) async {
    final items = await repository.getProducts(
      offset: input.offset,
      limit: input.limit,
      categoryId: input.categoryId,
    );
    return success(
      BlocxPage<ProductEntity>(
        items: items,
        offset: input.offset,
        limit: input.limit,
      ),
    );
  }
}
```

---

## 5. `BlocxSearchUseCase` & `BlocxSearchInput`

Import: `import 'package:blocx_core/blocx_core.dart';`

### `BlocxSearchInput`
Extends `BlocxPaginatedInput` and adds `final String? searchText;`:
```dart
const BlocxSearchInput({
  required this.searchText,
  required super.offset,
  required super.limit,
});
```

### `BlocxSearchUseCase<Input extends BlocxSearchInput, Entity extends BlocxBaseEntity>`
Extends `BlocxPaginatedUseCase<Input, Entity>`:
```dart
class SearchProductsUseCase extends BlocxSearchUseCase<BlocxSearchInput, ProductEntity> {
  final ProductRepository repository;

  SearchProductsUseCase({required this.repository, super.eventHub});

  @override
  Future<BlocxUseCaseResult<BlocxPage<ProductEntity>>> perform(BlocxSearchInput input) async {
    final results = await repository.search(
      query: input.searchText ?? '',
      offset: input.offset,
      limit: input.limit,
    );
    return success(
      BlocxPage<ProductEntity>(
        items: results,
        offset: input.offset,
        limit: input.limit,
      ),
    );
  }
}
```

---

## 6. `BlocxUseCaseTask` & `BlocxPaginatedUseCaseTask`

### `BlocxUseCaseTask<Input, Output>`
Used for non-paginated UseCases (form submission, single/bulk item deletion, remote selection sync, form prefetching, unique-field checking):
```dart
BlocxUseCaseTask<ProductEntity, bool>(
  useCase: deleteProductUseCase,
  inputBuilder: () => item,
)
```

### `BlocxPaginatedUseCaseTask<Input extends BlocxPaginatedInput, Output extends BlocxBaseEntity>`
Used for paginated collection tasks (`paginationTask`, `loadInitialPageTask`, `loadNextPageTask`, `refreshPageUseCaseTask`, `searchUseCaseTask`):
```dart
BlocxPaginatedUseCaseTask<LoadProductsInput, ProductEntity>(
  useCase: loadProductsUseCase,
  inputBuilder: (offset, limit) => LoadProductsInput(
    offset: offset,
    limit: limit,
    categoryId: payload,
  ),
)
```
> **Important**: `PaginatedInputBuilder<Input>` has signature `Input Function(int offset, int limit)` with **positional** parameters `(offset, limit)`.

---

## 7. `BlocxEventHub`, `BlocxCommandType` & Entity Command Broadcasting

### Strict Architectural Boundary
- **Only UseCases emit events** (`super(eventHub: eventHub, ...)`).
- **BLoCs never emit events** to `BlocxEventHub`.

### `BlocxCommandType`
```dart
enum BlocxCommandType {
  create,
  read,
  update,
  delete,
}
```

### `BlocxEntityEvent<T extends BlocxBaseEntity>`
Emitted on `BlocxEventHub` whenever a UseCase with `eventHub` and `commandType`/`commandTypes` succeeds:
- `final List<T> entities`
- `T? get entity => entities.isEmpty ? null : entities.first`
- `final BlocxCommandType command`
- `final BlocxEventOrigin? origin`

### Single-Command vs Multi-Command UseCases

1. **Single Command (`commandType`)**:
   Pass `super(eventHub: eventHub, commandType: BlocxCommandType.create)` or override `BlocxCommandType? get commandType => BlocxCommandType.create;`.

2. **Multiple Commands (`commandTypes`)**:
   Pass `super(eventHub: eventHub, commandTypes: const [BlocxCommandType.update, BlocxCommandType.read])` or override `List<BlocxCommandType> get commandTypes`:
   ```dart
   class OrderCheckoutUseCase extends BlocxBaseUseCase<OrderEntity, OrderEntity> {
     OrderCheckoutUseCase({super.eventHub})
         : super(
             commandTypes: const [
               BlocxCommandType.update,
               BlocxCommandType.read,
             ],
           );

     @override
     Future<BlocxUseCaseResult<OrderEntity>> perform(OrderEntity input) async {
       return success(input.copyWith(status: 'checked_out'));
     }
   }
   ```

3. **Entity Resolution (`resolveCommandEntities`)**:
   By default, `BlocxBaseUseCase.resolveCommandEntities(input, output)` checks in order:
   1. If `output is BlocxBaseEntity` -> `[output]`
   2. If `output is BlocxPage` -> `output.items.whereType<BlocxBaseEntity>().toList()`
   3. If `output is Iterable` -> `output.whereType<BlocxBaseEntity>().toList()`
   4. If `input is BlocxBaseEntity` -> `[input]` *(handles `DeleteUseCase<MyEntity, bool>` automatically!)*
   5. If `input is Iterable` -> `input.whereType<BlocxBaseEntity>().toList()`
   
   Override `resolveCommandEntities(Input input, Output output)` whenever your `Input` is a custom DTO/ID rather than the `BlocxBaseEntity` itself:
   ```dart
   class DeleteProductUseCase extends BlocxBaseUseCase<ProductEntity, bool> {
     DeleteProductUseCase({super.eventHub})
         : super(commandType: BlocxCommandType.delete);

     @override
     List<BlocxBaseEntity> resolveCommandEntities(ProductEntity input, bool output) {
       return output ? <BlocxBaseEntity>[input] : const <BlocxBaseEntity>[];
     }

     @override
     Future<BlocxUseCaseResult<bool>> perform(ProductEntity input) async {
       return success(true);
     }
   }
   ```

4. **Conditional Broadcasting (`shouldBroadcastCommandResult`)**:
   By default, returns `output` when `output is bool` (so `false` does not broadcast) and `true` otherwise. Override `bool shouldBroadcastCommandResult(Input input, Output output)` for custom conditions.

### `BlocxEventHub` & `BlocxSimpleEventHub` API
```dart
final BlocxEventHub eventHub = BlocxSimpleEventHub();

// Subscribe to entity events for a specific entity type and optional command filter:
// Note: onEntity<T> supports heterogeneous entity batches and filters matching entities via whereType<T>():
Stream<BlocxEntityEvent<ProductEntity>> stream = eventHub.onEntity<ProductEntity>(
  commands: const [BlocxCommandType.create, BlocxCommandType.update],
);

// Synchronous cleanup:
eventHub.dispose(); // returns void
```

#### EventHub Performance & Metadata Guarantees:
- **Zero Release Overhead**: `debugTrace` stack capture in `BlocxSimpleEventHub.emit` is assert-guarded (`assert(() { event.debugTrace ??= StackTrace.current; return true; }())`), ensuring no expensive `StackTrace.current` allocations in production/release mode.
- **Heterogeneous Batch Support**: `onEntity<T>` triggers if any entity matches `T` (`entities.any((e) => e is T)`), extracting all matching entities with `whereType<T>()`.
- **Event Metadata Preservation**: Typed re-wrapping in `onEntity<T>` preserves the original event `id` and `createdAt` timestamp for full auditability.

---

## 8. `BlocxEventHubMixin` (Listener-Only BLoC Mixin)

For custom `BlocxBaseBloc` subclasses (outside `BlocxCollectionBloc` and `BlocxFormBloc`, which have their own dedicated `BlocxCollectionSyncStreamMixin` and `BlocxFormSyncStreamMixin`), mix in `BlocxEventHubMixin<E, S>` to listen to `eventHub` streams without exposing emit methods:

```dart
class DashboardSummaryBloc extends BlocxBaseBloc<DashboardEvent, DashboardState>
    with BlocxEventHubMixin<DashboardEvent, DashboardState> {
  @override
  final BlocxEventHub eventHub;

  DashboardSummaryBloc({required this.eventHub}) : super(DashboardStateInitial()) {
    entityEventsOfType<OrderEntity>(
      commands: const [BlocxCommandType.create, BlocxCommandType.update],
    ).listen((event) {
      add(DashboardEventOrderChanged(order: event.entity!, command: event.command));
    });
  }
}
```
