import 'package:creatorio/common/widgets/api_response.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../common/storage.dart';
import '../network/token_manager.dart';
import 'auth_bootstrap.dart';

class AuthService {
  static final Dio _refreshDio = Dio(
    BaseOptions(
      baseUrl: dotenv.env['SERVER_URL'] ?? '',
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

      /// Restore access token immediately
      if (TokenManager.shouldRefreshToken()) {
        debugPrint(
          'Access token restored from storage',
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

      await SecureStorageService.clear();

      TokenManager.clear();

      AuthBootstrap.completeError(e);
    }
  }
}
