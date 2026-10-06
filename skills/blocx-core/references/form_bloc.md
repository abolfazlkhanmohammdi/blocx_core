# Form BLoC, Validation & Mixins Reference (`blocx_core`)

## Table of Contents
1. [Field Enum `E` & `BlocxBaseFormEntity<F, E>`](#1-field-enum-e--blocxbaseformentityf-e)
2. [`BlocxFormBloc<F, P, E>` & `BlocxFormCoreMixin`](#2-blocxformblocf-p-e--blocxformcoremixin)
3. [Form Events & States](#3-form-events--states)
4. [`BlocxFormErrorsMixin` (Persistent & Timed Errors)](#4-blocxformerrorsmixin-persistent--timed-errors)
5. [Validation (`BlocxFormValidationMixin`, `FormValidationMode`, `BlocxFormValidator`)](#5-validation-blocxformvalidationmixin-formvalidationmode-blocxformvalidator)
6. [Complete Built-in Field Validators Table](#6-complete-built-in-field-validators-table)
7. [All Optional Form Mixins](#7-all-optional-form-mixins)
   - [7.1 `BlocxUniqueFieldValidatorMixin` (Async Uniqueness Validation)](#71-blocxuniquefieldvalidatormixin-async-uniqueness-validation)
   - [7.2 `BlocxFormPrefetchMixin` (Parallel Reference Data Prefetch)](#72-blocxformprefetchmixin-parallel-reference-data-prefetch)
   - [7.3 `BlocxFormSteppedMixin` (Multi-Step Wizard Navigation)](#73-blocxformsteppedmixin-multi-step-wizard-navigation)
   - [7.4 `BlocxFormSyncStreamMixin` (Real-Time EventHub Sync for Forms)](#74-blocxformsyncstreammixin-real-time-eventhub-sync-for-forms)

---

## 1. Field Enum `E` & `BlocxBaseFormEntity<F, E>`

Import:
```dart
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/form_bloc.dart';
```

Every form requires:
1. A field `enum` (`E extends Enum`) with one value per form field.
2. An immutable class extending `BlocxBaseFormEntity<F, E>`.

### Required Overrides on `BlocxBaseFormEntity<F, E>`
- `String get identifier` (inherited from `BlocxBaseEntity`)
- `F updateByKey(E key, dynamic value)`
- `dynamic getValueByKey(E key)`

### Optional Override
- `dynamic getFormattedValueByKey(E key) => null;`
  Override when a field has a formatted string representation (e.g. a `DateTime`) that validators or UI should inspect via `getFormattedValueIfNotNullOtherwiseValue(key)`.

> **Debug Consistency Assertion (`updateByKeySafe`)**:
> When a field is updated via `BlocxFormEventUpdateData(key: key, data: value)`, `BlocxFormCoreMixin` calls `formData.updateByKeySafe(key, value)`. In debug mode, this asserts `DeepCollectionEquality().equals(result.getValueByKey(key), value)`. Therefore, `updateByKey` and `getValueByKey` **must** return the exact stored value for every enum key `E`.

```dart
enum ProfileFormField { username, email, age }

class ProfileFormEntity extends BlocxBaseFormEntity<ProfileFormEntity, ProfileFormField> {
  final String id;
  final String username;
  final String email;
  final int age;

  const ProfileFormEntity({
    this.id = 'draft',
    this.username = '',
    this.email = '',
    this.age = 0,
  });

  @override
  String get identifier => id;

  ProfileFormEntity copyWith({
    String? id,
    String? username,
    String? email,
    int? age,
  }) {
    return ProfileFormEntity(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      age: age ?? this.age,
    );
  }

  @override
  ProfileFormEntity updateByKey(ProfileFormField key, dynamic value) => switch (key) {
    ProfileFormField.username => copyWith(username: value as String? ?? ''),
    ProfileFormField.email => copyWith(email: value as String? ?? ''),
    ProfileFormField.age => copyWith(age: value as int? ?? 0),
  };

  @override
  dynamic getValueByKey(ProfileFormField key) => switch (key) {
    ProfileFormField.username => username,
    ProfileFormField.email => email,
    ProfileFormField.age => age,
  };
}
```

---

## 2. `BlocxFormBloc<F, P, E>` & `BlocxFormCoreMixin`

```dart
abstract class BlocxFormBloc<F extends BlocxBaseFormEntity<F, E>, P, E extends Enum>
    extends BlocxBaseBloc<BlocxFormEvent, BlocxFormState<F, E>>
    with BlocxFormCoreMixin<F, P, E>, BlocxFormErrorsMixin<F, P, E>
```
- **3 Type Parameters**:
  - `F`: The `BlocxBaseFormEntity<F, E>` subclass.
  - `P`: The payload type passed in `BlocxFormEventInit<P>(payload: ...)` for edit-mode hydration. Use `void` for create-only forms.
  - `E`: The field `Enum`.
- **Constructor**: `BlocxFormBloc(F formData)` initializes `super(BlocxFormStateInitial(formData: formData))` and auto-initializes all applied mixins.

### Required & Optional Overrides on `BlocxFormBloc<F, P, E>`

| Member | Signature | Purpose |
|---|---|---|
| `submitUseCaseTask` *(required)* | `BlocxUseCaseTask<Object?, Object?> get submitUseCaseTask` | Task executed on `BlocxFormEventSubmit` after validation passes. |
| `applyPayloadToFormData` | `FutureOr<F> applyPayloadToFormData(P payload) => formData;` | Hydrates `formData` from `payload` when `BlocxFormEventInit(payload: ...)` or `BlocxFormEventUpdateFormData(payload: ...)` is dispatched with a non-null payload. |
| `doBeforeSubmit` | `Future<bool> doBeforeSubmit(Emitter<BlocxFormState<F, E>> emit) async => true;` | Pre-submit hook; return `false` to abort submission. |
| `onFormSubmitted` | `FutureOr<bool> onFormSubmitted(Emitter<BlocxFormState<F, E>> emit, BlocxUseCaseResult<Object?> result) async => true;` | Post-submit hook; return `true` to emit `BlocxFormStateFormSubmitted`, or `false` to suppress it. |
| `validateOnInit` | `bool get validateOnInit => false;` | Whether to run full-form validation immediately on `BlocxFormEventInit`. |
| `shouldEmitChangesOnUpdate` | `bool get shouldEmitChangesOnUpdate => false;` | When `true`, emits `BlocxFormStateFormUpdated` before `BlocxFormStateLoaded` on every field change. |
| `formValidationMode` | `FormValidationMode get formValidationMode => FormValidationMode.none;` | Controls when validation runs (`onSubmit`, `onUserInteraction`, `always`, `none`). |

### Key State Properties on `BlocxFormBloc`
- `F formData`: Current form entity.
- `P? get payload`: Payload passed to `BlocxFormEventInit`.
- `bool get isUpdate`: `true` if initialized with a non-null `payload` (or updated via `BlocxFormEventUpdateFormData`).
- `bool get isFormSubmittable`: `errors.isEmpty && fieldsFetchingInfo.isEmpty && uniqueKeysBeingChecked.isEmpty`.

---

## 3. Form Events & States

### Form Events (`blocx_form_event.dart`)
| Event Class | Constructor | Description |
|---|---|---|
| `BlocxFormEventInit<P>` | `BlocxFormEventInit({required P? payload})` | Hydrates `formData` via `applyPayloadToFormData(payload)` if `payload != null`, emits `BlocxFormStateApplyInitialDataToForm`, optionally validates if `validateOnInit`, emits `BlocxFormStateLoaded`, and dispatches `BlocxFormEventPrefetchRequiredInfo()` if `BlocxFormPrefetchMixin` is applied. |
| `BlocxFormEventUpdateData<E>` | `BlocxFormEventUpdateData({required E key, required dynamic data})` | Updates `formData` via `updateByKeySafe(key, data)`, validates according to `formValidationMode`, triggers `BlocxFormEventCheckUniqueValue` if `key` is in `uniqueFieldKeys`, and emits state. |
| `BlocxFormEventSubmit` | `BlocxFormEventSubmit()` | Runs full validation (`forceFullValidation: true`), checks `isFormSubmittable` and `doBeforeSubmit`, emits `BlocxFormStateSubmittingForm`, executes `submitUseCaseTask`, and on success calls `onFormSubmitted` + emits `BlocxFormStateFormSubmitted` and `BlocxFormStateLoaded`. |
| `BlocxFormEventUpdateFormData<P>` | `BlocxFormEventUpdateFormData({required P payload, bool isUpdate = true})` | Replaces `formData` from a new `payload`, emits `BlocxFormStateApplyInitialDataToForm`, validates, and emits loaded state. |
| `BlocxFormEventSyncFormData<F>` | `BlocxFormEventSyncFormData({required F formData, bool applyToControllers = true, bool validate = false})` | Used by `BlocxFormSyncStreamMixin` to apply synced `formData`, optionally emit `BlocxFormStateApplyInitialDataToForm`, optionally validate, and emit loaded state. |
| `BlocxFormEventSetErrorToField<E>` | `BlocxFormEventSetErrorToField({required E key, required String message})` | Adds a persistent error message to field `key`. |
| `BlocxFormEventSetTimedErrorToField<E>` | `BlocxFormEventSetTimedErrorToField({required E key, required String message, Duration? duration})` | Adds a temporary error to field `key` that auto-clears after `duration` (default 3s). |
| `BlocxFormEventClearFieldError<E>` | `BlocxFormEventClearFieldError({required E key, String? message})` | Clears a specific `message` (or all errors on `key` when `message == null`). |

### Form States (`blocx_form_state.dart`)
All states extend `BlocxFormState<F, E>`:
- **Common properties**: `formData`, `step`, `comesFromPreviousStep`, `errors` (`Map<E, Set<String>>`), `fieldsFetchingInfo` (`Set<E>`), `checkingUniqueFields` (`Set<E>`), `isFormValid` (`bool`), `isValid` (`errors.isEmpty && fieldsFetchingInfo.isEmpty && checkingUniqueFields.isEmpty`), `errorByKey(E key)` (`String?`), `isFetchingFieldInfo(E key)` (`bool`).
- **Concrete State Subclasses**:
  1. `BlocxFormStateInitial<F, E>({required F formData})` (`shouldRebuild: true, shouldListen: false`)
  2. `BlocxFormStateLoaded<F, E>({...})` (`shouldRebuild: true, shouldListen: false`)
  3. `BlocxFormStateApplyInitialDataToForm<F, E>({required F formData})` (`shouldRebuild: false, shouldListen: true` — signals UI text controllers to sync with `formData`)
  4. `BlocxFormStateSubmittingForm<F, E>({required int step, required F formData, String? buttonText})` (`shouldRebuild: true, shouldListen: false`)
  5. `BlocxFormStateFormSubmitted<F, E>({required F formData, required dynamic submittedData})` (`shouldRebuild: false, shouldListen: true`)
  6. `BlocxFormStateFormUpdated<F, E>({required E updatedKey, required dynamic oldValue, required dynamic newValue, ...})` (`shouldRebuild: false, shouldListen: true`)

---

## 4. `BlocxFormErrorsMixin` (Persistent & Timed Errors)

Automatically mixed into `BlocxFormBloc`. Provides:
- `Map<E, Set<String>> get errors`
- `bool hasError(E key, [String? code])`
- `bool setFieldError(E key, String error, {required ErrorMutationSource source})`
- `bool clearFieldError(E key, {required ErrorMutationSource source, String? errorMessage})`
- `void clearAllErrors({ErrorMutationSource? source})`

---

## 5. Validation (`BlocxFormValidationMixin`, `FormValidationMode`, `BlocxFormValidator`)

### 1. Define a `BlocxFormValidator<F, E>`
```dart
class ProfileFormValidator extends BlocxFormValidator<ProfileFormEntity, ProfileFormField> {
  @override
  List<ProfileFormField> formKeys() => ProfileFormField.values;

  @override
  List<BlocxFieldValidator<ProfileFormEntity, ProfileFormField, dynamic>> getValidatorsByKey(
    ProfileFormEntity formData,
    ProfileFormField key,
  ) {
    return switch (key) {
      ProfileFormField.username => [
        BlocxStringRequiredValidator(),
        const BlocxStringMinLengthValidator(3),
      ],
      ProfileFormField.email => [
        BlocxStringRequiredValidator(),
        BlocxStringEmailValidator(),
      ],
      ProfileFormField.age => [
        const BlocxIntegerMinValueValidator(18),
      ],
    };
  }
}
```
> **Note on `const` vs non-`const` validators**: Zero-argument validators like `BlocxStringRequiredValidator()` and `BlocxStringEmailValidator()` use default non-`const` constructors, so instantiate them **without** `const`. Parameterized validators like `const BlocxStringMinLengthValidator(3)` and `const BlocxIntegerMinValueValidator(18)` have `const` constructors.

### 2. Mix `BlocxFormValidationMixin<F, P, E>` into `BlocxFormBloc<F, P, E>`
Required overrides:
- `BlocxFormValidator<F, E> get validator;`
- `List<E> get formKeysList;`
- Optional: `FormValidationMode get formValidationMode` (`onSubmit`, `onUserInteraction`, `always`, `none`).

---

## 6. Complete Built-in Field Validators Table

All exported from `package:blocx_core/form_bloc.dart`:

| Category | Validator Class | Constructor Signature | Value Type `T` |
|---|---|---|---|
| **String** | `BlocxStringRequiredValidator<F, E>` | `BlocxStringRequiredValidator()` *(non-const)* | `String` |
| **String** | `BlocxStringMinLengthValidator<F, E>` | `const BlocxStringMinLengthValidator(int min)` | `String` |
| **String** | `BlocxStringMaxLengthValidator<F, E>` | `const BlocxStringMaxLengthValidator(int max)` | `String` |
| **String** | `BlocxStringLengthRangeValidator<F, E>` | `const BlocxStringLengthRangeValidator(int min, int max)` | `String` |
| **String** | `BlocxStringExactLengthValidator<F, E>` | `const BlocxStringExactLengthValidator(int length)` | `String` |
| **String** | `BlocxStringEmailValidator<F, E>` | `BlocxStringEmailValidator()` *(non-const)* | `String` |
| **String** | `BlocxStringNumericValidator<F, E>` | `BlocxStringNumericValidator()` *(non-const)* | `String` |
| **String** | `BlocxStringAlphanumericValidator<F, E>` | `BlocxStringAlphanumericValidator()` *(non-const)* | `String` |
| **String** | `BlocxStringUrlValidator<F, E>` | `BlocxStringUrlValidator()` *(non-const)* | `String` |
| **String** | `BlocxStringMatchValidator<F, E>` | `const BlocxStringMatchValidator(E otherKey, {String? errorMessage})` | `String` |
| **Integer** | `BlocxIntegerRequiredValidator<F, E>` | `BlocxIntegerRequiredValidator()` *(non-const)* | `int?` |
| **Integer** | `BlocxIntegerMinValueValidator<F, E>` | `const BlocxIntegerMinValueValidator(int min)` | `int?` |
| **Integer** | `BlocxIntegerMaxValueValidator<F, E>` | `const BlocxIntegerMaxValueValidator(int max)` | `int?` |
| **Integer** | `BlocxIntegerRangeValidator<F, E>` | `const BlocxIntegerRangeValidator(int min, int max)` | `int?` |
| **Integer** | `BlocxIntegerPositiveValidator<F, E>` | `const BlocxIntegerPositiveValidator()` | `int?` |
| **Integer** | `BlocxIntegerNonZeroValidator<F, E>` | `const BlocxIntegerNonZeroValidator()` | `int?` |
| **Integer** | `BlocxIntegerGreaterThanFieldValidator<F, E>` | `const BlocxIntegerGreaterThanFieldValidator(E otherKey)` | `int?` |
| **Integer** | `BlocxIntegerLessThanFieldValidator<F, E>` | `const BlocxIntegerLessThanFieldValidator(E otherKey, String otherFieldName)` | `int?` |
| **Double** | `BlocxDoubleRequiredValidator<F, E>` | `BlocxDoubleRequiredValidator()` *(non-const)* | `double?` |
| **Double** | `BlocxDoubleMinValueValidator<F, E>` | `const BlocxDoubleMinValueValidator(double min)` | `double?` |
| **Double** | `BlocxDoubleMaxValueValidator<F, E>` | `const BlocxDoubleMaxValueValidator(double max)` | `double?` |
| **Double** | `BlocxDoubleRangeValidator<F, E>` | `const BlocxDoubleRangeValidator(double min, double max)` | `double?` |
| **Double** | `BlocxDoublePositiveValidator<F, E>` | `const BlocxDoublePositiveValidator()` | `double?` |
| **DateTime** | `BlocxDateTimeRequiredValidator<F, E>` | `BlocxDateTimeRequiredValidator()` *(non-const)* | `DateTime?` |
| **DateTime** | `BlocxDateTimeMinValidator<F, E>` | `const BlocxDateTimeMinValidator(DateTime min)` | `DateTime?` |
| **DateTime** | `BlocxDateTimeMaxValidator<F, E>` | `const BlocxDateTimeMaxValidator(DateTime max)` | `DateTime?` |
| **DateTime** | `BlocxDateTimeRangeValidator<F, E>` | `const BlocxDateTimeRangeValidator(DateTime min, DateTime max)` | `DateTime?` |
| **DateTime** | `BlocxDateTimeAfterFieldValidator<F, E>` | `const BlocxDateTimeAfterFieldValidator(E otherKey, String otherFieldName)` | `DateTime?` |
| **DateTime** | `BlocxDateTimeBeforeFieldValidator<F, E>` | `const BlocxDateTimeBeforeFieldValidator(E otherKey, String otherFieldName)` | `DateTime?` |
| **List** | `BlocxListRequiredValidator<F, E, T>` | `BlocxListRequiredValidator()` *(non-const)* | `List<T>?` |
| **List** | `BlocxListMinItemsValidator<F, E, T>` | `const BlocxListMinItemsValidator(int min)` | `List<T>?` |
| **List** | `BlocxListMaxItemsValidator<F, E, T>` | `const BlocxListMaxItemsValidator(int max)` | `List<T>?` |
| **List** | `BlocxListUniqueItemsValidator<F, E, T>` | `const BlocxListUniqueItemsValidator()` | `List<T>?` |
| **Phone** | `BlocxPhoneRequiredValidator<F, E>` | `BlocxPhoneRequiredValidator()` *(non-const)* | `String?` |
| **Phone** | `BlocxPhoneBasicFormatValidator<F, E>` | `BlocxPhoneBasicFormatValidator()` *(non-const)* | `String?` |
| **Phone** | `BlocxPhoneE164Validator<F, E>` | `BlocxPhoneE164Validator()` *(non-const)* | `String?` |
| **Phone** | `BlocxPhoneMinLengthValidator<F, E>` | `const BlocxPhoneMinLengthValidator(int min)` | `String?` |
| **Phone** | `BlocxPhoneMaxLengthValidator<F, E>` | `const BlocxPhoneMaxLengthValidator(int max)` | `String?` |
| **File** | `BlocxFileRequiredValidator<F, E>` | `BlocxFileRequiredValidator()` *(non-const)* | `BlocxFile?` |
| **File** | `BlocxFileMaxSizeValidator<F, E>` | `const BlocxFileMaxSizeValidator(int maxBytes)` | `BlocxFile?` |
| **Object** | `BlocxRequiredFieldValidator<F, E>` | `BlocxRequiredFieldValidator()` *(non-const)* | `Object?` |

---

## 7. All Optional Form Mixins

### 7.1 `BlocxUniqueFieldValidatorMixin<F, P, E>` (Async Uniqueness Validation)
Validates field uniqueness remotely when a field in `uniqueFieldKeys` is updated (and passes synchronous field validation first). Uses per-field request tokens to ignore stale responses and blocks form submission (`uniqueKeysBeingChecked.isNotEmpty`) while a check is in flight.

```dart
@override
List<ProfileFormField> get uniqueFieldKeys => const [ProfileFormField.username];

@override
BlocxUseCaseTask<dynamic, bool>? useCaseIsUniqueValueAvailable(
  ProfileFormEntity formData,
  ProfileFormField key,
  dynamic value,
) {
  if (key == ProfileFormField.username) {
    return BlocxUseCaseTask<String, bool>(
      useCase: checkUsernameUniqueUseCase, // returns true if available, false if taken
      inputBuilder: () => value as String,
    );
  }
  return null;
}

@override
Map<ProfileFormField, String> get unavailableFieldMessages => const {
  ProfileFormField.username: 'Username is already taken',
};
```

### 7.2 `BlocxFormPrefetchMixin<F, P, E>` (Parallel Reference Data Prefetch)
Executes auxiliary tasks in parallel when `BlocxFormEventInit` (or `BlocxFormEventPrefetchRequiredInfo`) is dispatched. Blocks submission while `fieldsFetchingInfo.isNotEmpty`.

```dart
@override
Map<ProfileFormField, BlocxUseCaseTask<Object?, Object?>> get requiredInitialInfoTasks => {
  ProfileFormField.country: BlocxUseCaseTask<void, List<CountryEntity>>(
    useCase: loadCountriesUseCase,
    inputBuilder: () => null,
  ),
};

@override
FutureOr<void> onInfoFetched(
  ProfileFormField key,
  dynamic data,
  Emitter<BlocxFormState<ProfileFormEntity, ProfileFormField>> emit,
) {
  // Optional hook called as each dataset resolves; results are also cached in `formRequiredInfo[key]`
}
```

### 7.3 `BlocxFormSteppedMixin<F, P, E>` (Multi-Step Wizard Navigation)
Adds step-by-step navigation to a form.
- **Required Override**: `int get maxStep;` (0-indexed maximum step).
- **Events**:
  - `BlocxFormEventNextStep()`
  - `BlocxFormEventPreviousStep()`
  - `BlocxFormEventGoToStep(int stepIndex)`
- **Hook**: `void onStepChanged(Emitter<BlocxFormState<F, E>> emit) {}`

### 7.4 `BlocxFormSyncStreamMixin<F, P, E, Entity extends BlocxBaseEntity>` (Real-Time EventHub Sync for Forms)
Note: Takes **4** type parameters `<F, P, E, Entity>` so a form backed by `F` (e.g. `ProfileFormEntity`) can watch domain entity events for `Entity` (e.g. `UserProfileEntity`) on `BlocxEventHub`.

```dart
class ProfileFormBloc extends BlocxFormBloc<ProfileFormEntity, UserProfileEntity, ProfileFormField>
    with BlocxFormSyncStreamMixin<ProfileFormEntity, UserProfileEntity, ProfileFormField, UserProfileEntity> {
  @override
  final BlocxEventHub eventHub;

  ProfileFormBloc({required this.eventHub, ...}) : super(const ProfileFormEntity());

  @override
  bool get popOnEntityDeleted => true;

  @override
  FutureOr<ProfileFormEntity?> mapSyncedEntityToFormData(
    UserProfileEntity entity,
    BlocxCommandType command,
  ) {
    return formData.copyWith(
      id: entity.id,
      username: entity.username,
      email: entity.email,
      age: entity.age,
    );
  }
}
```

- **Required Members**:
  - `BlocxEventHub get eventHub;` (must be initialized in constructor parameter list before `super(...)`).
  - `FutureOr<F?> mapSyncedEntityToFormData(Entity entity, BlocxCommandType command);` (by default returns `entity as F` if `entity is F`, otherwise `null`; override when `Entity` differs from `F`).
- **Optional Overrides & Flags**:
  - `List<BlocxCommandType> get listenedCommands` (returns `List<BlocxCommandType>`, defaults to `[create, read, update, delete]`)
  - `bool shouldSyncEntity(Entity entity, BlocxCommandType command)` (by default returns `true` when `formData.identifier.isEmpty` or `entity.identifier == formData.identifier`)
  - `bool get ignoreEventsWhileSubmitting => true;` (ignores incoming stream events while `state is BlocxFormStateSubmittingForm`)
  - `bool get popOnEntityDeleted => true;` (when `true`, automatically calls `pop()` inside `onWatchedEntityDeleted`)
  - `bool get applySyncedDataToControllers => true;` (when `true`, emits `BlocxFormStateApplyInitialDataToForm` before `BlocxFormStateLoaded`)
  - `bool get validateOnEntitySync => false;`
  - `@protected void onWatchedEntityDeleted(Entity entity)`
