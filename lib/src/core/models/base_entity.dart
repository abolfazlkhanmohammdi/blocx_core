/// The base contract for all entities used with blocx.
///
/// Every [BaseEntity] must expose a unique, constant [identifier].
/// This identifier is the **sole basis for equality and hashCode** comparisons,
/// meaning two entities of the same type are considered equal if they share
/// the same [identifier].
///
/// ### Identifier requirements:
/// - Must be **unique** within its entity type.
/// - Must be **constant/stable** across the entity’s lifecycle.
/// - Common choices:
///   - Remote UUIDs
///   - Database primary keys (stringified if needed)
///   - Usernames / emails (if immutable in your domain)
///
/// ### Example:
/// ```dart
/// class User extends BaseEntity {
///   final String id;
///   final String name;
///
///   @override
///   String get identifier => id;
///
///   const User({required this.id, required this.name});
/// }
///
/// final u1 = User(id: "abc123", name: "Alice");
/// final u2 = User(id: "abc123", name: "Alice Updated");
///
/// // Even though the `name` differs, equality is based only on `id`.
/// assert(u1 == u2);
/// ```
abstract class BaseEntity {
  const BaseEntity();

  /// A globally unique and constant identifier for the entity.
  ///
  /// Equality and [hashCode] depend solely on this field.
  String get identifier;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BaseEntity && other.runtimeType == runtimeType && other.identifier == identifier;
  }

  @override
  int get hashCode => Object.hash(runtimeType, identifier);
}
