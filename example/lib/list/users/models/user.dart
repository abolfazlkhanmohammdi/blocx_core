import 'package:blocx/blocx.dart';

class User extends ListEntity<User> {
  final String name;
  final String username;
  final int age;

  User({
    required this.name,
    required this.username,
    required this.age,
    super.isBeingRemoved,
    super.isBeingSelected,
    super.isHighlighted,
    super.isSelected,
  });
  @override
  User copyWith({
    bool? isSelected,
    bool? isBeingSelected,
    bool? isBeingRemoved,
    bool? isHighlighted,
    // you may add your classes fields too
    String? name,
    String? username,
    int? age,
  }) {
    return User(
      name: name ?? this.name,
      username: username ?? this.username,
      age: age ?? this.age,
      isHighlighted: isHighlighted ?? this.isHighlighted,
      isBeingRemoved: isBeingRemoved ?? this.isBeingRemoved,
      isSelected: isSelected ?? this.isSelected,
      isBeingSelected: isBeingSelected ?? this.isBeingSelected,
    );
  }

  @override
  String get identifier => username;
}
