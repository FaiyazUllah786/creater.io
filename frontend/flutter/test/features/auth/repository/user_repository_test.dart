import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:creatorio/core/network/dio_client.dart';
import 'package:creatorio/features/auth/repository/user_repository.dart';
import 'package:creatorio/core/exceptions/app_exceptions.dart';

class MockHttpClientAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;

  MockHttpClientAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late UserRepository repository;
  late Dio dio;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    repository = UserRepository();
    dio = DioClient.dio;
  });

  group('UserRepository', () {
    test('loginUser returns ApiResponse on success', () async {
      dio.httpClientAdapter = MockHttpClientAdapter((options) async {
        expect(options.path, '/user/auth/login');
        expect(options.method, 'POST');
        expect(options.data,
            {'email': 'test@example.com', 'password': 'password123'});

        return ResponseBody.fromString(
          jsonEncode({
            'statusCode': 200,
            'success': true,
            'message': 'Logged in successfully',
            'data': {'accessToken': 'token'},
          }),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        );
      });

      final response =
          await repository.loginUser('test@example.com', 'password123');

      expect(response, isNotNull);
      expect(response!.statusCode, 200);
      expect(response.message, 'Logged in successfully');
      expect(response.data, {'accessToken': 'token'});
    });

    test('loginUser throws ApiError on failure', () async {
      dio.httpClientAdapter = MockHttpClientAdapter((options) async {
        return ResponseBody.fromString(
          jsonEncode({
            'statusCode': 400,
            'success': false,
            'message': 'Invalid credentials',
          }),
          400,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        );
      });

      expect(
        () => repository.loginUser('test@example.com', 'wrong'),
        throwsA(isA<ServerException>()),
      );
    });

    test('registerUser returns ApiResponse on success', () async {
      dio.httpClientAdapter = MockHttpClientAdapter((options) async {
        expect(options.path, '/user/auth/register');
        expect(options.method, 'POST');
        expect(options.data, isA<FormData>());

        return ResponseBody.fromString(
          jsonEncode({
            'statusCode': 201,
            'success': true,
            'message': 'Account created successfully',
            'data': {'id': '123'},
          }),
          201,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        );
      });

      final response = await repository.registerUser(
          'username', 'test@example.com', 'password123', '');

      expect(response, isNotNull);
      expect(response!.statusCode, 201);
      expect(response.message, 'Account created successfully');
    });

    test('logout returns ApiResponse on success', () async {
      dio.httpClientAdapter = MockHttpClientAdapter((options) async {
        expect(options.path, '/user/auth/logout');
        expect(options.method, 'POST');

        return ResponseBody.fromString(
          jsonEncode({
            'statusCode': 200,
            'success': true,
            'message': 'Logged out successfully',
          }),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        );
      });

      final response = await repository.logout();

      expect(response, isNotNull);
      expect(response!.statusCode, 200);
      expect(response.message, 'Logged out successfully');
    });

    test('getCurrentUser returns ApiResponse on success', () async {
      dio.httpClientAdapter = MockHttpClientAdapter((options) async {
        expect(options.path, '/user/current-user');
        expect(options.method, 'GET');

        return ResponseBody.fromString(
          jsonEncode({
            'statusCode': 200,
            'success': true,
            'message': 'User retrieved successfully',
            'data': {'userName': 'testuser'},
          }),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        );
      });

      final response = await repository.getCurrentUser();

      expect(response, isNotNull);
      expect(response!.statusCode, 200);
      expect(response.data['userName'], 'testuser');
    });
  });
}
