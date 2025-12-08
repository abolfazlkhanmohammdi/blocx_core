import 'dart:async';
import 'dart:collection';
import 'package:bloc/bloc.dart';
import 'package:blocx_core/src/blocs/base/base_bloc.dart';
import 'package:blocx_core/src/blocs/form/bloc/form_bloc.dart';
import 'package:blocx_core/src/core/models/base_form_entity.dart';

mixin FormErrorsMixin<F extends BaseFormEntity<F, E>, P, E extends Enum>
    on BaseBloc<FormEvent, FormBlocState<F, E>> {
  final Map<E, Set<String>> _errors = <E, Set<String>>{};

  void initErrors() {
    on<FormEventSetTimedErrorToField<E>>(setTimedErrorToField);
    on<FormEventSetErrorToField<E>>(setErrorToField);
    on<FormEventClearFieldError<E>>(clearFieldErrors);
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
    FormEventSetTimedErrorToField<E> event,
    Emitter<FormBlocState<F, E>> emit,
  ) async {
    setFieldError(event.key, event.message);
    emitState(emit);
    await Future.delayed(event.duration ?? Duration(seconds: 2));
    clearFieldError(event.key, errorMessage: event.message);
    emitState(emit);
  }

  void emitState(Emitter<FormBlocState<F, E>> emit);

  FutureOr<void> setErrorToField(FormEventSetErrorToField<E> event, Emitter<FormBlocState<F, E>> emit) {
    setFieldError(event.key, event.message);
    emitState(emit);
  }

  FutureOr<void> clearFieldErrors(FormEventClearFieldError<E> event, Emitter<FormBlocState<F, E>> emit) {
    event.clearAll ? clearFieldError(event.key) : clearFieldError(event.key, errorMessage: event.message!);
    emitState(emit);
  }
}
