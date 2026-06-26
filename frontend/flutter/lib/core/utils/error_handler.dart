import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:creatorio/core/exceptions/api_error.dart';

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
      if (error.response?.data != null) {
        try {
          return ApiError.fromMap(error.response!.data);
        } catch (_) {}
      }
      return ApiError(statusCode: 500, message: 'Network error occurred');
    }

    return ApiError(statusCode: 500, message: 'An unexpected error occurred. Please try again.');
  }
}
