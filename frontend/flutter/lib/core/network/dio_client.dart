import 'package:creatorio/core/network/auth_interceptor.dart';
import 'package:creatorio/core/network/retry_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:creatorio/core/config/app_config.dart';

/// A singleton client providing a configured [Dio] instance for network requests.
class DioClient {
  DioClient._();

  /// The globally accessible [Dio] instance pre-configured with base URL and timeouts.
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.serverUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  /// Initializes interceptors for authentication and retry logic.
  /// Should be called exactly once during app initialization.
  static void initializeInterceptors() {
    debugPrint('Interceptor initialized');
    dio.interceptors.add(
      AuthInterceptor(dio),
    );
    dio.interceptors.add(
      RetryInterceptor(dio),
    );
  }
}
