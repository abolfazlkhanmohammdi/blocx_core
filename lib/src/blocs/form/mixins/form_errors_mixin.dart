import 'dart:collection';
import 'package:blocx_core/src/blocs/base/base_bloc.dart';
import 'package:blocx_core/src/blocs/form/bloc/form_bloc.dart';
import 'package:blocx_core/src/core/enum_error_codes.dart';

mixin FormErrorsMixin<F, P, E extends Enum> on BaseBloc<FormEvent, FormBlocState<F, E>> {
  final Map<E, Set<BlocXErrorCode>> _errors = <E, Set<BlocXErrorCode>>{};

  /// Returns true if the error map actually changed.
  bool setFieldError(E key, BlocXErrorCode code) {
    final set = _errors.putIfAbsent(key, () => <BlocXErrorCode>{});
    final changed = set.add(code);
    if (set.isEmpty) _errors.remove(key);
    return changed;
  }

  /// Returns true if something was removed.
  bool clearFieldError(E key, {BlocXErrorCode? errorCode}) {
    final set = _errors[key];
    if (set == null) return false;

    final changed = (errorCode == null) ? (_errors.remove(key) != null) : set.remove(errorCode);

    if (set.isEmpty) _errors.remove(key);
    return changed;
  }

  void clearAllErrors() => _errors.clear();

  bool hasError(E key, [BlocXErrorCode? code]) {
    final set = _errors[key];
    if (set == null) return false;
    return code == null ? set.isNotEmpty : set.contains(code);
  }

  /// Expose an unmodifiable snapshot to callers.
  Map<E, Set<BlocXErrorCode>> get errors =>
      UnmodifiableMapView(_errors.map((k, v) => MapEntry(k, UnmodifiableSetView(v))));
}
