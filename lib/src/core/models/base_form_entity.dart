import 'package:blocx_core/blocx_core.dart';
import 'package:meta/meta.dart';

/// A base class for immutable form entities used by the FormBloc system.
///
/// This class enforces a consistent way to update form fields using enum keys,
/// enabling generic form handling, validation, and UI updates. Subclasses must
/// implement both [updateByKey] and [getValueByKey] to define how individual
/// fields are stored and updated.
///
/// Type parameters:
/// - [F] is the concrete subclass type (F-bound polymorphism), allowing methods
///   like [updateByKey] to return a strongly typed instance.
/// - [E] is the enum type representing the unique keys of the form fields.
abstract class BaseFormEntity<F extends BaseFormEntity<F, E>, E extends Enum> extends BaseEntity {
  const BaseFormEntity();

  /// A safe version of [updateByKey] that performs a debug-mode consistency check.
  ///
  /// This method:
  /// 1. Calls the subclass's [updateByKey] implementation to produce a new
  ///    updated instance.
  /// 2. In debug mode (`assert` enabled), verifies that the updated instance
  ///    actually contains the expected value by calling [getValueByKey].
  ///
  /// If a mismatch is detected, an exception is thrown to warn developers that
  /// either `updateByKey` or `getValueByKey` is incorrectly implemented.
  ///
  /// In release mode, the assertion block is removed entirely, so no runtime
  /// overhead or validation occurs.
  @nonVirtual
  F updateByKeySafe(E key, dynamic value) {
    // Perform the actual update.
    final result = updateByKey(key, value);

    // Debug-only validation to ensure correctness of subclass implementations.
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

  /// Updates the field corresponding to the given [key] and returns a new
  /// instance of the form entity.
  ///
  /// Subclasses must implement this method using immutable update patterns
  /// (e.g., via `copyWith` or equivalent).
  F updateByKey(E key, value);

  /// Retrieves the value associated with the given field [key].
  ///
  /// This should return the exact field value stored in the entity instance.
  /// It is used by the form system for validation, UI updates, and the safety
  /// check inside [updateByKeySafe].
  getValueByKey(E key);
  getFormattedValueByKey(E key) {
    return null;
  }

  getFormattedValueIfNotNullOtherwiseValue(E key) {
    return getFormattedValueByKey(key) ?? getValueByKey(key);
  }
}
