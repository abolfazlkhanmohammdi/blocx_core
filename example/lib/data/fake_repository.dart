import 'package:blocx_example/list/users/models/user.dart';
import 'package:faker/faker.dart';
import 'package:uuid/uuid.dart';

class FakeRepository {
  final List<User> _generatedUsers = [];
  String get uuid => Uuid().v4();
  Faker faker = Faker();

  String get _uniqueUsername {
    var username = faker.internet.userName();
    int retries = 0;
    while (!_generatedUsers.any((e) => e.username == username) || retries == 5) {
      username = faker.internet.userName();
      retries++;
    }
    username = _generatedUsers.any((e) => e.username == username) ? uuid : username;
    return username;
  }

  Future<List<User>> getUsers(int rowCount, int offset) async {
    await _randomDelay();
    var users = List.generate(rowCount, (int index) {
      return _generateFakeUser();
    });
    return users;
  }

  User _generateFakeUser() {
    var username = _uniqueUsername;
    return User(
      name: faker.person.name(),
      username: username,
      age: faker.randomGenerator.integer(80, min: 20),
    );
  }

  Future<void> _randomDelay() async {
    final duration = Duration(seconds: faker.randomGenerator.integer(3, min: 1));
    await Future.delayed(duration);
  }
}
