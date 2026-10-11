# Graph Report - blocx_core  (2026-10-10)

## Corpus Check
- 168 files · ~58,456 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 4 file(s) not represented in the graph (top: (none) 4)

## Summary
- 1688 nodes · 3057 edges · 103 communities (94 shown, 9 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS · INFERRED: 1 edges (avg confidence: 0.85)
- Token cost: 18,500 input · 2,400 output

## Community Hubs (Navigation)
- Form State Hierarchy
- Infinite List Bloc & Events
- DI & Injectable Config Tests
- Collection Core Mixin
- BlocX Localizations Contract
- Localization Override Tests
- Entity Command Stream Sync Tests
- Form State Properties
- Testing Harness & Entities
- Collection Bloc Orchestrator
- Base Bloc & Error Policy
- Example Tasks Collection Bloc
- Collection Mutation Events
- Form Core Mixin Lifecycle
- Paginated Use Case Task
- Example Form & Notes Setup
- Cursor Paginated Use Cases
- Collection Selectable Mixin
- Form Errors & Timers Mixin
- Collection Bloc Unit Tests
- Form Sync Stream Mixin
- Collection Sync Stream Mixin
- Collection Infinite Pagination Mixin
- Screen Manager Cubit & States
- Field & List Validators
- Base Use Case Execution
- Collection Loaded State
- Form Lifecycle Events
- Cursor Refresh Tests
- Fake Use Case Helpers
- Stepped Form Mixin
- Architecture Docs & Skills
- Numeric Required Validators
- Form Validation Mode Tests
- Collection Expandable Mixin
- Form Unique Field Validator Mixin
- Collection State Extensions
- Form Prefetch Mixin
- Collection Filterable Mixin
- Collection Deletable Mixin
- Collection Searchable Mixin
- Form Validator Execution Mixin
- Integer & String Validators
- Collection Concurrency Race Tests
- Screen Manager State Classes
- Use Case Result Wrapper
- Collection Mixin Combination Tests
- Cursor & Offset Pagination Inputs
- DateTime & Numeric Validators
- Search Use Case Contract
- App & Entity Broadcast Events
- Collection Filter & Highlight Events
- Regex String Validators
- Base Entity Identity Model
- Base Form Entity Model
- Global Error Translator
- Collection Pagination Events
- Use Case Task Wrapper
- Form Test Fixtures
- Paginated Use Case Implementations
- File Size & Required Validators
- Use Case Broadcast Isolation Tests
- Base Form Validator Contract
- Internal Event Bus
- BlocxPage Pagination Model
- Collection State Classes
- Readable Error Model
- Test Suite Entrypoints
- Event Hub Mixin
- Collection List Replacement Events
- Event Hub Implementations
- Use Case Execution Tests
- Form Submit & Update Events
- Timed Error Message Model
- Collection Remove Item Events
- Selection Changed Data Model
- DateTime After Field Validator
- DateTime Before Field Validator
- DateTime Range Validator
- Double Range Validator
- Integer Less Than Validator
- Integer Range Validator
- Phone Basic Format Validator
- Phone E164 Format Validator
- String Length Range Validator
- String Match Validator
- Localization Provider
- Legacy Base Stub
- DateTime Max Validator
- DateTime Min Validator
- Double Max Validator
- Double Min Validator
- Integer Max Validator
- Integer Min Validator
- Phone Min Length Validator
- String Exact Length Validator
- Localization Implementations
- Design Principles & Release Notes
- Phone Required Validator

## God Nodes (most connected - your core abstractions)
1. `BlocxFieldValidator` - 44 edges
2. `BlocxCollectionEvent` - 33 edges
3. `BlocxCollectionBloc` - 32 edges
4. `TestItem` - 24 edges
5. `BlocxBaseUseCase` - 20 edges
6. `BlocxFormEvent` - 19 edges
7. `BlocxFormBloc` - 17 edges
8. `BlocxCollectionEventLoadInitialPage` - 16 edges
9. `BlocxCollectionInfiniteMixin` - 16 edges
10. `BlocxInfiniteListBloc` - 15 edges

## Surprising Connections (you probably didn't know these)
- `blocx_core Package Overview` --references--> `BlocX Core Official Package Logo`  [EXTRACTED]
  README.md → assets/pub/logo.png
- `TestFailureUseCase` --inherits--> `BlocxBaseUseCase`  [EXTRACTED]
  test/core/use_case_test.dart → lib/src/core/use_cases/blocx_base_use_case.dart
- `TestSuccessUseCase` --inherits--> `BlocxBaseUseCase`  [EXTRACTED]
  test/core/use_case_test.dart → lib/src/core/use_cases/blocx_base_use_case.dart
- `TestSubmitUseCase` --inherits--> `BlocxBaseUseCase`  [EXTRACTED]
  test/form/form_bloc_test.dart → lib/src/core/use_cases/blocx_base_use_case.dart
- `LoadTasksUseCase` --references--> `BlocxPaginatedInput`  [EXTRACTED]
  example/blocx_core_example.dart → lib/src/blocs/collection/use_cases/blocx_paginated_use_case.dart

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Unidirectional UseCase-to-BLoC EventHub Synchronization Architecture** — skills_blocx_core_skill_architecture_rules, skills_blocx_core_references_use_cases_and_event_hub_blocx_base_use_case, skills_blocx_core_references_collection_bloc_blocx_collection_bloc, skills_blocx_core_references_form_bloc_blocx_form_bloc [EXTRACTED 1.00]
- **BlocX Core 1.1.0 Release & CI Verification Suite** — pubspec_blocx_core_package, github_workflows_ci_workflow, analysis_options_lints_recommended, docs_release_report_v1_1_0, changelog_release_1_1_0 [EXTRACTED 1.00]

## Communities (103 total, 9 thin omitted)

### Community 0 - "Form State Hierarchy"
Cohesion: 0.07
Nodes (68): BlocxFormState, BlocxFormStateApplyInitialDataToForm, BlocxFormStateFormSubmitted, BlocxFormStateFormUpdated, BlocxFormStateInitial, BlocxFormStateLoaded, BlocxFormStateSubmittingForm, BlocxBaseBloc (+60 more)

### Community 1 - "Infinite List Bloc & Events"
Cohesion: 0.05
Nodes (62): BlocxInfiniteListEvent, BlocxInfiniteListEventChangeLoadBottomDataStatus, BlocxInfiniteListEventChangeLoadTopDataStatus, BlocxInfiniteListEventCloseRefresh, BlocxInfiniteListEventOnScroll, BlocxInfiniteListEventSetReachedEnd, BlocxInfiniteListEventVerticalDragEnded, BlocxInfiniteListEventVerticalDragStarted (+54 more)

### Community 2 - "DI & Injectable Config Tests"
Cohesion: 0.04
Nodes (53): areYouSure, areYouSureYouWantToDeleteThisItem, cancel, close, copyDetails, copyWith, dateRangeError, delete (+45 more)

### Community 3 - "Collection Core Mixin"
Cohesion: 0.04
Nodes (48): addItem, additionalInfo, _applyInitialPage, applyInitialSelection, beingRemovedItemIds, beingSelectedItemIds, clearList, cursorPaginationTask (+40 more)

### Community 5 - "BlocX Localizations Contract"
Cohesion: 0.04
Nodes (48): areYouSure, areYouSureYouWantToDeleteThisItem, cancel, close, copyDetails, dateRangeError, _default, delete (+40 more)

### Community 6 - "Localization Override Tests"
Cohesion: 0.04
Nodes (45): areYouSure, areYouSureYouWantToDeleteThisItem, cancel, close, copyDetails, dateRangeError, delete, deleteItem (+37 more)

### Community 7 - "Entity Command Stream Sync Tests"
Cohesion: 0.08
Nodes (35): BlocxBaseUseCase, BulkDeleteNotesUseCase, completer, CreateNoteUseCase, customCommands, customInsertMissingOnRead, customUpdateExistingOnCreate, DeleteNoteUseCase (+27 more)

### Community 8 - "Form State Properties"
Cohesion: 0.08
Nodes (33): allErrors, buttonText, checkingUniqueFields, errorByKey, errors, isFetchingFieldInfo, isFormValid, isValid (+25 more)

### Community 9 - "Testing Harness & Entities"
Cohesion: 0.06
Nodes (32): BlocxBaseFormEntity, BlocxBaseEntity, BlocxTestFormEntity, BlocxTestFormField, clearRecordedEvents, completer, copyWith, createTestEntities (+24 more)

### Community 11 - "Collection Bloc Orchestrator"
Cohesion: 0.06
Nodes (29): close, beingRemovedItemIds, beingSelectedItemIds, expandedItemIds, highlightedItemIds, selectedItemIds, DataInsertSource, hasFilters (+21 more)

### Community 12 - "Base Bloc & Error Policy"
Cohesion: 0.07
Nodes (22): BlocxBaseEvent, shouldListen, shouldRebuild, clearError, close, defaultError, displayErrorSnackbar, displayErrorWidget (+14 more)

### Community 13 - "Example Tasks Collection Bloc"
Cohesion: 0.20
Nodes (26): TasksCollectionBloc, BlocxCollectionBloc, BlocxCollectionDeletableMixin, BlocxCollectionExpandableMixin, BlocxCollectionFilterMixin, BlocxCollectionHighlightableMixin, BlocxCollectionInfiniteMixin, BlocxCollectionRefreshableMixin (+18 more)

### Community 14 - "Collection Mutation Events"
Cohesion: 0.15
Nodes (25): BlocxCollectionEvent, BlocxCollectionEventUpdateItem, BlocxCollectionEventRemoveItemById, BlocxCollectionEventRemoveMultipleItems, BlocxCollectionEventCollapseItem, BlocxCollectionEventExpandItem, BlocxCollectionEventToggleItemExpansion, item (+17 more)

### Community 15 - "Form Core Mixin Lifecycle"
Cohesion: 0.07
Nodes (27): applyPayloadToFormData, checkIsFieldValid, checkIsFormValid, doBeforeSubmit, emitChangesOnUpdate, emitState, errorDisplayPolicy, formData (+19 more)

### Community 16 - "Paginated Use Case Task"
Cohesion: 0.09
Nodes (18): BlocxPaginatedUseCaseTask, eventHub, main, paginationTask, paginatedUseCase, paginationTask, searchUseCase, searchUseCaseTask (+10 more)

### Community 17 - "Example Form & Notes Setup"
Cohesion: 0.10
Nodes (27): close, copyWith, eventHub, formBloc, formKeys, formKeysList, formValidationMode, getValidatorsByKey (+19 more)

### Community 18 - "Cursor Paginated Use Cases"
Cohesion: 0.12
Nodes (21): BlocxCursorPaginatedInput, BlocxCursorPaginatedUseCase, FakeCursorPaginatedUseCase, CallbackCursorUseCase, CursorCollectionBloc, CursorCollectionBlocWithLimit, cursorPaginationTask, CursorTestItem (+13 more)

### Community 19 - "Collection Selectable Mixin"
Cohesion: 0.08
Nodes (24): applyInitialSelection, _beingSelectedItemIds, beingSelectedItemIdsOriginal, clearSelection, deselectItem, deselectItemTask, deselectMultipleItems, emitSelectionChanged (+16 more)

### Community 20 - "Form Errors & Timers Mixin"
Cohesion: 0.08
Nodes (22): _cancelFieldTimers, clearAllErrors, clearFieldError, clearFieldErrors, clearTimers, emitState, Enum, ErrorMutationSource (+14 more)

### Community 21 - "Collection Bloc Unit Tests"
Cohesion: 0.09
Nodes (17): BlocxTestEntity, id, identifier, limit, paginationTask, perform, TestEntity, title (+9 more)

### Community 22 - "Form Sync Stream Mixin"
Cohesion: 0.09
Nodes (19): applySyncedDataToControllers, BlocxBaseEntity, closeStreams, _entityEventSub, eventHub, _handleEntityCommandEvent, ignoreEventsWhileSubmitting, initStreams (+11 more)

### Community 23 - "Collection Sync Stream Mixin"
Cohesion: 0.10
Nodes (20): closeStreams, _createSub, _deleteSub, _entityEventSub, eventHub, getInsertIndexForItem, _handleEntityCommandEvent, initStreams (+12 more)

### Community 24 - "Collection Infinite Pagination Mixin"
Cohesion: 0.13
Nodes (9): initInfiniteList, loadNextPage, loadNextPageCursorTask, loadNextPageTask, initRefresh, refreshPageCursorTask, refreshPageUseCaseTask, refreshThreshold (+1 more)

### Community 25 - "Screen Manager Cubit & States"
Cohesion: 0.14
Nodes (14): error, errorCode, message, snackbarType, stackTrace, title, BlocXSnackbarType, clearError (+6 more)

### Community 26 - "Field & List Validators"
Cohesion: 0.13
Nodes (12): T, validate, max, T, validate, min, T, validate (+4 more)

### Community 27 - "Base Use Case Execution"
Cohesion: 0.11
Nodes (12): _broadcastCommandEventsIfNeeded, _commandType, _commandTypes, _eventHub, eventOrigin, failureResult, handleBroadcastError, handleError (+4 more)

### Community 28 - "Collection Loaded State"
Cohesion: 0.11
Nodes (17): additionalInfo, copyWith, hasReachedEnd, index, isEmpty, isLoadingNextPage, isRefreshing, isSearching (+9 more)

### Community 29 - "Form Lifecycle Events"
Cohesion: 0.15
Nodes (17): applyToControllers, BlocxFormEvent, BlocxFormEventClearFieldError, BlocxFormEventInit, BlocxFormEventSetErrorToField, BlocxFormEventSetTimedErrorToField, BlocxFormEventSyncFormData, BlocxFormEventUpdateFormData (+9 more)

### Community 30 - "Cursor Refresh Tests"
Cohesion: 0.11
Nodes (16): cursorPaginationTask, cursorUseCase, extends, failureError, handleError, id, identifier, lastHandledError (+8 more)

### Community 31 - "Fake Use Case Helpers"
Cohesion: 0.11
Nodes (12): completer, delay, failureError, FakePaginatedSource, FakeSimpleUseCase, getPage, items, perform (+4 more)

### Community 32 - "Stepped Form Mixin"
Cohesion: 0.12
Nodes (15): BlocxFormEventGoToStep, BlocxFormEventNextStep, BlocxFormEventPreviousStep, stepIndex, comesFromPreviousStep, Enum, goToStep, initStepped (+7 more)

### Community 33 - "Architecture Docs & Skills"
Cohesion: 0.13
Nodes (14): Dart Lints Recommended Configuration, BlocX Core Official Package Logo, BlocX Core v1.0.0 Release Notes, BlocX Core v1.1.0 Release Notes, BlocX Core 1.1.0 Release Report & Quality Gates, GitHub Actions CI & Publish Workflow, blocx_core Pubspec Manifest (v1.1.0), blocx_core Package Overview (+6 more)

### Community 34 - "Numeric Required Validators"
Cohesion: 0.12
Nodes (11): Enum, validate, Enum, validate, Enum, validate, Enum, max (+3 more)

### Community 36 - "Form Validation Mode Tests"
Cohesion: 0.12
Nodes (15): email, formKeys, formKeysList, formValidationMode, getValidatorsByKey, getValueByKey, identifier, password (+7 more)

### Community 37 - "Collection Expandable Mixin"
Cohesion: 0.12
Nodes (14): collapseItem, _expandedItemIds, expandedItemIdsOriginal, expandItem, initExpandable, toggleItemExpansion, autoClearHighlight, clearHighlightedItem (+6 more)

### Community 38 - "Form Unique Field Validator Mixin"
Cohesion: 0.12
Nodes (12): BlocxFormEventCheckUniqueValue, data, key, _checkUniqueValue, Enum, _inFlightTokenByField, initUniqueFieldChecker, unavailableFieldMessages (+4 more)

### Community 39 - "Collection State Extensions"
Cohesion: 0.12
Nodes (15): firstSelectedItemOrNull, hasSelection, indexOfId, isBeingRemoved, isBeingRemovedId, isBeingSelected, isBeingSelectedId, isBusy (+7 more)

### Community 40 - "Form Prefetch Mixin"
Cohesion: 0.12
Nodes (12): BlocxFormEventPrefetchRequiredInfo, clearFormRequiredInfo, dataFetchingFields, Enum, _fetchRequiredInfo, fieldsFetchingInfo, _formInfo, formRequiredInfo (+4 more)

### Community 41 - "Collection Filterable Mixin"
Cohesion: 0.14
Nodes (8): getFilter, initFilters, setFilter, highlightScrolledToItems, initScrollable, scrollToIdentifier, scrollToItem, _toBeHighlightedItems

### Community 42 - "Collection Deletable Mixin"
Cohesion: 0.13
Nodes (13): _beingRemovedItemIds, _deleteItem, deleteItemTask, deleteMultipleItemsTask, displayDeletedSnackbar, _executeTask, initDeletable, onItemDeleted (+5 more)

### Community 43 - "Collection Searchable Mixin"
Cohesion: 0.14
Nodes (13): BlocxCollectionEventClearSearch, BlocxCollectionEventSearchNextPage, searchText, _clearSearch, _fetchSearchRefreshResult, initSearch, _search, searchDebounceDuration (+5 more)

### Community 44 - "Form Validator Execution Mixin"
Cohesion: 0.13
Nodes (14): _applyFieldValidationErrors, _applyFullFormValidationErrors, checkIsFieldValid, checkIsFormValid, Enum, fieldErrorDuration, formKeysList, FormValidationMode (+6 more)

### Community 45 - "Integer & String Validators"
Cohesion: 0.13
Nodes (10): Enum, otherKey, validate, Enum, validate, Enum, min, validate (+2 more)

### Community 46 - "Collection Concurrency Race Tests"
Cohesion: 0.13
Nodes (14): calls, completer, completeSuccess, ControlledCall, ControlledSearchCall, input, limit, _nextCallCompleter (+6 more)

### Community 47 - "Screen Manager State Classes"
Cohesion: 0.33
Nodes (11): BlocxBaseState, ScreenManagerCubitState, ScreenManagerCubitStateDisplayErrorPage, ScreenManagerCubitStateDisplayErrorPageByErrorCode, ScreenManagerCubitStateDisplaySnackbar, ScreenManagerCubitStateDisplaySnackbarByErrorCode, ScreenManagerCubitStateInitial, ScreenManagerCubitStatePop (+3 more)

### Community 48 - "Use Case Result Wrapper"
Cohesion: 0.16
Nodes (8): BlocxUseCaseFailure, BlocxUseCaseResult, BlocxUseCaseSuccess, data, error, isFailure, isSuccess, stackTrace

### Community 49 - "Collection Mixin Combination Tests"
Cohesion: 0.14
Nodes (11): deletedItems, deleteItemTask, deleteUseCase, eventHub, FakeDeleteUseCase, limit, paginatedUseCase, paginationTask (+3 more)

### Community 50 - "Cursor & Offset Pagination Inputs"
Cohesion: 0.15
Nodes (11): Filter, BlocxBaseEntity, cursor, filter, limit, successResult, BlocxBaseEntity, filter (+3 more)

### Community 51 - "DateTime & Numeric Validators"
Cohesion: 0.14
Nodes (9): Enum, validate, Enum, validate, Enum, validate, Enum, max (+1 more)

### Community 52 - "Search Use Case Contract"
Cohesion: 0.22
Nodes (9): BlocxBaseEntity, BlocxSearchInput, BlocxSearchUseCase, searchText, FakeSearchUseCase, FakeUseCase, ControlledSearchUseCase, FakeSearchOffsetUseCase (+1 more)

### Community 53 - "App & Entity Broadcast Events"
Cohesion: 0.15
Nodes (11): BlocxCommandType, BlocxEventOrigin, command, createdAt, debugTrace, entities, entity, feature (+3 more)

### Community 54 - "Collection Filter & Highlight Events"
Cohesion: 0.19
Nodes (7): BlocxCollectionEventFilter, filter, clearSelection, highlightItem, identifier, index, item

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
Cohesion: 0.20
Nodes (6): BlocxErrorTranslator, errorTranslator, _instance, makeErrorReadable, setInstance, CustomTranslator

### Community 59 - "Collection Pagination Events"
Cohesion: 0.47
Nodes (10): BlocxCollectionEventLoadInitialPage, BlocxCollectionEventLoadNextPage, BlocxCollectionEventRefreshData, BlocxCollectionEventSearch, main, main, main, main (+2 more)

### Community 60 - "Use Case Task Wrapper"
Cohesion: 0.20
Nodes (5): BlocxBaseEntity, BlocxUseCaseTask, execute, inputBuilder, useCase

### Community 61 - "Form Test Fixtures"
Cohesion: 0.31
Nodes (8): TestFormBloc, TestFormEntity, TestFormField, EmailValidator, PasswordValidator, TestField, TestFormEntity, TestFormValidator

### Community 62 - "Paginated Use Case Implementations"
Cohesion: 0.33
Nodes (8): BlocxPaginatedInput, BlocxPaginatedUseCase, FakePaginatedUseCase, TestPaginatedUseCase, ControlledPaginatedUseCase, TestCollectionBloc, FakePaginatedUseCase, FetchNotesPageUseCase

### Community 63 - "File Size & Required Validators"
Cohesion: 0.22
Nodes (6): Enum, _format, maxBytes, validate, Enum, validate

### Community 64 - "Use Case Broadcast Isolation Tests"
Cohesion: 0.22
Nodes (7): capturedBroadcastError, capturedBroadcastStackTrace, handleBroadcastError, main, perform, resolveCommandEntities, ThrowingBroadcastUseCase

### Community 65 - "Base Form Validator Contract"
Cohesion: 0.29
Nodes (5): Enum, formKeys, getValidatorsByKey, validateField, validateForm

### Community 66 - "Internal Event Bus"
Cohesion: 0.25
Nodes (4): _controller, dispose, emit, stream

### Community 67 - "BlocxPage Pagination Model"
Cohesion: 0.25
Nodes (6): BlocxPage, _hasNext, items, limit, nextCursor, offset

### Community 68 - "Collection State Classes"
Cohesion: 0.36
Nodes (8): BlocxCollectionState, BlocxCollectionStateError, BlocxCollectionStateLoaded, BlocxCollectionStateLoading, BlocxCollectionStateScrollToItem, BlocxCollectionStateSelectionChanged, ListStateExtensions, BlocxCollectionCoreMixin

### Community 69 - "Readable Error Model"
Cohesion: 0.25
Nodes (6): copyWith, error, message, ReadableError, stackTrace, title

### Community 71 - "Event Hub Mixin"
Cohesion: 0.33
Nodes (3): BlocxEventHubMixin, eventHub, systemEvents

### Community 72 - "Collection List Replacement Events"
Cohesion: 0.33
Nodes (5): BlocxCollectionEventRemoveFromList, BlocxCollectionEventReplaceList, newItems, payload, item

### Community 73 - "Event Hub Implementations"
Cohesion: 0.60
Nodes (5): BlocxAppEvent, BlocxEntityEvent, BlocxEventHub, BlocxSimpleEventHub, BlocxTestEventHub

### Community 74 - "Use Case Execution Tests"
Cohesion: 0.33
Nodes (4): main, perform, TestFailureUseCase, TestSuccessUseCase

### Community 75 - "Form Submit & Update Events"
Cohesion: 0.50
Nodes (5): BlocxFormEventSubmit, BlocxFormEventUpdateData, main, main, main

### Community 76 - "Timed Error Message Model"
Cohesion: 0.40
Nodes (3): duration, error, TimedErrorMessage

### Community 77 - "Collection Remove Item Events"
Cohesion: 0.40
Nodes (4): BlocxCollectionEventRemoveItem, identifier, item, items

### Community 78 - "Selection Changed Data Model"
Cohesion: 0.40
Nodes (4): item, selection, SelectionChangedData, wasSelected

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

### Community 88 - "String Match Validator"
Cohesion: 0.40
Nodes (4): Enum, errorMessage, otherKey, validate

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

### Community 96 - "Integer Min Validator"
Cohesion: 0.50
Nodes (3): Enum, min, validate

### Community 97 - "Phone Min Length Validator"
Cohesion: 0.50
Nodes (3): Enum, min, validate

### Community 98 - "String Exact Length Validator"
Cohesion: 0.50
Nodes (3): Enum, length, validate

### Community 99 - "Localization Implementations"
Cohesion: 0.50
Nodes (4): BlocXLocalizations, _DefaultLocalizations, CustomLocalizations, _CustomSearchLocalizations

## Knowledge Gaps
- **924 isolated node(s):** `id`, `title`, `isCompleted`, `identifier`, `eventHub` (+919 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1081 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **9 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `BlocxPaginatedUseCaseTask` connect `Paginated Use Case Task` to `DI & Injectable Config Tests`, `Collection Core Mixin`, `Entity Command Stream Sync Tests`, `Collection Searchable Mixin`, `Collection Concurrency Race Tests`, `Collection Mixin Combination Tests`, `Collection Bloc Unit Tests`, `Collection Infinite Pagination Mixin`, `Use Case Task Wrapper`, `Cursor Refresh Tests`?**
  _High betweenness centrality (0.010) - this node is a cross-community bridge._
- **What connects `id`, `title`, `isCompleted` to the rest of the system?**
  _924 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Form State Hierarchy` be split into smaller, more focused modules?**
  _Cohesion score 0.06848425835767608 - nodes in this community are weakly interconnected._
- **Why does `BlocxCollectionBloc` connect `Example Tasks Collection Bloc` to `Form State Hierarchy`, `Collection State Classes`, `Collection Bloc Orchestrator`, `Collection Mutation Events`, `Cursor Paginated Use Cases`, `Paginated Use Case Implementations`?**
  _High betweenness centrality (0.007) - this node is a cross-community bridge._
- **Should `Infinite List Bloc & Events` be split into smaller, more focused modules?**
  _Cohesion score 0.05179982440737489 - nodes in this community are weakly interconnected._
- **Why does `BlocxEventHub` connect `Event Hub Implementations` to `Internal Event Bus`, `Entity Command Stream Sync Tests`, `Example Tasks Collection Bloc`, `Paginated Use Case Task`, `Example Form & Notes Setup`, `Collection Mixin Combination Tests`, `Base Use Case Execution`?**
  _High betweenness centrality (0.007) - this node is a cross-community bridge._
- **Should `DI & Injectable Config Tests` be split into smaller, more focused modules?**
  _Cohesion score 0.03636363636363636 - nodes in this community are weakly interconnected._