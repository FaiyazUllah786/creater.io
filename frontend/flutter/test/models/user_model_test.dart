import 'package:flutter_test/flutter_test.dart';
import 'package:creatorio/model/user_model.dart';

void main() {
  group('UserModel', () {
    test('fromMap() correctly parses valid JSON map', () {
      final map = {
        'userName': 'johndoe',
        'email': 'john@example.com',
        'profilePhoto': 'http://example.com/photo.jpg',
        'firstName': 'John',
        'lastName': 'Doe',
        'createdAt': '2023-01-01T00:00:00.000Z',
        'updatedAt': '2023-01-02T00:00:00.000Z',
        'authProvider': 'local',
        'githubId': null,
        'googleId': null,
      };

      final user = UserModel.fromMap(map);

      expect(user.userName, equals('johndoe'));
      expect(user.email, equals('john@example.com'));
      expect(user.profilePhoto, equals('http://example.com/photo.jpg'));
      expect(user.firstName, equals('John'));
      expect(user.lastName, equals('Doe'));
      expect(
          user.createdAt, equals(DateTime.parse('2023-01-01T00:00:00.000Z')));
      expect(
          user.updatedAt, equals(DateTime.parse('2023-01-02T00:00:00.000Z')));
      expect(user.authProvider, equals('local'));
      expect(user.githubId, isNull);
      expect(user.googleId, isNull);
    });

    test('toMap() correctly serializes object to map', () {
      final user = UserModel(
        userName: 'janedoe',
        email: 'jane@example.com',
        profilePhoto: null,
        firstName: null,
        lastName: null,
        createdAt: DateTime.parse('2023-05-01T00:00:00.000Z'),
        updatedAt: DateTime.parse('2023-05-01T00:00:00.000Z'),
        authProvider: 'google',
        githubId: null,
        googleId: 'google_123',
      );

      final map = user.toMap();

      expect(map['userName'], equals('janedoe'));
      expect(map['email'], equals('jane@example.com'));
      expect(map['profilePhoto'], isNull);
      expect(map['createdAt'], equals('2023-05-01T00:00:00.000Z'));
      expect(map['authProvider'], equals('google'));
      expect(map['googleId'], equals('google_123'));
    });
  });
}
