import 'dart:collection';
import 'package:blocx_core/src/blocs/base/base_bloc.dart';
import 'package:blocx_core/src/blocs/form/bloc/form_bloc.dart';

mixin FormErrorsMixin<F, P, E extends Enum> on BaseBloc<FormEvent, FormBlocState<F, E>> {
  final Map<E, Set<String>> _errors = <E, Set<String>>{};

  /// Returns true if the error map actually changed.
  bool setFieldError(E key, String error) {
    final set = _errors.putIfAbsent(key, () => <String>{});
    final changed = set.add(error);
    if (set.isEmpty) _errors.remove(key);
    return changed;
  }

  /// Returns true if something was removed.
  bool clearFieldError(E key, {String? errorCode}) {
    final set = _errors[key];
    if (set == null) return false;

    final changed = (errorCode == null) ? (_errors.remove(key) != null) : set.remove(errorCode);

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
}
