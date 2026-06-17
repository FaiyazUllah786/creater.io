// Unit tests for AuthInterceptor Concurrency (Phase 2)
//
// The bug: If multiple requests hit a 401 concurrently and the refresh attempt
// fails, both the initiator and waiter would attempt to call
// _refreshCompleter.completeError(), causing a StateError.
//
// The fix: Separate waiter and initiator paths and guard completeError()
// with isCompleted checks.
//
// Run with:
// flutter test test/auth_interceptor_concurrency_test.dart

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

class MockAuthInterceptor {
  bool _isRefreshing = false;
  bool _isLoggingOut = false;
  Completer<void>? _refreshCompleter;

  int refreshCallCount = 0;
  int retryCallCount = 0;
  int logoutCallCount = 0;

  final Future<void> Function() refreshBehavior;

  MockAuthInterceptor({
    required this.refreshBehavior,
  });

  Future<void> onError(int requestId) async {
    /// Waiter path
    if (_isRefreshing) {
      try {
        await _refreshCompleter?.future;

        retryCallCount++;

        return;
      } catch (e) {
        await _logout();

        throw Exception('WaiterPropagatedError');
      }
    }

    /// Initiator path
    try {
      _isRefreshing = true;

      _refreshCompleter = Completer<void>();

      // Prevent unhandled future warnings
      _refreshCompleter?.future.catchError((_) {});

      refreshCallCount++;

      await refreshBehavior();

      _refreshCompleter?.complete();

      retryCallCount++;
    } catch (e) {
      if (!(_refreshCompleter?.isCompleted ?? true)) {
        _refreshCompleter?.completeError(e);
      }

      await _logout();

      throw Exception('InitiatorPropagatedError');
    } finally {
      _isRefreshing = false;
      _refreshCompleter = null;
    }
  }

  Future<void> _logout() async {
    if (_isLoggingOut) {
      return;
    }

    _isLoggingOut = true;

    logoutCallCount++;

    await Future.delayed(
      const Duration(milliseconds: 10),
    );
  }
}

void main() {
  group(
    'AuthInterceptor Concurrency Latch (Refresh Storm Prevention)',
    () {
      test(
        '1. Multiple successful concurrent refreshes',
        () async {
          final interceptor = MockAuthInterceptor(
            refreshBehavior: () async {
              await Future.delayed(
                const Duration(milliseconds: 100),
              );
            },
          );

          final futures = [
            interceptor.onError(1),
            interceptor.onError(2),
            interceptor.onError(3),
          ];

          await Future.wait(futures);

          expect(
            interceptor.refreshCallCount,
            equals(1),
          );

          expect(
            interceptor.retryCallCount,
            equals(3),
          );

          expect(
            interceptor.logoutCallCount,
            equals(0),
          );
        },
      );

      test(
        '2. Multiple concurrent refresh failures do not throw StateError',
        () async {
          final interceptor = MockAuthInterceptor(
            refreshBehavior: () async {
              await Future.delayed(
                const Duration(milliseconds: 50),
              );

              throw Exception(
                'Refresh token expired',
              );
            },
          );

          final futures = [
            interceptor.onError(1),
            interceptor.onError(2),
            interceptor.onError(3),
          ];

          final results = await Future.wait(
            futures.map(
              (future) async {
                try {
                  await future;

                  return null;
                } catch (e) {
                  return e;
                }
              },
            ),
          );

          expect(
            interceptor.refreshCallCount,
            equals(1),
          );

          expect(
            interceptor.retryCallCount,
            equals(0),
          );

          expect(
            interceptor.logoutCallCount,
            equals(1),
          );

          expect(
            results.length,
            equals(3),
          );

          for (final result in results) {
            expect(
              result,
              isNot(isA<StateError>()),
            );

            expect(
              result.toString(),
              anyOf(
                contains(
                  'WaiterPropagatedError',
                ),
                contains(
                  'InitiatorPropagatedError',
                ),
              ),
            );
          }
        },
      );

      test(
        '3. Immediate refresh failure still avoids StateError',
        () async {
          final interceptor = MockAuthInterceptor(
            refreshBehavior: () async {
              throw Exception(
                'Immediate failure',
              );
            },
          );

          final futures = [
            interceptor.onError(1),
            interceptor.onError(2),
          ];

          final results = await Future.wait(
            futures.map(
              (future) async {
                try {
                  await future;

                  return null;
                } catch (e) {
                  return e;
                }
              },
            ),
          );

          expect(
            interceptor.refreshCallCount,
            equals(1),
          );

          expect(
            interceptor.retryCallCount,
            equals(0),
          );

          expect(
            interceptor.logoutCallCount,
            equals(1),
          );

          for (final result in results) {
            expect(
              result,
              isNot(isA<StateError>()),
            );

            expect(
              result.toString(),
              anyOf(
                contains(
                  'WaiterPropagatedError',
                ),
                contains(
                  'InitiatorPropagatedError',
                ),
              ),
            );
          }
        },
      );
    },
  );
}
