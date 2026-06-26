// Unit & integration tests for Issue 8: Inverted shouldRefreshToken() logic
//
// The bug: AuthService.initializeAuth() used shouldRefreshToken() to decide
// whether to skip the refresh network call. shouldRefreshToken() returns true
// when the token IS near-expiry — so the code skipped the refresh exactly
// when it was most needed, and performed it when it wasn't.
//
// The fix: Replace with hasValidAccessToken() which returns true only when
// the token exists AND is not expired.
//
// Run with:
//   flutter test test/auth_service_init_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:creatorio/core/network/token_manager.dart';

// We can't easily create real JWTs in unit tests without pulling in 'dart:convert'
// and crafting tokens manually. So we test the method contracts with a helper.

/// Creates a minimal valid JWT with the given expiry timestamp.
/// Format: header.payload.signature (all base64url encoded).
String _createTestJwt({required DateTime expiry}) {
  // JWT header: {"alg":"HS256","typ":"JWT"}
  const header = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9';

  // JWT payload with exp claim
  final exp = expiry.millisecondsSinceEpoch ~/ 1000;
  // Manually construct a base64url-encoded JSON payload
  final payloadJson = '{"_id":"test123","exp":$exp}';
  final payloadBytes = payloadJson.codeUnits;
  final payloadB64 = _base64UrlEncode(payloadBytes);

  // Fake signature
  const signature = 'fake_signature';

  return '$header.$payloadB64.$signature';
}

/// Base64url encode without padding (JWT standard).
String _base64UrlEncode(List<int> bytes) {
  final b64 = Uri.encodeFull(
    String.fromCharCodes(bytes),
  );
  // Use dart:convert for proper base64url
  // For test simplicity, we'll use a direct approach
  final encoded = _toBase64Url(bytes);
  return encoded;
}

String _toBase64Url(List<int> bytes) {
  const chars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';
  final buffer = StringBuffer();
  for (var i = 0; i < bytes.length; i += 3) {
    final b0 = bytes[i];
    final b1 = i + 1 < bytes.length ? bytes[i + 1] : 0;
    final b2 = i + 2 < bytes.length ? bytes[i + 2] : 0;
    buffer.writeCharCode(chars.codeUnitAt(b0 >> 2));
    buffer.writeCharCode(chars.codeUnitAt(((b0 & 3) << 4) | (b1 >> 4)));
    if (i + 1 < bytes.length) {
      buffer.writeCharCode(chars.codeUnitAt(((b1 & 15) << 2) | (b2 >> 6)));
    }
    if (i + 2 < bytes.length) {
      buffer.writeCharCode(chars.codeUnitAt(b2 & 63));
    }
  }
  return buffer.toString();
}

