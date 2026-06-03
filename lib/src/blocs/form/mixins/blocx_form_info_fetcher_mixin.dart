import 'dart:async';
import 'dart:collection';

import 'package:bloc/bloc.dart';
import 'package:blocx_core/blocx_core.dart';
import 'package:blocx_core/form_bloc.dart'
    show BlocxFormBloc, BlocxFormEventFetchRequiredInfo, BlocxFormState;
import 'package:blocx_core/src/core/models/blocx_base_form_entity.dart';

/// Fetches and caches auxiliary form data required during form initialization.
///
/// This mixin is typically used for:
///
/// - dropdown options
/// - reference data
/// - prefilled form metadata
/// - server-driven configuration values
///
/// Type parameters:
///
/// - [F]: The form entity type.
/// - [P]: The form payload type.
/// - [E]: The enum key representing each required dataset.
mixin BlocxFormInfoFetcherMixin<F extends BlocxBaseFormEntity<F, E>, P, E extends Enum>
    on BlocxFormBloc<F, P, E> {
  /// Required initial data tasks indexed by enum key.
  ///
  /// Each task is executed during [BlocxFormEventFetchRequiredInfo].
  ///
  /// Different keys may return different output types, so consumers should use
  /// [BlocxUseCaseTask<Object?, Object?>] as the common task shape.
  Map<E, BlocxUseCaseTask<Object?, Object?>> get requiredInitialInfoTasks;

  /// Internal set tracking currently loading keys.
  final Set<E> _loading = <E>{};

  /// In-memory cache of resolved form-required data.
  final Map<E, dynamic> _formInfo = <E, dynamic>{};

  /// Registers the event handler for required info fetching.
  void initInfoFetcher() {
    on<BlocxFormEventFetchRequiredInfo>(_fetchRequiredInfo);
  }

  /// Immutable view of currently loading keys.
  Set<E> get dataFetchingFields => Set.unmodifiable(_loading);

  /// Immutable view of fetched form-required data.
  Map<E, dynamic> get formRequiredInfo => UnmodifiableMapView(_formInfo);

  /// Executes all required info tasks.
  ///
  /// Tasks are executed in parallel. Successful results are cached under their
  /// related enum key. Failed tasks are reported with a global form-data error.
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

    final futures = keys.map((key) {
      return tasks[key]!.execute();
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
  void clearFormRequiredInfo(Emitter<BlocxFormState<F, E>> emit) {
    if (_formInfo.isEmpty && _loading.isEmpty) return;

    _loading.clear();
    _formInfo.clear();

    emitState(emit);
  }

  /// Called after one dataset is successfully fetched.
  void onInfoFetched(E key, dynamic data) {}

  /// Current fields waiting for required info.
  @override
  Set<E> get fieldsFetchingInfo => _loading;
}
