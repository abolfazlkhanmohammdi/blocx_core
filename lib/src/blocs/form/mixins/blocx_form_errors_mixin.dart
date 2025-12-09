import 'dart:async';
import 'dart:collection';
import 'package:bloc/bloc.dart';
import 'package:blocx_core/src/blocs/base/base_bloc.dart';
import 'package:blocx_core/src/blocs/form/bloc/blocx_form_bloc.dart';
import 'package:blocx_core/src/core/models/base_form_entity.dart';

mixin BlocxFormErrorsMixin<F extends BaseFormEntity<F, E>, P, E extends Enum>
    on BaseBloc<BlocxFormEvent, BlocxFormState<F, E>> {
  final Map<E, Set<String>> _errors = <E, Set<String>>{};

  void initErrors() {
    on<BlocxFormEventSetTimedErrorToField<E>>(setTimedErrorToField);
    on<BlocxFormEventSetErrorToField<E>>(setErrorToField);
    on<BlocxFormEventClearFieldError<E>>(clearFieldErrors);
  }

  /// Returns true if the error map actually changed.
  bool setFieldError(E key, String error) {
    final set = _errors.putIfAbsent(key, () => <String>{});
    final changed = set.add(error);
    if (set.isEmpty) _errors.remove(key);
    return changed;
  }

  void setFieldErrorsBulk(E key, List<String> error) {
    final set = _errors.putIfAbsent(key, () => <String>{});
    set.addAll(error);
    if (set.isEmpty) _errors.remove(key);
  }

  /// Returns true if something was removed.
  bool clearFieldError(E key, {String? errorMessage}) {
    final set = _errors[key];
    if (set == null) return false;

    final changed = (errorMessage == null) ? (_errors.remove(key) != null) : set.remove(errorMessage);

    if (set.isEmpty) _errors.remove(key);
    return changed;
  }

  void clearAllErrors() => _errors.clear();

  bool hasError(E key, [String? code]) {
    final set = _errors[key];
    if (set == null) return false;
    return code == null ? set.isNotEmpty : set.contains(code);
  }

  /// Expose an unmodifiable snapshot to callers.
  Map<E, Set<String>> get errors =>
      UnmodifiableMapView(_errors.map((k, v) => MapEntry(k, UnmodifiableSetView(v))));

  Future<void> setTimedErrorToField(
    BlocxFormEventSetTimedErrorToField<E> event,
    Emitter<BlocxFormState<F, E>> emit,
  ) async {
    setFieldError(event.key, event.message);
    emitState(emit);
    await Future.delayed(event.duration ?? Duration(seconds: 2));
    clearFieldError(event.key, errorMessage: event.message);
    emitState(emit);
  }

  void emitState(Emitter<BlocxFormState<F, E>> emit);

  FutureOr<void> setErrorToField(BlocxFormEventSetErrorToField<E> event, Emitter<BlocxFormState<F, E>> emit) {
    setFieldError(event.key, event.message);
    emitState(emit);
  }

  FutureOr<void> clearFieldErrors(BlocxFormEventClearFieldError<E> event, Emitter<BlocxFormState<F, E>> emit) {
    event.clearAll ? clearFieldError(event.key) : clearFieldError(event.key, errorMessage: event.message!);
    emitState(emit);
  }
}
