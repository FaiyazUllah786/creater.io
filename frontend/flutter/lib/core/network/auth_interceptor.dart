import 'dart:async';
import 'package:creatorio/common/navigator_key.dart';
import 'package:creatorio/common/storage.dart';
import 'package:creatorio/core/network/auth_bootstrap.dart';
import 'package:creatorio/core/network/token_manager.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AuthInterceptor extends Interceptor {
  final Dio dio;

  late final Dio refreshDio;

  AuthInterceptor(this.dio) {
    refreshDio = Dio(
      BaseOptions(
        baseUrl: dio.options.baseUrl,
        connectTimeout: dio.options.connectTimeout,
        receiveTimeout: dio.options.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  /// Prevent multiple refresh calls
  bool _isRefreshing = false;

  /// Prevent multiple logout calls
  bool _isLoggingOut = false;

  /// Queue waiting requests
  Completer<void>? _refreshCompleter;

  static const List<String> publicRoutes = [
    '/user/auth/login',
    '/user/auth/register',
    '/user/auth/refresh-tokens',
    '/auth/google/mobile',
    '/auth/github/mobile'
  ];

  bool _isPublicRoute(String path) {
    final normalizedPath = Uri.parse(path).path;

    return publicRoutes.contains(normalizedPath);
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      /// Skip auth logic for public APIs
      if (!_isPublicRoute(options.path)) {
        /// Wait for auth bootstrap if running
        if (AuthBootstrap.isBootstrapping) {
          await AuthBootstrap.future;
        }

        /// Proactive refresh
        if (TokenManager.shouldRefreshToken()) {
          await _handleTokenRefresh();
        }

        final token = TokenManager.accessToken;

        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      }

      handler.next(options);
    } catch (e) {
      await _logout();

      handler.reject(
        DioException(
          requestOptions: options,
          error: 'Session expired',
        ),
      );
    }
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    /// Ignore non-401 errors
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    /// Avoid infinite retry loop
    if (err.requestOptions.extra['retried'] == true) {
      return handler.next(err);
    }

    /// If refresh API itself failed
    final isRefreshApi = _isPublicRoute(
      err.requestOptions.path,
    );

    if (isRefreshApi) {
      await _logout();

      return handler.next(err);
    }

    try {
      /// Wait if another refresh is happening
      if (_isRefreshing) {
        await _refreshCompleter?.future;

        final response = await _retryRequest(
          err.requestOptions,
        );

        return handler.resolve(response);
      }

      /// Start refresh process
      _isRefreshing = true;

      _refreshCompleter = Completer<void>();

      await _refreshToken();

      _refreshCompleter?.complete();

      final response = await _retryRequest(
        err.requestOptions,
      );

      return handler.resolve(response);
    } catch (e) {
      _refreshCompleter?.completeError(e);

      await _logout();

      return handler.next(err);
    } finally {
      _isRefreshing = false;

      _refreshCompleter = null;
    }
  }

  /// ============================================================
  /// REFRESH TOKEN
  /// ============================================================

  Future<void> _refreshToken() async {
    final refreshToken = await SecureStorageService.getRefreshToken();

    if (refreshToken == null) {
      throw Exception('Refresh token missing');
    }

    if (kDebugMode) {
      debugPrint('Refreshing token...');
    }

    final response = await refreshDio.post(
      '/user/auth/refresh-tokens',
      data: {
        'refreshToken': refreshToken,
      },
    );

    final newAccessToken = response.data['accessToken'];

    final newRefreshToken = response.data['refreshToken'];

    if (newAccessToken == null || newRefreshToken == null) {
      throw Exception(
        'Invalid refresh response',
      );
    }

    /// Save in memory
    await TokenManager.setAccessToken(
      newAccessToken,
    );

    /// Save in storage
    await SecureStorageService.saveAccessToken(
      newAccessToken,
    );

    await SecureStorageService.saveRefreshToken(
      newRefreshToken,
    );

    if (kDebugMode) {
      debugPrint('Token refreshed');
    }
  }

  /// ============================================================
  /// HANDLE TOKEN REFRESH
  /// ============================================================

  Future<void> _handleTokenRefresh() async {
    if (_isRefreshing) {
      await _refreshCompleter?.future;
      return;
    }

    try {
      _isRefreshing = true;

      _refreshCompleter = Completer<void>();

      await _refreshToken();

      _refreshCompleter?.complete();
    } catch (e) {
      _refreshCompleter?.completeError(e);

      rethrow;
    } finally {
      _isRefreshing = false;

      _refreshCompleter = null;
    }
  }

  /// ============================================================
  /// RETRY REQUEST
  /// ============================================================

  Future<Response<dynamic>> _retryRequest(
    RequestOptions requestOptions,
  ) async {
    final token = TokenManager.accessToken;

    requestOptions.extra['retried'] = true;

    if (kDebugMode) {
      debugPrint(
        'Retrying request: ${requestOptions.path}',
      );
    }

    final options = Options(
      method: requestOptions.method,
      headers: {
        ...requestOptions.headers,
        'Authorization': 'Bearer $token',
      },
    );

    return dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  /// ============================================================
  /// LOGOUT
  /// ============================================================

  Future<void> _logout() async {
    if (_isLoggingOut) return;

    _isLoggingOut = true;

    if (kDebugMode) {
      debugPrint('Logging out user...');
    }

    TokenManager.clear();

    await SecureStorageService.clear();

    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }
}
