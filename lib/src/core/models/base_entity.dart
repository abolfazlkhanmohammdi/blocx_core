abstract class BaseEntity {
  String get identifier;
  const BaseEntity();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BaseEntity && other.runtimeType == runtimeType && other.identifier == identifier;
  }

  @override
  int get hashCode => Object.hash(runtimeType, identifier);
}
