# Error Handling, ScreenManagerCubit, Localization & Testing (`blocx_core`)

## Table of Contents
1. [`BlocxBaseBloc` & `ScreenManagerCubit`](#1-blocxbasebloc--screenmanagercubit)
2. [`BlocxErrorTranslator`, `ReadableError` & `BlocXErrorCode`](#2-blocxerrortranslator-readableerror--blocxerrorcode)
3. [`BlocXLocalizations`](#3-blocxlocalizations)
4. [Pure-Dart Unit Testing Patterns](#4-pure-dart-unit-testing-patterns)

---

## 1. `BlocxBaseBloc` & `ScreenManagerCubit`

Every BLoC in `blocx_core` extends `BlocxBaseBloc<E extends BlocxBaseEvent, S extends BlocxBaseState>`.
`BlocxBaseBloc` creates and manages an internal `ScreenManagerCubit` accessed via `bloc.screenManagerCubit`.

### Built-in Screen & Feedback Helpers on `BlocxBaseBloc`
- `void pop()` -> emits `ScreenManagerCubitStatePop`
- `void displayInfoSnackbar(String message, {String? title})` -> emits `ScreenManagerCubitStateDisplaySnackbar(..., BlocXSnackbarType.info)` then restores previous state
- `void displayWarningSnackbar(String message, {String? title})` -> emits `ScreenManagerCubitStateDisplaySnackbar(..., BlocXSnackbarType.warning)` then restores previous state
- `void displayErrorSnackbar(String message, {String? title})` -> emits `ScreenManagerCubitStateDisplaySnackbar(..., BlocXSnackbarType.error)` then restores previous state
- `void displayErrorWidget(ReadableError error)` -> emits `ScreenManagerCubitStateDisplayErrorPage(error: error)`
- `void displayErrorWidgetByErrorCode(BlocXErrorCode errorCode, {Object? error, StackTrace? stackTrace})` -> emits `ScreenManagerCubitStateDisplayErrorPageByErrorCode`
- `FutureOr<void> handleError(Object error, Emitter<BlocxBaseState> emit, {StackTrace? stacktrace})`:
  Translates `error` using `BlocxErrorTranslator.errorTranslator` (or falls back to `defaultError`) and surfaces it according to `errorDisplayPolicy`.

### `ErrorDisplayPolicy`
```dart
enum ErrorDisplayPolicy {
  snackBar, // Default: calls displayErrorSnackbar
  page,     // Calls displayErrorWidget
}
```
Override in any BLoC to show full-page errors instead of snackbars:
```dart
@override
ErrorDisplayPolicy get errorDisplayPolicy => ErrorDisplayPolicy.page;
```

### `ScreenManagerCubitState` Hierarchy
- `ScreenManagerCubitStateInitial`
- `ScreenManagerCubitStateDisplayErrorPage({required ReadableError error})`
- `ScreenManagerCubitStateDisplayErrorPageByErrorCode(BlocXErrorCode errorCode, {Object? error, StackTrace? stackTrace})`
- `ScreenManagerCubitStateDisplaySnackbar({required String message, String? title, required BlocXSnackbarType snackbarType})`
- `ScreenManagerCubitStateDisplaySnackbarByErrorCode({required BlocXErrorCode errorCode, required BlocXSnackbarType snackbarType})`
- `ScreenManagerCubitStatePop`

---

## 2. `BlocxErrorTranslator`, `ReadableError` & `BlocXErrorCode`

### Registering a Custom `BlocxErrorTranslator`
```dart
class AppErrorTranslator extends BlocxErrorTranslator {
  @override
  ReadableError makeErrorReadable(Object error, {StackTrace? stackTrace}) {
    if (error is FormatException) {
      return ReadableError(
        title: 'Invalid Format',
        message: error.message,
        error: error,
        stackTrace: stackTrace,
      );
    }
    return ReadableError(
      message: error.toString(),
      error: error,
      stackTrace: stackTrace,
    );
  }
}

// Register once at startup:
BlocxErrorTranslator.setInstance(AppErrorTranslator());
```

### `BlocXErrorCode`
```dart
enum BlocXErrorCode {
  checkingUniqueValue,
  unknown,
  valueNotAvailable,
  errorGettingInitialFormData,
  fieldCannotBeEmpty,
}
```

---

## 3. `BlocXLocalizations`

`BlocXLocalizations.localizations` provides all built-in validator and error messages in English by default. To localize or customize messages across `blocx_core`, extend `BlocXLocalizations` and set:

```dart
BlocXLocalizations.localizations = MyCustomBlocXLocalizations();
```

---

## 4. Pure-Dart Unit Testing Patterns

When testing `blocx_core` UseCases and BLoCs with `package:test`:

```dart
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/collection_bloc.dart';
import 'package:blocx_core/form_bloc.dart';
import 'package:test/test.dart';

void main() {
  test('UseCase broadcasts command and CollectionBloc syncs automatically', () async {
    final eventHub = BlocxSimpleEventHub();
    final loadUseCase = LoadTasksUseCase(eventHub: eventHub);
    final createUseCase = SaveTaskUseCase(isCreate: true, eventHub: eventHub);

    final bloc = TasksCollectionBloc(
      loadTasksUseCase: loadUseCase,
      searchTasksUseCase: SearchTasksUseCase(),
      deleteTaskUseCase: DeleteTaskUseCase(eventHub: eventHub),
      eventHub: eventHub,
    );

    bloc.add(BlocxCollectionEventLoadInitialPage<TaskEntity, void>(payload: null));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    // Executing the UseCase broadcasts BlocxCommandType.create to eventHub
    await createUseCase.execute(const TaskEntity(id: '1', title: 'Write tests'));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(bloc.state.list.map((e) => e.id), contains('1'));

    await bloc.close();
    eventHub.dispose();
  });
}
```
- Always `await bloc.close()` and call `eventHub.dispose()` (synchronous `void`) at the end of tests to clean up stream subscriptions and internal `ScreenManagerCubit` / `BlocxInfiniteListBloc` instances.
- To verify `pop()` or snackbar actions on a BLoC in unit tests, listen to `bloc.screenManagerCubit.stream`:
  ```dart
  final screenStates = <ScreenManagerCubitState>[];
  final sub = bloc.screenManagerCubit.stream.listen(screenStates.add);
  // trigger action...
  expect(screenStates.whereType<ScreenManagerCubitStatePop>(), isNotEmpty);
  await sub.cancel();
  ```
