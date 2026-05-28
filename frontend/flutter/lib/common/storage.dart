import 'dart:convert';

import 'package:creatorio/model/user_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String refreshTokenKey = 'refreshToken';
  static const String accessTokenKey = 'accessToken';
  static const String userKey = 'user';

  static Future<void> saveRefreshToken(
    String token,
  ) async {
    await _storage.write(
      key: refreshTokenKey,
      value: token,
    );
  }

  static Future<void> saveAccessToken(
    String token,
  ) async {
    await _storage.write(
      key: accessTokenKey,
      value: token,
    );
  }

  static Future<String?> getRefreshToken() async {
    return _storage.read(
      key: refreshTokenKey,
    );
  }

  static Future<String?> getAccessToken() async {
    return _storage.read(
      key: accessTokenKey,
    );
  }

  static Future<void> saveUser(
    UserModel user,
  ) async {
    final userData = jsonEncode(user.toMap());
    await _storage.write(
      key: userKey,
      value: userData,
    );
  }

  static Future<UserModel?> loadUser() async {
    final data = await _storage.read(key: userKey);

    if (data == null) return null;

    return UserModel.fromMap(jsonDecode(data));
  }

  static Future<void> clear() async {
    await _storage.deleteAll();
  }
}
