import 'package:uuid/uuid.dart';

class BaseEntity {
  final String identifier = Uuid().v4();
  BaseEntity();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BaseEntity && other.runtimeType == runtimeType && other.identifier == identifier;
  }

  @override
  int get hashCode => Object.hash(runtimeType, identifier);
}
