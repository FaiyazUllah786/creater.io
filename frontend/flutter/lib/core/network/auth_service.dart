import 'package:creatorio/core/models/api_response.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:creatorio/core/config/app_config.dart';

import '../../common/storage.dart';
import '../network/token_manager.dart';
import 'auth_bootstrap.dart';

class AuthService {
  static final Dio _refreshDio = Dio(
    BaseOptions(
      baseUrl: AppConfig.serverUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  static Future<void> initializeAuth() async {
    try {
      AuthBootstrap.start();

      final accessToken = await SecureStorageService.getAccessToken();
      TokenManager.setAccessToken(accessToken);

      /// If the restored access token is still valid, use it directly
      /// without making a network refresh call.
      if (TokenManager.hasValidAccessToken()) {
        debugPrint(
          'Valid access token restored from storage',
        );

        AuthBootstrap.complete();
        return;
      }

      final refreshToken = await SecureStorageService.getRefreshToken();

      if (refreshToken == null) {
        debugPrint(
          'Refresh token is not found',
        );
        AuthBootstrap.complete();
        return;
      }

      debugPrint('Restoring session...');

      final response = await _refreshDio.post(
        '/user/auth/refresh-tokens',
        data: {
          'refreshToken': refreshToken,
        },
      );
      final resMap = ApiResponse.fromMap(response.data);

      final newAccessToken = resMap.data['accessToken'];

      final newRefreshToken = resMap.data['refreshToken'];

      if (newAccessToken == null || newRefreshToken == null) {
        throw Exception('Invalid tokens');
      }

      await TokenManager.setAccessToken(
        newAccessToken,
      );

      await SecureStorageService.saveAccessToken(newAccessToken);

      await SecureStorageService.saveRefreshToken(newRefreshToken);

      debugPrint('Session restored');

      AuthBootstrap.complete();
    } catch (e) {
      debugPrint(
        'Session restore failed: $e',
      );

      if (_isAuthFailure(e)) {
        await SecureStorageService.clear();
        TokenManager.clear();
      }

      AuthBootstrap.completeError(e);
    }
  }

  static bool _isAuthFailure(dynamic e) {
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
