import 'package:creatorio/common/ip.dart';
import 'package:creatorio/core/network/auth_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class DioClient {
  DioClient._();

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: myIp,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  static void initializeInterceptors() {
    debugPrint('Interceptor initialized');
    dio.interceptors.add(
      AuthInterceptor(dio),
    );
  }
}
