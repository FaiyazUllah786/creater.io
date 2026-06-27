import 'package:jwt_decoder/jwt_decoder.dart';

/// Manages the in-memory access token for the application.
class TokenManager {
  TokenManager._();

  static String? _accessToken;

  /// Retrieves the current access token.
  static String? get accessToken => _accessToken;

  /// Sets the current access token.
  static Future<void> setAccessToken(String? token) async {
    _accessToken = token;
  }

  /// Clears the current access token from memory.
  static void clear() {
    _accessToken = null;
  }

  /// Checks if the current access token should be refreshed.
  /// Returns true if the token expires within the next 2 minutes.
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

  /// Checks if there is currently a valid, non-expired access token.
  static bool hasValidAccessToken() {
    if (_accessToken == null) {
      return false;
    }

    return !JwtDecoder.isExpired(
      _accessToken!,
    );
  }
}
