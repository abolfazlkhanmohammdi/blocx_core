import 'dart:collection';
import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/form_bloc.dart'
    show BlocxFormEventFetchRequiredInfo, BlocxFormBloc, BlocxFormState;
import 'package:blocx_core/src/core/models/base_form_entity.dart';
import 'package:blocx_core/src/core/use_cases/blocx_use_case_task.dart';

/// Mixin responsible for fetching and caching auxiliary form data
/// required during form initialization.
///
/// This mixin coordinates execution of multiple [BlocxBaseUseCase] tasks
/// using [BlocxUseCaseTask], allowing each required dataset to define:
/// - its own use case
/// - its own runtime input builder
///
/// Responsibilities:
/// - Executes required info fetches in parallel
/// - Tracks loading state per key
/// - Stores resolved results in-memory for form usage
/// - Provides lifecycle hooks for downstream handling
///
/// This is typically used for:
/// - dropdown options
/// - reference data
/// - prefilled form metadata
/// - server-driven configuration values
///
/// Type Parameters:
/// - [F]: form entity type
/// - [P]: payload type used by the form
/// - [E]: enum key representing each required dataset
mixin BlocxInitialInfoFetcherFormMixin<F extends BaseFormEntity<F, E>, P, E extends Enum>
    on BlocxFormBloc<F, P, E> {
  /// Map of required initial data tasks indexed by enum key.
  ///
  /// Each entry defines:
  /// - a use case responsible for fetching data
  /// - an input builder executed at runtime
  ///
  /// This allows each dataset to be independently computed
  /// based on current bloc state.
  Map<E, BlocxUseCaseTask> get requiredInitialInfoTasks;

  /// Internal set tracking currently loading keys.
  final Set<E> _loading = <E>{};

  /// In-memory cache of resolved form-required data.
  ///
  /// Values are dynamic because different keys may return
  /// different result types.
  final Map<E, dynamic> _formInfo = <E, dynamic>{};

  /// Registers event handler for required info fetching.
  ///
  /// Must be called during bloc initialization.
  void initInfoFetcher() {
    on<BlocxFormEventFetchRequiredInfo>(_fetchRequiredInfo);
  }

  /// Returns immutable view of currently loading keys.
  Set<E> get dataFetchingFields => Set.unmodifiable(_loading);

  /// Returns immutable view of fetched form-required data.
  Map<E, dynamic> get formRequiredInfo => UnmodifiableMapView(_formInfo);

  /// Internal handler that executes all required info use cases.
  ///
  /// Execution model:
  /// - collects all tasks
  /// - marks all keys as loading
  /// - executes all use cases concurrently
  /// - stores successful results
  /// - reports failures globally
  ///
  /// This method guarantees:
  /// - parallel execution (Future.wait)
  /// - deterministic key-result mapping
  /// - partial failure tolerance
  Future<void> _fetchRequiredInfo(
    BlocxFormEventFetchRequiredInfo event,
    Emitter<BlocxFormState<F, E>> emit,
  ) async {
    final tasks = requiredInitialInfoTasks;

    if (tasks.isEmpty) {
      emitState(emit);
      return;
    }

    final keys = tasks.keys.toList(growable: false);

    _loading
      ..clear()
      ..addAll(keys);

    emitState(emit);

    final futures = keys.map((k) {
      final task = tasks[k]!;
      return task.useCase.execute(task.inputBuilder());
    }).toList();

    final results = await Future.wait(futures);

    _loading.clear();

    final failedKeys = <E>[];

    for (var i = 0; i < results.length; i++) {
      final key = keys[i];
      final result = results[i];

      if (result.isFailure) {
        failedKeys.add(key);
        continue;
      }

      _formInfo[key] = result.data;
      onInfoFetched(key, result.data);
    }

    emitState(emit);

    if (failedKeys.isNotEmpty) {
      displayErrorWidgetByErrorCode(BlocXErrorCode.errorGettingInitialFormData);
    }
  }

  /// Clears cached required info and resets loading state.
  ///
  /// Typically used when:
  /// - form is reset
  /// - form context changes
  /// - bloc is reinitialized
  void clearFormRequiredInfo(Emitter<BlocxFormState<F, E>> emit) {
    if (_formInfo.isEmpty && _loading.isEmpty) return;

    _loading.clear();
    _formInfo.clear();

    emitState(emit);
  }

  /// Hook invoked after each individual dataset is successfully fetched.
  ///
  /// Can be overridden to perform side effects such as:
  /// - transformation
  /// - logging
  /// - dependent state updates
  void onInfoFetched(E key, dynamic data) {}

  /// Exposes current loading keys to external consumers (e.g. UI).
  @override
  Set<E> get fieldsFetchingInfo => _loading;
}
