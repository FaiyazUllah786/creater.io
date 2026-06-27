import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final List<String> idempotentMethods = [
    'GET',
    'PUT',
    'DELETE',
    'HEAD',
    'OPTIONS'
  ];

  RetryInterceptor(this.dio, {this.maxRetries = 3});

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final extra = err.requestOptions.extra;
    final int currentRetry = extra['retryCount'] ?? 0;

    if (_shouldRetry(err) && currentRetry < maxRetries) {
      final method = err.requestOptions.method.toUpperCase();

      // Only auto-retry idempotent requests unless explicitly overridden
      final bool forceRetry = extra['forceRetry'] == true;
      if (idempotentMethods.contains(method) || forceRetry) {
        final nextRetry = currentRetry + 1;

        // Exponential backoff: 1s, 2s, 4s...
        final delaySeconds = 1 << (currentRetry);

        if (kDebugMode) {
          debugPrint('[RetryInterceptor] Request failed with ${err.type}. '
              'Retrying $method ${err.requestOptions.path} '
              '($nextRetry/$maxRetries) in ${delaySeconds}s...');
        }

        await Future.delayed(Duration(seconds: delaySeconds));

        err.requestOptions.extra['retryCount'] = nextRetry;

        try {
          final response = await dio.fetch(err.requestOptions);
          return handler.resolve(response);
        } on DioException catch (e) {
          return super.onError(e, handler);
        } catch (e) {
          return super.onError(err, handler);
        }
      }
    }

    return super.onError(err, handler);
  }

  bool _shouldRetry(DioException err) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      return true;
    }

    if (err.type == DioExceptionType.badResponse) {
      final statusCode = err.response?.statusCode;
      if (statusCode != null &&
          (statusCode == 500 ||
              statusCode == 502 ||
              statusCode == 503 ||
              statusCode == 504)) {
        return true;
      }
    }

    return false;
  }
}
