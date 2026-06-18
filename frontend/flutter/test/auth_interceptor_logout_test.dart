// Unit tests for Issue 6: _isLoggingOut flag never reset
//
// The bug: _isLoggingOut was set to true and never reset. Since the
// AuthInterceptor is a singleton that lives for the entire app session,
// once an auto-logout was triggered, the interceptor could never
// perform another auto-logout — even after the user logged back in.
//
// The fix: Wrap the logout body in try/finally and reset the flag.
//
// Run with:
//   flutter test test/auth_interceptor_logout_test.dart

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

/// Lightweight mock that mirrors the _logout() lifecycle of AuthInterceptor.
class MockLogoutInterceptor {
  bool _isLoggingOut = false;
  int logoutExecutionCount = 0;
  int logoutSkipCount = 0;

  final Future<void> Function()? logoutSideEffect;

  MockLogoutInterceptor({this.logoutSideEffect});

  /// Original buggy implementation (for comparison tests)
  Future<void> logoutBuggy() async {
    if (_isLoggingOut) {
      logoutSkipCount++;
      return;
    }
    _isLoggingOut = true;

    logoutExecutionCount++;
    await (logoutSideEffect?.call() ?? Future.value());

    // BUG: _isLoggingOut is never reset to false
  }

  /// Fixed implementation
  Future<void> logoutFixed() async {
    if (_isLoggingOut) {
      logoutSkipCount++;
      return;
    }
    _isLoggingOut = true;

    try {
      logoutExecutionCount++;
      await (logoutSideEffect?.call() ?? Future.value());
    } finally {
      _isLoggingOut = false;
    }
  }

  bool get isLoggingOut => _isLoggingOut;
}

void main() {
  group('Issue 6: _isLoggingOut reset', () {
    test('BUG: after logout, flag stays true permanently', () async {
      final mock = MockLogoutInterceptor();

      // First logout works
      await mock.logoutBuggy();
      expect(mock.logoutExecutionCount, equals(1));
      expect(mock.isLoggingOut, isTrue); // stuck at true

      // Second logout is silently skipped
      await mock.logoutBuggy();
      expect(mock.logoutExecutionCount, equals(1)); // never incremented
      expect(mock.logoutSkipCount, equals(1));
    });

    test('FIX: after logout, flag resets to false', () async {
      final mock = MockLogoutInterceptor();

      // First logout works
      await mock.logoutFixed();
      expect(mock.logoutExecutionCount, equals(1));
      expect(mock.isLoggingOut, isFalse); // correctly reset

      // Second logout also works (simulating re-login + another token expiry)
      await mock.logoutFixed();
      expect(mock.logoutExecutionCount, equals(2));
      expect(mock.isLoggingOut, isFalse);
    });

    test('FIX: flag resets even if logout body throws', () async {
      final mock = MockLogoutInterceptor(
        logoutSideEffect: () async {
          throw Exception('SecureStorage.clear() failed');
        },
      );

      // Logout throws, but flag should still reset
      try {
        await mock.logoutFixed();
      } catch (_) {
        // Expected
      }

      expect(mock.isLoggingOut, isFalse);
      expect(mock.logoutExecutionCount, equals(1));

      // Can logout again after error
      final mock2 = MockLogoutInterceptor();
      await mock2.logoutFixed();
      expect(mock2.logoutExecutionCount, equals(1));
    });

    test('FIX: concurrent logout calls are deduplicated', () async {
      final completer = Completer<void>();
      final mock = MockLogoutInterceptor(
        logoutSideEffect: () => completer.future,
      );

      // Fire two concurrent logouts
      final future1 = mock.logoutFixed();
      final future2 = mock.logoutFixed();

      // Second call should be skipped (guard is active while first runs)
      expect(mock.logoutSkipCount, equals(1));

      // Complete the first logout
      completer.complete();
      await future1;
      await future2;

      // Only one logout executed
      expect(mock.logoutExecutionCount, equals(1));

      // But flag is reset, so a THIRD call would work
      await mock.logoutFixed();
      expect(mock.logoutExecutionCount, equals(2));
    });

    test(
      'Full lifecycle: auto-logout → re-login → auto-logout works',
      () async {
        final mock = MockLogoutInterceptor();

        // Step 1: Token expires, interceptor triggers auto-logout
        await mock.logoutFixed();
        expect(mock.logoutExecutionCount, equals(1));
        expect(mock.isLoggingOut, isFalse);

        // Step 2: User manually logs back in
        // (no interceptor involvement — just sets new tokens)
        // ... time passes ...

        // Step 3: Token expires again, interceptor triggers auto-logout
        await mock.logoutFixed();
        expect(mock.logoutExecutionCount, equals(2));
        expect(mock.isLoggingOut, isFalse);

        // Step 4: Repeat — should work indefinitely
        await mock.logoutFixed();
        expect(mock.logoutExecutionCount, equals(3));
      },
    );
  });
}