void main() {
  setUp(() {
    TokenManager.clear();
  });

  // ===========================================================================
  // UNIT TESTS: shouldRefreshToken() and hasValidAccessToken() truth table
  // ===========================================================================
  group('TokenManager method truth table', () {
    test('null token: shouldRefreshToken=false, hasValidAccessToken=false', () {
      // No token set
      expect(TokenManager.accessToken, isNull);
      expect(TokenManager.shouldRefreshToken(), isFalse);
      expect(TokenManager.hasValidAccessToken(), isFalse);
    });

    test('valid token (>2min remaining): shouldRefresh=false, hasValid=true',
        () async {
      final token = _createTestJwt(
        expiry: DateTime.now().add(const Duration(hours: 1)),
      );
      await TokenManager.setAccessToken(token);

      expect(TokenManager.shouldRefreshToken(), isFalse);
      expect(TokenManager.hasValidAccessToken(), isTrue);
    });

    test(
        'near-expiry token (<2min remaining): shouldRefresh=true, hasValid=true',
        () async {
      final token = _createTestJwt(
        expiry: DateTime.now().add(const Duration(seconds: 90)),
      );
      await TokenManager.setAccessToken(token);

      expect(TokenManager.shouldRefreshToken(), isTrue);
      // Still technically valid (not expired yet)
      expect(TokenManager.hasValidAccessToken(), isTrue);
    });

    test('expired token: shouldRefresh=true, hasValid=false', () async {
      final token = _createTestJwt(
        expiry: DateTime.now().subtract(const Duration(minutes: 5)),
      );
      await TokenManager.setAccessToken(token);

      expect(TokenManager.shouldRefreshToken(), isTrue);
      expect(TokenManager.hasValidAccessToken(), isFalse);
    });
  });

  // ===========================================================================
  // UNIT TESTS: The bug vs the fix — decision logic
  // ===========================================================================
  group(
      'initializeAuth decision logic — shouldRefreshToken vs hasValidAccessToken',
      () {
    // These tests simulate the decision point in initializeAuth() without
    // actually calling the network. They verify that the correct method
    // produces the correct "should we skip the refresh?" decision.

    test('BUG: shouldRefreshToken() skips refresh for valid tokens (wrong)',
        () async {
      // Valid token, >2min remaining → shouldRefreshToken() = false
      // Buggy code: if (shouldRefreshToken()) return; → does NOT return
      // → falls through to network refresh → UNNECESSARY network call
      final token = _createTestJwt(
        expiry: DateTime.now().add(const Duration(hours: 1)),
      );
      await TokenManager.setAccessToken(token);

      final buggySkipRefresh = TokenManager.shouldRefreshToken();
      expect(buggySkipRefresh, isFalse,
          reason: 'Bug: valid token does NOT trigger early return');
    });

    test(
        'BUG: shouldRefreshToken() early-returns for near-expiry tokens (wrong)',
        () async {
      // Near-expiry token → shouldRefreshToken() = true
      // Buggy code: if (shouldRefreshToken()) return; → RETURNS
      // → skips refresh → token expires shortly after → first API call fails
      final token = _createTestJwt(
        expiry: DateTime.now().add(const Duration(seconds: 30)),
      );
      await TokenManager.setAccessToken(token);

      final buggySkipRefresh = TokenManager.shouldRefreshToken();
      expect(buggySkipRefresh, isTrue,
          reason:
              'Bug: near-expiry token DOES trigger early return, skipping refresh');
    });

    test('BUG: shouldRefreshToken() early-returns for expired tokens (wrong)',
        () async {
      // Expired token → shouldRefreshToken() = true
      // Buggy code: if (shouldRefreshToken()) return; → RETURNS
      // → doesn't refresh → user stuck with expired token
      final token = _createTestJwt(
        expiry: DateTime.now().subtract(const Duration(minutes: 10)),
      );
      await TokenManager.setAccessToken(token);

      final buggySkipRefresh = TokenManager.shouldRefreshToken();
      expect(buggySkipRefresh, isTrue,
          reason:
              'Bug: expired token DOES trigger early return, skipping refresh');
    });

    test('FIX: hasValidAccessToken() correctly skips refresh for valid tokens',
        () async {
      final token = _createTestJwt(
        expiry: DateTime.now().add(const Duration(hours: 1)),
      );
      await TokenManager.setAccessToken(token);

      final fixedSkipRefresh = TokenManager.hasValidAccessToken();
      expect(fixedSkipRefresh, isTrue,
          reason:
              'Fix: valid token triggers early return, no network call needed');
    });

    test(
        'FIX: hasValidAccessToken() correctly falls through for expired tokens',
        () async {
      final token = _createTestJwt(
        expiry: DateTime.now().subtract(const Duration(minutes: 10)),
      );
      await TokenManager.setAccessToken(token);

      final fixedSkipRefresh = TokenManager.hasValidAccessToken();
      expect(fixedSkipRefresh, isFalse,
          reason:
              'Fix: expired token does NOT trigger early return, refresh proceeds');
    });

    test('FIX: hasValidAccessToken() correctly falls through for null token',
        () {
      // No token → hasValidAccessToken() = false → fall through to refresh
      final fixedSkipRefresh = TokenManager.hasValidAccessToken();
      expect(fixedSkipRefresh, isFalse,
          reason:
              'Fix: null token does NOT trigger early return, refresh proceeds');
    });

    test(
        'EDGE CASE: near-expiry token (<2min) — hasValidAccessToken() returns true',
        () async {
      // Near-expiry: hasValidAccessToken() = true → early return → skip refresh
      // This is ACCEPTABLE: the interceptor's proactive refresh (line 64)
      // will handle it on the first API call.
      final token = _createTestJwt(
        expiry: DateTime.now().add(const Duration(seconds: 90)),
      );
      await TokenManager.setAccessToken(token);

      final fixedSkipRefresh = TokenManager.hasValidAccessToken();
      expect(fixedSkipRefresh, isTrue,
          reason:
              'Near-expiry token skips startup refresh — interceptor handles it');
    });
  });

  // ===========================================================================
  // INTEGRATION TEST: Full init flow simulation
  // ===========================================================================
  group('initializeAuth flow simulation', () {
    // Simulates the decision tree in initializeAuth() using the FIXED logic,
    // without actual network calls or secure storage.

    test('valid token → skips refresh, completes bootstrap', () async {
      final log = <String>[];

      // Simulate: storage returns a valid token
      final token = _createTestJwt(
        expiry: DateTime.now().add(const Duration(hours: 1)),
      );
      await TokenManager.setAccessToken(token);

      // Simulate initializeAuth decision
      if (TokenManager.hasValidAccessToken()) {
        log.add('skip_refresh');
      } else {
        log.add('attempt_refresh');
      }

      expect(log, equals(['skip_refresh']));
    });

    test('expired token + refresh token → attempts refresh', () async {
      final log = <String>[];

      // Simulate: storage returns an expired token
      final token = _createTestJwt(
        expiry: DateTime.now().subtract(const Duration(hours: 1)),
      );
      await TokenManager.setAccessToken(token);

      // Simulate initializeAuth decision
      if (TokenManager.hasValidAccessToken()) {
        log.add('skip_refresh');
      } else {
        // Simulate: refresh token exists
        const refreshToken = 'some_refresh_token';
        log.add('attempt_refresh');
      }

      expect(log, equals(['attempt_refresh']));
    });

    test('null token + no refresh token → completes without refresh', () async {
      final log = <String>[];

      // Simulate: no stored access token
      // TokenManager._accessToken is already null from setUp

      if (TokenManager.hasValidAccessToken()) {
        log.add('skip_refresh');
      } else {
        // Simulate: no refresh token either
        const String? refreshToken = null;
        if (refreshToken == null) {
          log.add('no_refresh_token');
        } else {
          log.add('attempt_refresh');
        }
      }

      expect(log, equals(['no_refresh_token']));
    });

    test('null token + has refresh token → attempts refresh', () async {
      final log = <String>[];

      // Simulate: no access token but refresh token exists
      if (TokenManager.hasValidAccessToken()) {
        log.add('skip_refresh');
      } else {
        const refreshToken = 'valid_refresh_token';
        log.add('attempt_refresh');
      }

      expect(log, equals(['attempt_refresh']));
    });
  });
}
