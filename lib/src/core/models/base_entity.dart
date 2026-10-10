/// The base contract for all entities used with blocx.
///
/// Every [BlocxBaseEntity] must expose a unique, constant [identifier].
/// This identifier is used by BlocX collection extensions, selection, deduplication,
/// and live stream sync to match entities across updates and deletions.
///
/// Note: [BlocxBaseEntity] does not override Dart's default [operator ==] or [hashCode]
/// so as not to interfere with custom value equality solutions (such as `equatable`
/// or `freezed`) or reference equality semantics. Subclasses may implement
/// [operator ==] and [hashCode] if value-based equality is desired.
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
/// class User extends BlocxBaseEntity {
///   final String id;
///   final String name;
///
///   const User({required this.id, required this.name});
///
///   @override
///   String get identifier => id;
/// }
///
/// final u1 = User(id: "abc123", name: "Alice");
/// final u2 = User(id: "abc123", name: "Alice Updated");
///
/// // Collections match and update items using `identifier`:
/// assert(u1.identifier == u2.identifier);
/// ```
abstract class BlocxBaseEntity {
  const BlocxBaseEntity();

  /// A globally unique and constant identifier for the entity.
  ///
  /// Used for identification, deduplication, and sync across BlocX collections.
  String get identifier;
}
