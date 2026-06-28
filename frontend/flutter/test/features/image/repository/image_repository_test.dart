import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:creatorio/core/network/dio_client.dart';
import 'package:creatorio/features/image/repository/image_repository.dart';
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
  late ImageRepository repository;
  late Dio dio;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    repository = ImageRepository();
    dio = DioClient.dio;
  });

  group('ImageRepository', () {
    test('getImages returns ApiResponse on success', () async {
      dio.httpClientAdapter = MockHttpClientAdapter((options) async {
        expect(options.path, '/image/get-images');
        expect(options.method, 'GET');
        expect(options.queryParameters, {'page': 1, 'limit': 10});

        return ResponseBody.fromString(
          jsonEncode({
            'statusCode': 200,
            'success': true,
            'message': 'Images retrieved successfully',
            'data': {'images': []},
          }),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        );
      });

      final response = await repository.getImages(page: 1, limit: 10);

      expect(response, isNotNull);
      expect(response!.statusCode, 200);
      expect(response.message, 'Images retrieved successfully');
    });

    test('deleteImage returns ApiResponse on success', () async {
      dio.httpClientAdapter = MockHttpClientAdapter((options) async {
        expect(options.path, '/image/delete-image');
        expect(options.method, 'POST');
        expect(options.data, {'imageId': 'img123'});

        return ResponseBody.fromString(
          jsonEncode({
            'statusCode': 200,
            'success': true,
            'message': 'Image deleted successfully',
          }),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        );
      });

      final response = await repository.deleteImage('img123');

      expect(response, isNotNull);
      expect(response!.statusCode, 200);
    });

    test('addTransformation returns ApiResponse on success', () async {
      dio.httpClientAdapter = MockHttpClientAdapter((options) async {
        expect(options.path, '/image/add-transformation');
        expect(options.method, 'POST');
        expect(options.data, {
          'imagePublicId': 'pub123',
          'transformation': {'type': 'blur'}
        });

        return ResponseBody.fromString(
          jsonEncode({
            'statusCode': 200,
            'success': true,
            'message': 'Transformation added',
          }),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        );
      });

      final response =
          await repository.addTransformation('pub123', {'type': 'blur'});

      expect(response, isNotNull);
      expect(response!.statusCode, 200);
    });

    test('throws ServerException on 500 error', () async {
      dio.httpClientAdapter = MockHttpClientAdapter((options) async {
        return ResponseBody.fromString(
          jsonEncode({
            'statusCode': 500,
            'success': false,
            'message': 'Internal Server Error',
          }),
          500,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        );
      });

      expect(
        () => repository.deleteImage('img123'),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
