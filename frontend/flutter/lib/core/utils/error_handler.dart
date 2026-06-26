import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:creatorio/core/models/api_error.dart';
import 'package:creatorio/core/exceptions/app_exceptions.dart';

class ErrorHandler {
  static Exception handle(dynamic error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      if (error is DioException) {
        debugPrint('[ErrorHandler] DioException: ${error.type} at ${error.requestOptions.path}');
        if (error.response?.data != null) {
          debugPrint('[ErrorHandler] Response: ${error.response?.data}');
        }
      } else {
        debugPrint('[ErrorHandler] Unexpected error: $error');
      }
      if (stackTrace != null) debugPrintStack(stackTrace: stackTrace);
    }

    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout || 
          error.type == DioExceptionType.receiveTimeout || 
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError) {
        return NetworkException('Network connection failed. Please check your internet connection.');
      }
      
      if (error.type == DioExceptionType.badResponse) {
        final statusCode = error.response?.statusCode ?? 500;
        String message = 'Server returned an error.';
        if (error.response?.data != null) {
          try {
            final apiError = ApiError.fromMap(error.response!.data);
            message = apiError.message;
          } catch (_) {}
        }
        if (statusCode == 401 || statusCode == 403) {
           return AuthException(message);
        }
        return ServerException(statusCode, message);
      }
      
      return NetworkException(error.message ?? 'Unknown network error');
    }

    return ServerException(500, error.toString());
  }
}

