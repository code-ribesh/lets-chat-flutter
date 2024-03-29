import 'package:chat/src/models/User.dart';
import 'package:chat/src/services/user/user_service_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rethinkdb_dart/rethinkdb_dart.dart';

import 'helper/helper.dart';

void main() {
  Rethinkdb r = Rethinkdb();
  Connection connection;
  UserService sut;

  setUp(() async {
    connection = await r.connect(host: "localhost", port: 28015);
    await createdDb(r, connection);
    sut = UserService(r, connection);
  });

  tearDown(() async {
    await cleanDb(r, connection);
  });

  test('create a new user document in database', () async {
    final user = User(
        username: 'test',
        photoUrl: 'url',
        active: true,
        lastseen: DateTime.now());
    final userWithId = await sut.connect(user);
    expect(userWithId.id, isNotEmpty);
  });

  test('get online users', () async {
    final user = User(
        username: 'test',
        photoUrl: 'url',
        active: true,
        lastseen: DateTime.now());

    // arrange
    await sut.connect(user);
    //act
    final users = await sut.online();
    // assert
    expect(users.length, 1);
  });
}
