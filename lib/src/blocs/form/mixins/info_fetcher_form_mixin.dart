import 'dart:collection';
import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:blocx_core/blocx_core.dart';

mixin InfoFetcherFormMixin<F, P, E extends Enum> on FormBloc<F, P, E> {
  /// Declare the initial info use cases once per bloc.
  Map<E, BaseUseCase<dynamic>> get requiredInitialInfoUseCases;

  // Loading flags per key.
  final Set<E> _loading = <E>{};

  // Collected info (values can be different types per key).
  final Map<E, dynamic> _formInfo = <E, dynamic>{};

  void initInfoFetcher() {
    // Cancel any in-flight fetch and keep only the latest.
    on<FormEventFetchRequiredInfo>(_fetchRequiredInfo);
  }

  Set<E> get dataFetchingFields => Set.unmodifiable(_loading);

  Map<E, dynamic> get formRequiredInfo => UnmodifiableMapView(_formInfo);

  Future<void> _fetchRequiredInfo(FormEventFetchRequiredInfo event, Emitter<FormBlocState<F, E>> emit) async {
    final cases = requiredInitialInfoUseCases;
    if (cases.isEmpty) {
      // Nothing to load; still emit so UI can settle.
      emitState(emit);
      return;
    }

    final keys = cases.keys.toList(growable: false);

    // Mark all as loading and notify UI.
    _loading
      ..clear()
      ..addAll(keys);
    emitState(emit);

    // Fire all requests concurrently.
    final futures = keys.map((k) => cases[k]!.execute()).toList(growable: false);
    final results = await Future.wait(futures);

    _loading.clear();

    // Apply successes; track failures.
    final failedKeys = <E>[];
    for (var i = 0; i < results.length; i++) {
      final r = results[i];
      final k = keys[i];
      if (r.isFailure) {
        failedKeys.add(k);
        continue;
      }
      _formInfo[k] = r.data;
    }

    emitState(emit);

    // Surface a global snackbar on any failure (and consider per-key UI if needed).
    if (failedKeys.isNotEmpty) {
      displayErrorWidgetByErrorCode(BlocXErrorCode.errorGettingInitialFormData);
    }
  }

  /// Optional helper to clear cached info (e.g., on form reset).
  void clearFormRequiredInfo(Emitter<FormBlocState<F, E>> emit) {
    if (_formInfo.isEmpty && _loading.isEmpty) return;
    _loading.clear();
    _formInfo.clear();
    emitState(emit);
  }
}
