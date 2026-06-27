import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:creatorio/core/network/token_manager.dart';

void main() {
  group('TokenManager', () {
    setUp(() {
      TokenManager.clear();
    });

    // Helper to generate a dummy JWT with a specific expiration
    String generateJwt(DateTime expiry) {
      final header = base64UrlEncode(utf8.encode('{"alg":"HS256","typ":"JWT"}'));
      final expirySecondsSinceEpoch = expiry.millisecondsSinceEpoch ~/ 1000;
      final payload = base64UrlEncode(utf8.encode('{"exp": $expirySecondsSinceEpoch}'));
      final signature = 'fake_signature';
      return '$header.$payload.$signature';
    }

    test('initial state has null access token', () {
      expect(TokenManager.accessToken, isNull);
      expect(TokenManager.hasValidAccessToken(), isFalse);
      expect(TokenManager.shouldRefreshToken(), isFalse);
    });

    test('clear() removes the access token', () async {
      await TokenManager.setAccessToken('dummy_token');
      expect(TokenManager.accessToken, equals('dummy_token'));
      TokenManager.clear();
      expect(TokenManager.accessToken, isNull);
    });

    test('hasValidAccessToken() returns true for future expiry', () async {
      final token = generateJwt(DateTime.now().add(const Duration(hours: 1)));
      await TokenManager.setAccessToken(token);
      expect(TokenManager.hasValidAccessToken(), isTrue);
    });

    test('hasValidAccessToken() returns false for past expiry', () async {
      final token = generateJwt(DateTime.now().subtract(const Duration(hours: 1)));
      await TokenManager.setAccessToken(token);
      expect(TokenManager.hasValidAccessToken(), isFalse);
    });

    test('shouldRefreshToken() returns true if expiry is within 2 minutes', () async {
      final token = generateJwt(DateTime.now().add(const Duration(minutes: 1)));
      await TokenManager.setAccessToken(token);
      expect(TokenManager.shouldRefreshToken(), isTrue);
    });

    test('shouldRefreshToken() returns false if expiry is > 2 minutes', () async {
      final token = generateJwt(DateTime.now().add(const Duration(minutes: 5)));
      await TokenManager.setAccessToken(token);
      expect(TokenManager.shouldRefreshToken(), isFalse);
    });
  });
}
