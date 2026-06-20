import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lightweight mock that mirrors the exact `_isAuthFailure(...)` logic from
/// both `AuthInterceptor` and `AuthService`.
///
/// This avoids instantiating the real interceptor (which depends on
/// MethodChannel, navigatorKey, SecureStorage, and a full Dio instance).
///
/// Production auth contract:
///   Logout ONLY when there is strong evidence credentials are invalid.
///
///   401 (Unauthorized) → logout   (token revoked / expired / deleted user)
///   403 (Forbidden)    → logout   (account banned / permissions revoked)
///   FormatException    → logout   (local token corruption)
///
///   400 (Bad Request)  → preserve (malformed request — not proof of bad creds)
///   404 (Not Found)    → preserve (infrastructure / deployment issue)
///   408 (Timeout)      → preserve (request timeout — transient)
///   429 (Rate Limited) → preserve (rate limited — transient)
///   5xx (Server Error) → preserve (server error — transient)
///   Network errors     → preserve (offline / DNS / socket — transient)
///   Timeouts           → preserve (connection / send / receive — transient)
class AuthFailureEvaluator {
  static bool isAuthFailure(dynamic e) {
    if (e is DioException) {
      if (e.type == DioExceptionType.badResponse) {
        final statusCode = e.response?.statusCode ?? 0;
        return statusCode == 401 || statusCode == 403;
      }
      return false;
    }
    return true;
  }
}

DioException _makeBadResponse(int statusCode) {
  return DioException(
    requestOptions: RequestOptions(path: '/user/auth/refresh-tokens'),
    type: DioExceptionType.badResponse,
    response: Response(
      requestOptions: RequestOptions(path: '/user/auth/refresh-tokens'),
      statusCode: statusCode,
    ),
  );
}

DioException _makeDioError(DioExceptionType type) {
  return DioException(
    requestOptions: RequestOptions(path: '/user/auth/refresh-tokens'),
    type: type,
  );
}

void main() {
  group('Issue 16: Production Auth Contract (_isAuthFailure)', () {
    // ── Transient failures: credentials are NOT proven invalid ──

    test('1. Socket/network failure → should NOT logout', () {
      expect(
        AuthFailureEvaluator.isAuthFailure(
          _makeDioError(DioExceptionType.connectionError),
        ),
        isFalse,
      );
    });

    test('2. Connection timeout → should NOT logout', () {
      expect(
        AuthFailureEvaluator.isAuthFailure(
          _makeDioError(DioExceptionType.connectionTimeout),
        ),
        isFalse,
      );
    });

    test('3. Receive timeout → should NOT logout', () {
      expect(
        AuthFailureEvaluator.isAuthFailure(
          _makeDioError(DioExceptionType.receiveTimeout),
        ),
        isFalse,
      );
    });

    test('4. Send timeout → should NOT logout', () {
      expect(
        AuthFailureEvaluator.isAuthFailure(
          _makeDioError(DioExceptionType.sendTimeout),
        ),
        isFalse,
      );
    });

    test('5. HTTP 500 → should NOT logout', () {
      expect(
        AuthFailureEvaluator.isAuthFailure(_makeBadResponse(500)),
        isFalse,
      );
    });

    test('6. HTTP 429 → should NOT logout', () {
      expect(
        AuthFailureEvaluator.isAuthFailure(_makeBadResponse(429)),
        isFalse,
      );
    });

    test('7. HTTP 408 → should NOT logout', () {
      expect(
        AuthFailureEvaluator.isAuthFailure(_makeBadResponse(408)),
        isFalse,
      );
    });

    test('8. HTTP 404 → should NOT logout', () {
      expect(
        AuthFailureEvaluator.isAuthFailure(_makeBadResponse(404)),
        isFalse,
      );
    });

    test('9. HTTP 400 → should NOT logout', () {
      expect(
        AuthFailureEvaluator.isAuthFailure(_makeBadResponse(400)),
        isFalse,
      );
    });

    // ── Credential failures: strong evidence credentials are invalid ──

    test('10. HTTP 401 → SHOULD logout', () {
      expect(
        AuthFailureEvaluator.isAuthFailure(_makeBadResponse(401)),
        isTrue,
      );
    });

    test('11. HTTP 403 → SHOULD logout', () {
      expect(
        AuthFailureEvaluator.isAuthFailure(_makeBadResponse(403)),
        isTrue,
      );
    });

    test('12. FormatException → SHOULD logout', () {
      expect(
        AuthFailureEvaluator.isAuthFailure(
          const FormatException('Invalid token format'),
        ),
        isTrue,
      );
    });
  });
}
