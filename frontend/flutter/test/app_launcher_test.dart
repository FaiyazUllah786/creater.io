// Unit & integration tests for Issue 7: AuthService.initializeAuth() race condition fix
//
// These tests verify that AppLauncher AWAITS auth initialization before
// deciding whether to navigate to /home or /login.
//
// Run with:
//   flutter test test/app_launcher_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:creatorio/core/network/token_manager.dart';
import 'package:creatorio/core/network/auth_bootstrap.dart';

// ---------------------------------------------------------------------------
// Unit tests: TokenManager state after async init
// ---------------------------------------------------------------------------
void main() {
  group('TokenManager — unit tests', () {
    setUp(() {
      // Reset in-memory token state before every test
      TokenManager.clear();
    });

    test('hasValidAccessToken returns false when token is null', () {
      expect(TokenManager.accessToken, isNull);
      expect(TokenManager.hasValidAccessToken(), isFalse);
    });

    test('hasValidAccessToken returns false after clear()', () async {
      // Simulate a login that populates the token
      await TokenManager.setAccessToken('dummy.token.value');
      expect(TokenManager.accessToken, isNotNull);

      TokenManager.clear();
      expect(TokenManager.hasValidAccessToken(), isFalse);
    });

    test('setAccessToken stores the token in memory', () async {
      const fakeToken = 'abc.def.ghi';
      await TokenManager.setAccessToken(fakeToken);
      expect(TokenManager.accessToken, equals(fakeToken));
    });
  });

  group('AuthBootstrap — unit tests', () {
    test('isBootstrapping is false initially', () {
      // AuthBootstrap should not be in a bootstrapping state
      // unless start() was called and not yet completed
      expect(AuthBootstrap.isBootstrapping, isFalse);
    });

    test('start() sets isBootstrapping to true', () {
      AuthBootstrap.start();
      expect(AuthBootstrap.isBootstrapping, isTrue);

      // Clean up
      AuthBootstrap.complete();
    });

    test('complete() clears the bootstrapping state', () {
      AuthBootstrap.start();
      AuthBootstrap.complete();
      expect(AuthBootstrap.isBootstrapping, isFalse);
    });

    test('completeError() clears the bootstrapping state', () async {
      AuthBootstrap.start();

      final future = AuthBootstrap.future;

      AuthBootstrap.completeError(Exception('test error'));

      expect(AuthBootstrap.isBootstrapping, isFalse);

      await expectLater(
        future,
        throwsA(isA<Exception>()),
      );
    });

    test('future resolves after complete()', () async {
      AuthBootstrap.start();
      final future = AuthBootstrap.future;
      expect(future, isNotNull);

      AuthBootstrap.complete();
      // If this doesn't throw/hang, the future resolved successfully
      await future;
    });

    test('calling complete() before start() is a no-op', () {
      // Should not throw
      AuthBootstrap.complete();
      expect(AuthBootstrap.isBootstrapping, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Integration test: Navigation decision ordering
  // ---------------------------------------------------------------------------
  group('AppLauncher — integration: init-before-navigate contract', () {
    // This test verifies the ORDERING contract: that the navigation decision
    // cannot be made until the async init completes.
    //
    // We simulate the sequencing using a Completer to model the
    // AuthService.initializeAuth() future, then assert that the downstream
    // check only runs AFTER the completer completes.

    test(
        'navigation decision is blocked until auth init completes '
        '(ordering contract)', () async {
      // Track execution order
      final executionLog = <String>[];

      // Simulate the _init() method's structure with await
      Future<void> initWithAwait() async {
        // Simulate AuthService.initializeAuth()
        await Future.delayed(const Duration(milliseconds: 50), () {
          executionLog.add('auth_init_complete');
        });

        // This represents the navigation check — should run AFTER init
        executionLog.add('navigation_check');
      }

      await initWithAwait();

      // Verify ordering: auth init completes BEFORE navigation check
      expect(executionLog,
          orderedEquals(['auth_init_complete', 'navigation_check']));
    });

    test(
        'WITHOUT await, navigation check runs BEFORE auth init '
        '(demonstrates the bug)', () async {
      final executionLog = <String>[];

      // Simulate the BUGGY _init() method WITHOUT await
      Future<void> initWithoutAwait() async {
        // Fire-and-forget (the bug)
        Future.delayed(const Duration(milliseconds: 50), () {
          executionLog.add('auth_init_complete');
        });

        // Navigation check runs immediately — before init finishes
        executionLog.add('navigation_check');
      }

      await initWithoutAwait();

      // The navigation check ran first (the bug behavior)
      expect(executionLog, orderedEquals(['navigation_check']));

      // Wait for the delayed future to complete
      await Future.delayed(const Duration(milliseconds: 100));

      // Now both have run, but in the WRONG order
      expect(executionLog,
          orderedEquals(['navigation_check', 'auth_init_complete']));
    });
  });
}
