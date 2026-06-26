import 'package:jwt_decoder/jwt_decoder.dart';

class TokenManager {
  TokenManager._();

  static String? _accessToken;

  static String? get accessToken => _accessToken;

  static Future<void> setAccessToken(String? token) async {
    _accessToken = token;
  }

  static void clear() {
    _accessToken = null;
  }

  // Token expires within next 2 mins?
  static bool shouldRefreshToken() {
    if (_accessToken == null) {
      return false;
    }

    final expiryDate = JwtDecoder.getExpirationDate(
      _accessToken!,
    );

    final remainingTime = expiryDate.difference(DateTime.now());

    return remainingTime.inMinutes <= 2;
  }

  static bool hasValidAccessToken() {
    if (_accessToken == null) {
      return false;
    }

    return !JwtDecoder.isExpired(
      _accessToken!,
    );
  }
}
