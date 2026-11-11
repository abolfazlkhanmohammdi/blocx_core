# Graph Report - blocx_core  (2026-11-11)

## Corpus Check
- 177 files · ~71,145 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 4 file(s) not represented in the graph (top: (none) 4)

## Summary
- 2199 nodes · 3851 edges · 129 communities (118 shown, 11 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS · INFERRED: 1 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Form State Hierarchy
- blocx_infinite_list_bloc.dart
- DI & Injectable Config Tests
- Collection Core Mixin
- BlocX Localizations Contract
- Localization Override Tests
- Entity Command Stream Sync Tests
- Form State Properties
- testing.dart
- Collection Bloc Orchestrator
- Base Bloc & Error Policy
- Example Tasks Collection Bloc
- Collection Mutation Events
- Form Core Mixin Lifecycle
- package:test/test.dart
- Example Form & Notes Setup
- Cursor Paginated Use Cases
- Collection Selectable Mixin
- Form Errors & Timers Mixin
- BlocxBaseEntity
- Form Sync Stream Mixin
- Collection Sync Stream Mixin
- infinite/mixin.dart
- Screen Manager Cubit & States
- Field & List Validators
- Base Use Case Execution
- blocx_collection_state.dart
- Changelog
- Cursor Refresh Tests
- Fake Use Case Helpers
- Stepped Form Mixin
- Dart Lints Recommended Configuration
- E extends
- Form Validation Mode Tests
- Collection Expandable Mixin
- Form Unique Field Validator Mixin
- lis_state_extension.dart
- Form Prefetch Mixin
- scroll_to/mixin.dart
- Collection Deletable Mixin
- package:blocx_core/blocx_core.dart
- Form Validator Execution Mixin
- blocx_integer_greater_than_field_validator.dart
- Collection Concurrency Race Tests
- ScreenManagerCubitState
- Use Case Result Wrapper
- form_readiness_state_test.dart
- Cursor & Offset Pagination Inputs
- package:blocx_core/src/core/models/blocx_base_form_entity.dart
- TestItem
- App & Entity Broadcast Events
- README.md
- Regex String Validators
- Base Entity Identity Model
- Base Form Entity Model
- Global Error Translator
- BlocxCollectionEventLoadInitialPage
- Use Case Task Wrapper
- Form Test Fixtures
- collection_inline_error_retry_test.dart
- File Size & Required Validators
- report_error_test.dart
- Base Form Validator Contract
- Internal Event Bus
- BlocxPage Pagination Model
- BlocxCollectionCoreMixin
- Readable Error Model
- Test Suite Entrypoints
- Event Hub Mixin
- unique_field_null_task_test.dart
- BlocxFormBloc
- BlocxBaseUseCase
- blocx_form_event.dart
- Timed Error Message Model
- form_concurrency_test.dart
- List
- DateTime After Field Validator
- DateTime Before Field Validator
- DateTime Range Validator
- Double Range Validator
- Integer Less Than Validator
- Integer Range Validator
- Phone Basic Format Validator
- Phone E164 Format Validator
- String Length Range Validator
- blocx_infinite_list_bloc_event.dart
- UseCases, Tasks & EventHub Reference (`blocx_core`)
- Legacy Base Stub
- DateTime Max Validator
- DateTime Min Validator
- Double Max Validator
- Double Min Validator
- Integer Max Validator
- stepped_form_test.dart
- Phone Min Length Validator
- String Exact Length Validator
- Localization Implementations
- Form BLoC, Validation & Mixins Reference (`blocx_core`)
- collection_search_next_page_test.dart
- check_readme.dart
- collection_pagination_drift_test.dart
- 3. Tasks Completed
- 2. Six Non-Negotiable Architectural Rules
- blocx_infinite_list_bloc_state.dart
- package:blocx_core/src/core/localizations/loc_provider.dart
- Error Handling, ScreenManagerCubit, Localization & Testing (`blocx_core`)
- refresh/mixin.dart
- Collection BLoC & Mixins Reference (`blocx_core`)
- Architectural Notes & Critique Review (C8)
- 5. All 10 Collection Mixins (Complete Reference)
- class
- BlocxCursorPaginatedUseCase
- 1. Summary of Changes
- Release Report: blocx_core 1.2.1
- BlocxFormSteppedMixin
- 7. `BlocxEventHub`, `BlocxCommandType` & Entity Command Broadcasting
- blocx_file.dart
- 7. All Optional Form Mixins
- blocx_phone_max_length_validator.dart
- blocx_string_max_length_validator.dart
- blocx_string_min_length_validator.dart
- BlocxTestFormEntity
- BlocX Core Official Package Logo
- blocx_core Pubspec Manifest (v1.1.0)

## God Nodes (most connected - your core abstractions)
1. `BlocxFieldValidator` - 44 edges
2. `BlocxCollectionBloc` - 39 edges
3. `TestItem` - 39 edges
4. `BlocxCollectionEvent` - 34 edges
5. `BlocxBaseUseCase` - 26 edges
6. `BlocxFormBloc` - 21 edges
7. `BlocxCollectionEventLoadInitialPage` - 20 edges
8. `BlocxCollectionInfiniteMixin` - 20 edges
9. `BlocxFormEvent` - 20 edges
10. `BlocxPaginatedUseCaseTask` - 19 edges

## Surprising Connections (you probably didn't know these)
- `main` --calls--> `BlocxCollectionEventLoadInitialPage`  [EXTRACTED]
  test/core/report_error_test.dart → lib/src/blocs/collection/bloc/blocx_collection_event.dart
- `SaveTaskUseCase` --inherits--> `BlocxBaseUseCase`  [EXTRACTED]
  example/blocx_core_example.dart → lib/src/core/use_cases/blocx_base_use_case.dart
- `TaskFormEntity` --inherits--> `BlocxBaseFormEntity`  [EXTRACTED]
  example/blocx_core_example.dart → lib/src/core/models/blocx_base_form_entity.dart
- `TaskFormValidator` --inherits--> `BlocxFormValidator`  [EXTRACTED]
  example/blocx_core_example.dart → lib/src/blocs/form/validation/blocx_form_validator.dart
- `TaskFormBloc` --inherits--> `BlocxFormBloc`  [EXTRACTED]
  example/blocx_core_example.dart → lib/src/blocs/form/bloc/blocx_form_bloc.dart

## Import Cycles
- None detected.

## Communities (129 total, 11 thin omitted)

### Community 0 - "Form State Hierarchy"
Cohesion: 0.13
Nodes (42): BlocxFieldValidator, BlocxDateTimeAfterFieldValidator, BlocxDateTimeBeforeFieldValidator, BlocxDateTimeMaxValidator, BlocxDateTimeMinValidator, BlocxDateTimeRangeValidator, BlocxDateTimeRequiredValidator, BlocxDoubleMaxValueValidator (+34 more)

### Community 1 - "blocx_infinite_list_bloc.dart"
Cohesion: 0.08
Nodes (24): _changeLoadBottomDataStatus, _changeLoadTopDataStatus, _closeRefresh, _hasReachedEnd, _isAtBottom, _isAtTop, _isIdle, _isRefreshing (+16 more)

### Community 2 - "DI & Injectable Config Tests"
Cohesion: 0.04
Nodes (53): areYouSure, areYouSureYouWantToDeleteThisItem, cancel, close, copyDetails, copyWith, dateRangeError, delete (+45 more)

### Community 3 - "Collection Core Mixin"
Cohesion: 0.03
Nodes (61): activeFilter, activeFilters, activeSearchQuery, addItem, additionalInfo, adjustOffsetForLocalChanges, _applyInitialPage, applyInitialSelection (+53 more)

### Community 5 - "BlocX Localizations Contract"
Cohesion: 0.03
Nodes (55): areYouSure, areYouSureYouWantToDeleteThisItem, cancel, close, copyDetails, dateRangeError, _default, delete (+47 more)

### Community 6 - "Localization Override Tests"
Cohesion: 0.04
Nodes (48): areYouSure, areYouSureYouWantToDeleteThisItem, cancel, close, copyDetails, dateRangeError, delete, deleteItem (+40 more)

### Community 7 - "Entity Command Stream Sync Tests"
Cohesion: 0.08
Nodes (33): completer, CreateNoteUseCase, customCommands, customInsertMissingOnRead, customUpdateExistingOnCreate, DeleteNoteUseCase, eventHub, getValueByKey (+25 more)

### Community 8 - "Form State Properties"
Cohesion: 0.07
Nodes (39): allErrors, buttonText, canSubmit, checkingUniqueFields, errorByKey, errors, hasPendingUniqueChecks, initialData (+31 more)

### Community 9 - "testing.dart"
Cohesion: 0.03
Nodes (60): activeFilters, beingRemovedItemIds, beingSelectedItemIds, BlocxBaseEntity, BlocxCollectionStateSeeder, BlocxFormStateSeeder, checkingUniqueFields, clearRecordedEvents (+52 more)

### Community 11 - "Collection Bloc Orchestrator"
Cohesion: 0.06
Nodes (32): newItems, payload, close, beingRemovedItemIds, beingSelectedItemIds, expandedItemIds, highlightedItemIds, selectedItemIds (+24 more)

### Community 12 - "Base Bloc & Error Policy"
Cohesion: 0.06
Nodes (26): BlocxBaseEvent, shouldListen, shouldRebuild, clearError, close, defaultError, displayErrorSnackbar, displayErrorWidget (+18 more)

### Community 13 - "Example Tasks Collection Bloc"
Cohesion: 0.15
Nodes (32): TasksCollectionBloc, BlocxCollectionBloc, BlocxCollectionDeletableMixin, BlocxCollectionExpandableMixin, BlocxCollectionFilterMixin, BlocxCollectionHighlightableMixin, BlocxCollectionInfiniteMixin, BlocxCollectionRefreshableMixin (+24 more)

### Community 14 - "Collection Mutation Events"
Cohesion: 0.18
Nodes (20): BlocxCollectionEvent, BlocxCollectionEventRemoveFromList, BlocxCollectionEventReplaceList, BlocxCollectionEventRetryLastLoad, BlocxCollectionEventUpdateItem, BlocxCollectionEventRemoveItemById, BlocxCollectionEventCollapseItem, BlocxCollectionEventExpandItem (+12 more)

### Community 15 - "Form Core Mixin Lifecycle"
Cohesion: 0.06
Nodes (33): applyPayloadToFormData, cancelPendingUniqueChecks, checkIsFieldValid, checkIsFormValid, clearAllErrors, doBeforeSubmit, emitChangesOnUpdate, emitState (+25 more)

### Community 16 - "package:test/test.dart"
Cohesion: 0.06
Nodes (28): BlocxPaginatedUseCaseTask, DedupTestCollectionBloc, eventHub, paginationTask, paginatedUseCase, paginationTask, searchUseCase, searchUseCaseTask (+20 more)

### Community 17 - "Example Form & Notes Setup"
Cohesion: 0.10
Nodes (25): close, copyWith, eventHub, formBloc, formKeys, formKeysList, formValidationMode, getValidatorsByKey (+17 more)

### Community 18 - "Cursor Paginated Use Cases"
Cohesion: 0.13
Nodes (11): cursorPaginationTask, cursorUseCase, _customLimit, extends, id, identifier, label, limit (+3 more)

### Community 19 - "Collection Selectable Mixin"
Cohesion: 0.08
Nodes (24): applyInitialSelection, _beingSelectedItemIds, beingSelectedItemIdsOriginal, clearSelection, deselectItem, deselectItemTask, deselectMultipleItems, emitSelectionChanged (+16 more)

### Community 20 - "Form Errors & Timers Mixin"
Cohesion: 0.08
Nodes (22): _cancelFieldTimers, clearAllErrors, clearFieldError, clearFieldErrors, clearTimers, emitState, Enum, ErrorMutationSource (+14 more)

### Community 21 - "BlocxBaseEntity"
Cohesion: 0.20
Nodes (8): TestEntity, RefreshCursorItem, TestEntity, AnotherTestEntity, identifier, key, main, OtherEntity

### Community 22 - "Form Sync Stream Mixin"
Cohesion: 0.09
Nodes (19): applySyncedDataToControllers, BlocxBaseEntity, closeStreams, _entityEventSub, eventHub, _handleEntityCommandEvent, ignoreEventsWhileSubmitting, initStreams (+11 more)

### Community 23 - "Collection Sync Stream Mixin"
Cohesion: 0.10
Nodes (20): closeStreams, _createSub, _deleteSub, _entityEventSub, eventHub, getInsertIndexForItem, _handleEntityCommandEvent, initStreams (+12 more)

### Community 24 - "infinite/mixin.dart"
Cohesion: 0.15
Nodes (10): BlocxInfiniteListEventChangeLoadBottomDataStatus, _addBlocxInfiniteListEvent, nextLoadGeneration, _fetchNextPage, _fetchNextPageWithCursor, initInfiniteList, loadNextPage, loadNextPageCursorTask (+2 more)

### Community 25 - "Screen Manager Cubit & States"
Cohesion: 0.14
Nodes (14): error, errorCode, message, snackbarType, stackTrace, title, BlocXSnackbarType, clearError (+6 more)

### Community 26 - "Field & List Validators"
Cohesion: 0.11
Nodes (14): data, key, T, validate, max, T, validate, min (+6 more)

### Community 27 - "Base Use Case Execution"
Cohesion: 0.11
Nodes (12): _broadcastCommandEventsIfNeeded, _commandType, _commandTypes, _eventHub, eventOrigin, failureResult, handleBroadcastError, handleError (+4 more)

### Community 28 - "blocx_collection_state.dart"
Cohesion: 0.07
Nodes (26): activeFilters, additionalInfo, copyWith, filter, hasFilter, hasInitialError, hasReachedEnd, index (+18 more)

### Community 29 - "Changelog"
Cohesion: 0.04
Nodes (48): [0.7.1] - prior release, [0.8.0], [0.8.1], [0.8.2], [0.8.3], [0.9.0], [1.0.0], [1.0.1] - 2026-10-09 (+40 more)

### Community 30 - "Cursor Refresh Tests"
Cohesion: 0.11
Nodes (16): cursorPaginationTask, cursorUseCase, extends, failureError, handleError, id, identifier, lastHandledError (+8 more)

### Community 31 - "Fake Use Case Helpers"
Cohesion: 0.12
Nodes (11): completer, delay, failureError, FakePaginatedSource, getPage, items, perform, performedInputs (+3 more)

### Community 32 - "Stepped Form Mixin"
Cohesion: 0.14
Nodes (11): comesFromPreviousStep, Enum, goToStep, initStepped, maxStep, nextStep, onStepChanged, previousStep (+3 more)

### Community 34 - "E extends"
Cohesion: 0.13
Nodes (10): Enum, validate, Enum, validate, Enum, validate, Enum, errorMessage (+2 more)

### Community 36 - "Form Validation Mode Tests"
Cohesion: 0.12
Nodes (15): email, formKeys, formKeysList, formValidationMode, getValidatorsByKey, getValueByKey, identifier, password (+7 more)

### Community 37 - "Collection Expandable Mixin"
Cohesion: 0.11
Nodes (14): collapseItem, _expandedItemIds, expandedItemIdsOriginal, expandItem, initExpandable, toggleItemExpansion, autoClearHighlight, clearHighlightedItem (+6 more)

### Community 38 - "Form Unique Field Validator Mixin"
Cohesion: 0.15
Nodes (10): cancelPendingUniqueChecks, _checkUniqueValue, Enum, _inFlightTokenByField, initUniqueFieldChecker, unavailableFieldMessages, unavailableFormDataMessage, uniqueFieldKeys (+2 more)

### Community 39 - "lis_state_extension.dart"
Cohesion: 0.12
Nodes (15): firstSelectedItemOrNull, hasSelection, indexOfId, isBeingRemoved, isBeingRemovedId, isBeingSelected, isBeingSelectedId, isBusy (+7 more)

### Community 40 - "Form Prefetch Mixin"
Cohesion: 0.14
Nodes (11): clearFormRequiredInfo, dataFetchingFields, Enum, _fetchRequiredInfo, fieldsFetchingInfo, _formInfo, formRequiredInfo, initInfoFetcher (+3 more)

### Community 41 - "scroll_to/mixin.dart"
Cohesion: 0.14
Nodes (12): BlocxCollectionEventHighlightScrolledToItems, BlocxCollectionEventScrollToIdentifier, BlocxCollectionEventScrollToItem, highlightItem, identifier, index, item, highlightScrolledToItems (+4 more)

### Community 42 - "Collection Deletable Mixin"
Cohesion: 0.10
Nodes (17): BlocxCollectionEventRemoveMultipleItems, identifier, item, items, _beingRemovedItemIds, _deleteItem, deleteItemTask, deleteMultipleItemsTask (+9 more)

### Community 43 - "package:blocx_core/blocx_core.dart"
Cohesion: 0.07
Nodes (23): BlocxCollectionEventFilter, filter, activeFilter, filterDebounceDuration, getFilter, initFilters, setFilter, clearSelection (+15 more)

### Community 44 - "Form Validator Execution Mixin"
Cohesion: 0.13
Nodes (14): _applyFieldValidationErrors, _applyFullFormValidationErrors, checkIsFieldValid, checkIsFormValid, Enum, fieldErrorDuration, formKeysList, FormValidationMode (+6 more)

### Community 45 - "blocx_integer_greater_than_field_validator.dart"
Cohesion: 0.50
Nodes (3): Enum, otherKey, validate

### Community 46 - "Collection Concurrency Race Tests"
Cohesion: 0.07
Nodes (24): calls, completer, completeSuccess, ControlledCall, ControlledSearchCall, input, limit, _nextCallCompleter (+16 more)

### Community 47 - "ScreenManagerCubitState"
Cohesion: 0.33
Nodes (11): BlocxBaseState, ScreenManagerCubitState, ScreenManagerCubitStateDisplayErrorPage, ScreenManagerCubitStateDisplayErrorPageByErrorCode, ScreenManagerCubitStateDisplaySnackbar, ScreenManagerCubitStateDisplaySnackbarByErrorCode, ScreenManagerCubitStateInitial, ScreenManagerCubitStatePop (+3 more)

### Community 48 - "Use Case Result Wrapper"
Cohesion: 0.16
Nodes (8): BlocxUseCaseFailure, BlocxUseCaseResult, BlocxUseCaseSuccess, data, error, isFailure, isSuccess, stackTrace

### Community 49 - "form_readiness_state_test.dart"
Cohesion: 0.06
Nodes (35): applyDefaultCountryOnPrefetch, applyPayloadToFormData, completer, copyWith, country, enablePrefetch, extends, formKeys (+27 more)

### Community 50 - "Cursor & Offset Pagination Inputs"
Cohesion: 0.12
Nodes (13): Filter, BlocxBaseEntity, cursor, filter, limit, successResult, BlocxBaseEntity, filter (+5 more)

### Community 51 - "package:blocx_core/src/core/models/blocx_base_form_entity.dart"
Cohesion: 0.14
Nodes (9): Enum, validate, Enum, validate, Enum, min, validate, Enum (+1 more)

### Community 52 - "TestItem"
Cohesion: 0.19
Nodes (19): LoadTasksUseCase, BlocxPaginatedInput, BlocxPaginatedUseCase, BlocxSearchInput, BlocxSearchUseCase, FakePaginatedUseCase, FakeSearchUseCase, FakeUseCase (+11 more)

### Community 53 - "App & Entity Broadcast Events"
Cohesion: 0.15
Nodes (11): BlocxCommandType, BlocxEventOrigin, command, createdAt, debugTrace, entities, entity, feature (+3 more)

### Community 54 - "README.md"
Cohesion: 0.06
Nodes (31): 1. Domain Entities (`BlocxBaseEntity`), 2. UseCases & Automatic `BlocxEventHub` Command Broadcasting, Architecture Overview, Barrel Imports, Before vs. After, Built-in Field Validators (`package:blocx_core/form_bloc.dart`), Collection BLoC, 📦 Collections & Paginated Lists (`package:blocx_core/collection_bloc.dart`) (+23 more)

### Community 55 - "Regex String Validators"
Cohesion: 0.15
Nodes (9): Enum, _regex, validate, Enum, _regex, validate, Enum, _regex (+1 more)

### Community 56 - "Base Entity Identity Model"
Cohesion: 0.18
Nodes (8): BlocxBaseEntity, identifier, copyWith, id, identifier, order, title, toString

### Community 57 - "Base Form Entity Model"
Cohesion: 0.20
Nodes (7): Enum, getFormattedValueByKey, getFormattedValueIfNotNullOtherwiseValue, getValueByKey, updateByKey, updateByKeySafe, execute

### Community 58 - "Global Error Translator"
Cohesion: 0.18
Nodes (7): BlocxErrorTranslator, errorTranslator, _instance, makeErrorReadable, setInstance, _TestErrorTranslator, CustomTranslator

### Community 59 - "BlocxCollectionEventLoadInitialPage"
Cohesion: 0.22
Nodes (22): BlocxCollectionEventLoadInitialPage, BlocxCollectionEventRemoveItem, BlocxCollectionEventLoadNextPage, BlocxCollectionEventRefreshData, BlocxCollectionEventAddItem, BlocxCollectionEventClearSearch, BlocxCollectionEventSearch, BlocxCollectionEventSelectItem (+14 more)

### Community 60 - "Use Case Task Wrapper"
Cohesion: 0.18
Nodes (6): BlocxBaseEntity, BlocxCursorPaginatedUseCaseTask, BlocxUseCaseTask, execute, inputBuilder, useCase

### Community 61 - "Form Test Fixtures"
Cohesion: 0.26
Nodes (10): BlocxBaseFormEntity, TestFormBloc, TestFormEntity, TestFormField, EmailValidator, PasswordValidator, TestFormEntity, TestFormValidator (+2 more)

### Community 62 - "collection_inline_error_retry_test.dart"
Cohesion: 0.08
Nodes (23): capturedFilters, capturedPayloads, category, cursorUseCase, _CustomFilter, failNextDelete, failNextSelect, failureError (+15 more)

### Community 63 - "File Size & Required Validators"
Cohesion: 0.22
Nodes (6): Enum, _format, maxBytes, validate, Enum, validate

### Community 64 - "report_error_test.dart"
Cohesion: 0.11
Nodes (16): main, _paginationTask, reportedErrors, reportedStackTraces, reportError, ReportingCollectionBloc, TestBaseBloc, _TestEvent (+8 more)

### Community 65 - "Base Form Validator Contract"
Cohesion: 0.29
Nodes (5): Enum, formKeys, getValidatorsByKey, validateField, validateForm

### Community 66 - "Internal Event Bus"
Cohesion: 0.19
Nodes (9): BlocxAppEvent, BlocxEntityEvent, BlocxEventHub, BlocxSimpleEventHub, _controller, dispose, emit, stream (+1 more)

### Community 67 - "BlocxPage Pagination Model"
Cohesion: 0.25
Nodes (6): BlocxPage, _hasNext, items, limit, nextCursor, offset

### Community 68 - "BlocxCollectionCoreMixin"
Cohesion: 0.24
Nodes (10): BlocxCollectionState, BlocxCollectionStateError, BlocxCollectionStateLoaded, BlocxCollectionStateLoading, BlocxCollectionStateScrollToItem, BlocxCollectionStateSelectionChanged, ListStateExtensions, BlocxCollectionCoreMixin (+2 more)

### Community 69 - "Readable Error Model"
Cohesion: 0.25
Nodes (6): copyWith, error, message, ReadableError, stackTrace, title

### Community 71 - "Event Hub Mixin"
Cohesion: 0.33
Nodes (3): BlocxEventHubMixin, eventHub, systemEvents

### Community 72 - "unique_field_null_task_test.dart"
Cohesion: 0.11
Nodes (20): BlocxFormEventCheckUniqueValue, BlocxFormValidator, DummyFormValidator, email, formKeys, formKeysList, getValidatorsByKey, getValueByKey (+12 more)

### Community 73 - "BlocxFormBloc"
Cohesion: 0.19
Nodes (18): BlocxFormState, BlocxFormStateApplyInitialDataToForm, BlocxFormStateFormSubmitted, BlocxFormStateFormUpdated, BlocxFormStateInitial, BlocxFormStateLoaded, BlocxFormStateSubmittingForm, BlocxBaseBloc (+10 more)

### Community 74 - "BlocxBaseUseCase"
Cohesion: 0.17
Nodes (11): BlocxBaseUseCase, main, perform, TestFailureUseCase, TestSuccessUseCase, TestSubmitUseCase, ControlledSubmitUseCase, _ControlledBoolUseCase (+3 more)

### Community 75 - "blocx_form_event.dart"
Cohesion: 0.12
Nodes (25): applyToControllers, BlocxFormEvent, BlocxFormEventClearFieldError, BlocxFormEventInit, BlocxFormEventReset, BlocxFormEventSetErrorToField, BlocxFormEventSetTimedErrorToField, BlocxFormEventSubmit (+17 more)

### Community 76 - "Timed Error Message Model"
Cohesion: 0.40
Nodes (3): duration, error, TimedErrorMessage

### Community 77 - "form_concurrency_test.dart"
Cohesion: 0.12
Nodes (20): applyPayloadToFormData, completer, ConcurrencyField, ConcurrencyFormBloc, ConcurrencyFormEntity, _DummyValidator, executeCount, formKeys (+12 more)

### Community 78 - "List"
Cohesion: 0.15
Nodes (10): item, selection, SelectionChangedData, wasSelected, indexById, ListEntityExtension, removeById, replaceItem (+2 more)

### Community 79 - "DateTime After Field Validator"
Cohesion: 0.40
Nodes (4): Enum, otherFieldName, otherKey, validate

### Community 80 - "DateTime Before Field Validator"
Cohesion: 0.40
Nodes (4): Enum, otherFieldName, otherKey, validate

### Community 81 - "DateTime Range Validator"
Cohesion: 0.40
Nodes (4): Enum, max, min, validate

### Community 82 - "Double Range Validator"
Cohesion: 0.40
Nodes (4): Enum, max, min, validate

### Community 83 - "Integer Less Than Validator"
Cohesion: 0.40
Nodes (4): Enum, otherFieldName, otherKey, validate

### Community 84 - "Integer Range Validator"
Cohesion: 0.40
Nodes (4): Enum, max, min, validate

### Community 85 - "Phone Basic Format Validator"
Cohesion: 0.40
Nodes (3): Enum, _phoneRegex, validate

### Community 86 - "Phone E164 Format Validator"
Cohesion: 0.40
Nodes (3): _e164, Enum, validate

### Community 87 - "String Length Range Validator"
Cohesion: 0.40
Nodes (4): Enum, max, min, validate

### Community 88 - "blocx_infinite_list_bloc_event.dart"
Cohesion: 0.18
Nodes (17): BlocxInfiniteListEvent, BlocxInfiniteListEventChangeLoadTopDataStatus, BlocxInfiniteListEventOnScroll, BlocxInfiniteListEventSetReachedEnd, BlocxInfiniteListEventVerticalDragEnded, BlocxInfiniteListEventVerticalDragStarted, BlocxInfiniteListEventVerticalDragUpdated, globalY (+9 more)

### Community 89 - "UseCases, Tasks & EventHub Reference (`blocx_core`)"
Cohesion: 0.11
Nodes (18): 1. `BlocxBaseEntity`, 2. `BlocxBaseUseCase<Input, Output>` (`perform` vs `execute`), 3. `BlocxUseCaseResult<Output>`, 4. `BlocxPaginatedUseCase`, `BlocxPaginatedInput` & `BlocxPage`, 5. `BlocxSearchUseCase` & `BlocxSearchInput`, 6. `BlocxUseCaseTask` & `BlocxPaginatedUseCaseTask`, 8. `BlocxEventHubMixin` (Listener-Only BLoC Mixin), `BlocxPage<Entity>` (+10 more)

### Community 91 - "DateTime Max Validator"
Cohesion: 0.50
Nodes (3): Enum, max, validate

### Community 92 - "DateTime Min Validator"
Cohesion: 0.50
Nodes (3): Enum, min, validate

### Community 93 - "Double Max Validator"
Cohesion: 0.50
Nodes (3): Enum, max, validate

### Community 94 - "Double Min Validator"
Cohesion: 0.50
Nodes (3): Enum, min, validate

### Community 95 - "Integer Max Validator"
Cohesion: 0.50
Nodes (3): Enum, max, validate

### Community 96 - "stepped_form_test.dart"
Cohesion: 0.12
Nodes (13): call, _DummyEmitter, email, getValueByKey, identifier, isDone, max, maxStep (+5 more)

### Community 97 - "Phone Min Length Validator"
Cohesion: 0.50
Nodes (3): Enum, min, validate

### Community 98 - "String Exact Length Validator"
Cohesion: 0.50
Nodes (3): Enum, length, validate

### Community 99 - "Localization Implementations"
Cohesion: 0.50
Nodes (4): BlocXLocalizations, _DefaultLocalizations, CustomLocalizations, _CustomSearchLocalizations

### Community 100 - "Form BLoC, Validation & Mixins Reference (`blocx_core`)"
Cohesion: 0.12
Nodes (16): 1. Define a `BlocxFormValidator<F, E>`, 1. Field Enum `E` & `BlocxBaseFormEntity<F, E>`, 2. `BlocxFormBloc<F, P, E>` & `BlocxFormCoreMixin`, 2. Mix `BlocxFormValidationMixin<F, P, E>` into `BlocxFormBloc<F, P, E>`, 3. Form Events & States, 4. `BlocxFormErrorsMixin` (Persistent & Timed Errors), 5. Validation (`BlocxFormValidationMixin`, `FormValidationMode`, `BlocxFormValidator`), 6. Complete Built-in Field Validators Table (+8 more)

### Community 101 - "collection_search_next_page_test.dart"
Cohesion: 0.13
Nodes (13): calls, completeFailure, completer, completeSuccess, ControlledSearchCall, input, limit, paginatedUseCase (+5 more)

### Community 103 - "check_readme.dart"
Cohesion: 0.13
Nodes (12): addDartFilesOf, allow, extraPackages, forbidden, idPattern, libSource, main, problems (+4 more)

### Community 104 - "collection_pagination_drift_test.dart"
Cohesion: 0.14
Nodes (11): _adjustOffset, adjustOffsetForLocalChanges, _comparator, eventHub, limit, paginatedUseCase, paginationTask, searchDebounceDuration (+3 more)

### Community 105 - "3. Tasks Completed"
Cohesion: 0.14
Nodes (13): 1. Executive Summary, 2. CI Root Cause Analysis & Resolution, 3. Tasks Completed, 4. Quality Gate Results Summary, BlocX Core 1.1.0 Release Report, Resolution, Root Cause, Task T1: CI Alignment & SDK Floor (+5 more)

### Community 106 - "2. Six Non-Negotiable Architectural Rules"
Cohesion: 0.14
Nodes (14): 1. Barrel Exports & Imports, 2. Six Non-Negotiable Architectural Rules, 3. Core Workflows & Code Blueprints, 4. Reference Manuals (Progressive Disclosure), `blocx_core` Comprehensive Architecture & Implementation Skill, Blueprint A: Domain Entity & UseCases with EventHub Broadcasting, Blueprint B: Full-Featured `BlocxCollectionBloc`, Blueprint C: Validated Edit `BlocxFormBloc` with Live Stream Sync (+6 more)

### Community 107 - "blocx_infinite_list_bloc_state.dart"
Cohesion: 0.19
Nodes (12): BlocxInfiniteListState, BlocxInfiniteListStateInitial, BlocxInfiniteListStateLoaded, BlocxInfiniteListStateRefresh, isLoadingMore, hasReachedEnd, isAtBottom, isAtTop (+4 more)

### Community 108 - "package:blocx_core/src/core/localizations/loc_provider.dart"
Cohesion: 0.15
Nodes (8): Enum, validate, Enum, validate, Enum, validate, Enum, validate

### Community 109 - "Error Handling, ScreenManagerCubit, Localization & Testing (`blocx_core`)"
Cohesion: 0.15
Nodes (12): 1. `BlocxBaseBloc` & `ScreenManagerCubit`, 2. `BlocxErrorTranslator`, `ReadableError` & `BlocXErrorCode`, 3. `BlocXLocalizations`, 4. Pure-Dart Unit Testing Patterns, `BlocXErrorCode`, Built-in Screen & Feedback Helpers on `BlocxBaseBloc`, Error Handling, ScreenManagerCubit, Localization & Testing (`blocx_core`), `ErrorDisplayPolicy` (+4 more)

### Community 110 - "refresh/mixin.dart"
Cohesion: 0.20
Nodes (8): BlocxInfiniteListEventCloseRefresh, _fetchRefreshPage, _fetchRefreshPageWithCursor, initRefresh, refreshPage, refreshPageCursorTask, refreshPageUseCaseTask, refreshThreshold

### Community 111 - "Collection BLoC & Mixins Reference (`blocx_core`)"
Cohesion: 0.17
Nodes (12): 1. `BlocxCollectionBloc<Entity, Payload>` Overview, 2. `BlocxCollectionCoreMixin` Properties, Tasks & Helpers, 3. Core Collection Events, 4. Collection States & `ListStateExtensions`, Collection BLoC & Mixins Reference (`blocx_core`), Computed Query, Filter & Error Helpers on `BlocxCollectionState<T>`, List Manipulation & Lifecycle Hooks, `ListStateExtensions<T>` on `BlocxCollectionState<T>` (+4 more)

### Community 112 - "Architectural Notes & Critique Review (C8)"
Cohesion: 0.18
Nodes (10): 1. `BlocxBaseEntity` Identity vs. Equality, 2. `resolveCommandEntities` Signature, 3. Collection Search Model, 4. Mixin Composition Architecture, Architectural Notes & Critique Review (C8), Baseline Results (T0.1) - 2026-10-09, `blocx_core` Baseline, BlocX Fix Notes (+2 more)

### Community 113 - "5. All 10 Collection Mixins (Complete Reference)"
Cohesion: 0.18
Nodes (11): 5.10 `BlocxCollectionSyncStreamMixin<T extends BlocxBaseEntity, P>` (Real-Time EventHub CRUD Sync), 5.1 `BlocxCollectionInfiniteMixin<Entity, Payload>` (Next-Page Pagination), 5.2 `BlocxCollectionRefreshableMixin<Entity, Payload>` (Pull-to-Refresh), 5.3 `BlocxCollectionSearchableMixin<Entity, Payload>` (Debounced Search & Search Pagination), 5.4 `BlocxCollectionSelectableMixin<Entity, Payload>` (Single/Multi Selection & Server Sync), 5.5 `BlocxCollectionDeletableMixin<Entity, Payload>` (Single & Bulk Deletion), 5.6 `BlocxCollectionHighlightableMixin<Entity, Payload>` (Temporary Item Highlight), 5.7 `BlocxCollectionExpandableMixin<Entity, Payload>` (Expand / Collapse Items) (+3 more)

### Community 114 - "class"
Cohesion: 0.22
Nodes (7): id, identifier, limit, paginationTask, perform, title, _useCase

### Community 115 - "BlocxCursorPaginatedUseCase"
Cohesion: 0.42
Nodes (9): BlocxCursorPaginatedInput, BlocxCursorPaginatedUseCase, FakeCursorPaginatedUseCase, FakeCursorPaginatedUseCase, CallbackCursorUseCase, CursorTestItem, FakeCursorUseCase, TestCursorUseCase (+1 more)

### Community 116 - "1. Summary of Changes"
Cohesion: 0.25
Nodes (7): 1. Summary of Changes, 2. Gate Verification, 3. Breaking Changes, CI/CD, Release Report: blocx_core 1.2.0, Round 1 Changes (F1 - F7), Round 2 Changes (C-A - C-H)

### Community 117 - "Release Report: blocx_core 1.2.1"
Cohesion: 0.25
Nodes (7): 1. Work Package Execution Status, 2. Quality Gate Verification, 3. README Corrections Applied (Beyond Basic Spec), 4. Owner Actions Required, Baseline (WP0):, Final Gate (WP7):, Release Report: blocx_core 1.2.1

### Community 118 - "BlocxFormSteppedMixin"
Cohesion: 0.39
Nodes (7): BlocxFormEventGoToStep, BlocxFormEventNextStep, BlocxFormEventPreviousStep, stepIndex, BlocxFormSteppedMixin, main, SteppedTestFormBloc

### Community 119 - "7. `BlocxEventHub`, `BlocxCommandType` & Entity Command Broadcasting"
Cohesion: 0.29
Nodes (7): 7. `BlocxEventHub`, `BlocxCommandType` & Entity Command Broadcasting, `BlocxCommandType`, `BlocxEntityEvent<T extends BlocxBaseEntity>`, `BlocxEventHub` & `BlocxSimpleEventHub` API, EventHub Performance & Metadata Guarantees:, Single-Command vs Multi-Command UseCases, Strict Architectural Boundary

### Community 120 - "blocx_file.dart"
Cohesion: 0.33
Nodes (5): BlocxFile, mimeType, name, path, sizeBytes

### Community 121 - "7. All Optional Form Mixins"
Cohesion: 0.40
Nodes (5): 7.1 `BlocxUniqueFieldValidatorMixin<F, P, E>` (Async Uniqueness Validation), 7.2 `BlocxFormPrefetchMixin<F, P, E>` (Parallel Reference Data Prefetch), 7.3 `BlocxFormSteppedMixin<F, P, E>` (Multi-Step Wizard Navigation), 7.4 `BlocxFormSyncStreamMixin<F, P, E, Entity extends BlocxBaseEntity>` (Real-Time EventHub Sync for Forms), 7. All Optional Form Mixins

### Community 122 - "blocx_phone_max_length_validator.dart"
Cohesion: 0.50
Nodes (3): Enum, max, validate

### Community 123 - "blocx_string_max_length_validator.dart"
Cohesion: 0.50
Nodes (3): Enum, max, validate

### Community 124 - "blocx_string_min_length_validator.dart"
Cohesion: 0.50
Nodes (3): Enum, min, validate

## Knowledge Gaps
- **1134 isolated node(s):** `id`, `title`, `isCompleted`, `identifier`, `eventHub` (+1129 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1453 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **11 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `BlocxFile` connect `blocx_file.dart` to `Form State Hierarchy`?**
  _High betweenness centrality (0.011) - this node is a cross-community bridge._
- **What connects `id`, `title`, `isCompleted` to the rest of the system?**
  _1134 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Form State Hierarchy` be split into smaller, more focused modules?**
  _Cohesion score 0.12657004830917876 - nodes in this community are weakly interconnected._
- **Why does `BlocxBaseBloc` connect `BlocxFormBloc` to `Form State Hierarchy`, `report_error_test.dart`, `BlocxCollectionCoreMixin`, `Event Hub Mixin`, `Base Bloc & Error Policy`, `Example Tasks Collection Bloc`, `blocx_infinite_list_bloc_event.dart`?**
  _High betweenness centrality (0.008) - this node is a cross-community bridge._
- **Should `blocx_infinite_list_bloc.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.07692307692307693 - nodes in this community are weakly interconnected._
- **Why does `BlocxCollectionBloc` connect `Example Tasks Collection Bloc` to `report_error_test.dart`, `BlocxCollectionCoreMixin`, `BlocxFormBloc`, `Collection Bloc Orchestrator`, `Collection Mutation Events`, `package:test/test.dart`?**
  _High betweenness centrality (0.007) - this node is a cross-community bridge._
- **Should `DI & Injectable Config Tests` be split into smaller, more focused modules?**
  _Cohesion score 0.03636363636363636 - nodes in this community are weakly interconnected._