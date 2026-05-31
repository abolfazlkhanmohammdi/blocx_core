import 'package:blocx_core/blocx_core.dart';
import 'package:meta/meta.dart';

/// Base class for all immutable form entities used by [BlocxFormBloc].
///
/// Enforces a consistent enum-keyed update/read contract so the form system
/// can handle field updates, validation, and UI refresh generically —
/// without knowing the concrete field types at compile time.
///
/// ## Type parameters
///
/// - [F]: The concrete subclass (F-bound polymorphism). Ensures [updateByKey]
///   returns a strongly-typed instance rather than the base class.
/// - [E]: The enum whose values map 1-to-1 to form fields.
///
/// ## Required overrides
///
/// Only [updateByKey] is required. Implement it as an immutable field swap,
/// typically delegating to `copyWith`:
///
/// ```dart
/// @override
/// LoginForm updateByKey(LoginField key, dynamic value) => switch (key) {
///   LoginField.email    => copyWith(email: value),
///   LoginField.password => copyWith(password: value),
/// };
/// ```
///
/// ## Optional overrides
///
/// Override [getValueByKey] when the form system needs to read field values
/// back — e.g. for the debug-mode consistency check in [updateByKeySafe],
/// or for validation that inspects other fields:
///
/// ```dart
/// @override
/// dynamic getValueByKey(LoginField key) => switch (key) {
///   LoginField.email    => email,
///   LoginField.password => password,
/// };
/// ```
///
/// Override [getFormattedValueByKey] only when a field has a display
/// representation that differs from its stored value (e.g. a date formatted
/// as a locale string).
///
/// ## Equality
///
/// Equality is inherited from [BlocxBaseEntity] and is based solely on
/// [identifier]. Two form entity instances with the same [identifier] are
/// considered equal regardless of field values.
abstract class BlocxBaseFormEntity<F extends BlocxBaseFormEntity<F, E>, E extends Enum>
    extends BlocxBaseEntity {
  const BlocxBaseFormEntity();

  /// Updates the field identified by [key] and returns a new instance.
  ///
  /// Implement using an immutable update pattern such as `copyWith`:
  /// ```dart
  /// @override
  /// LoginForm updateByKey(LoginField key, dynamic value) => switch (key) {
  ///   LoginField.email    => copyWith(email: value),
  ///   LoginField.password => copyWith(password: value),
  /// };
  /// ```
  F updateByKey(E key, dynamic value);

  /// Returns the stored value for [key].
  ///
  /// Used by the debug-mode consistency check in [updateByKeySafe],
  /// cross-field validation, and UI display via
  /// [getFormattedValueIfNotNullOtherwiseValue].
  ///
  /// ```dart
  /// @override
  /// dynamic getValueByKey(LoginField key) => switch (key) {
  ///   LoginField.email    => email,
  ///   LoginField.password => password,
  /// };
  /// ```
  dynamic getValueByKey(E key);

  /// Returns a formatted display value for [key].
  ///
  /// Override when a field has a display representation that differs from its
  /// stored value (e.g. a [DateTime] formatted as a locale string). Return
  /// `null` to fall back to [getValueByKey] via
  /// [getFormattedValueIfNotNullOtherwiseValue].
  dynamic getFormattedValueByKey(E key) {
    return null;
  }

  /// Returns [getFormattedValueByKey] if non-null, otherwise [getValueByKey].
  ///
  /// Use this in UI code to get the best available display value for a field.
  dynamic getFormattedValueIfNotNullOtherwiseValue(E key) =>
      getFormattedValueByKey(key) ?? getValueByKey(key);

  /// Calls [updateByKey] and validates the result in debug mode.
  ///
  /// In debug builds, asserts that [getValueByKey] on the returned instance
  /// equals [value]. A mismatch means either [updateByKey] or [getValueByKey]
  /// is incorrectly implemented.
  ///
  /// In release builds the assertion is stripped — no runtime overhead.
  @nonVirtual
  F updateByKeySafe(E key, dynamic value) {
    final result = updateByKey(key, value);

    assert(() {
      final setValue = result.getValueByKey(key);
      if (setValue != value) {
        throw Exception(
          'Failed to update key $key with value $value.\n'
          'Either "updateByKey" or "getValueByKey" is incorrectly implemented '
          'in the subclass. Expected "$value" but got "$setValue".',
        );
      }
      return true;
    }());

    return result;
  }
}
