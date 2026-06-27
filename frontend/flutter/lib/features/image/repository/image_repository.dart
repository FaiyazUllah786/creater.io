import 'dart:io';

import 'package:creatorio/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:creatorio/core/models/api_response.dart';
import 'package:creatorio/core/utils/error_handler.dart';

import 'i_image_repository.dart';

class ImageRepository implements IImageRepository {
  final Dio dio = DioClient.dio;
  @override
  Future<ApiResponse?> uploadImage(File imageFiles) async {
    try {
      final imagePath = imageFiles.path;
      FormData formData = FormData();

      if (imagePath.isNotEmpty) {
        formData.files.add(
          MapEntry(
            'images',
            await MultipartFile.fromFile(imagePath),
          ),
        );
      }

      final res = await dio.post(
        '/image/upload',
        data: formData,
      );

      return ApiResponse.fromMap(
        res.data,
      );
    } catch (e, stackTrace) {
      throw ErrorHandler.handle(e, stackTrace);
    }
  }

  @override
  Future<ApiResponse?> getImages({int page = 1, int limit = 10}) async {
    try {
      final res = await dio.get('/image/get-images', queryParameters: {
        'page': page,
        'limit': limit,
      });
      return ApiResponse.fromMap(res.data);
    } catch (e, stackTrace) {
      throw ErrorHandler.handle(e, stackTrace);
    }
  }

  @override
  Future<ApiResponse?> deleteImage(String imageId) async {
    try {
      final res = await dio.post(
        '/image/delete-image',
        data: {
          "imageId": imageId,
        },
      );
      return ApiResponse.fromMap(res.data);
    } catch (e, stackTrace) {
      throw ErrorHandler.handle(e, stackTrace);
    }
  }

  @override
  Future<ApiResponse?> saveImage(String imageUrl) async {
    try {
      final res = await dio.post(
        '/image/save-image',
        data: {
          "imageUrl": imageUrl,
        },
      );
      return ApiResponse.fromMap(res.data);
    } catch (e, stackTrace) {
      throw ErrorHandler.handle(e, stackTrace);
    }
  }

  @override
  Future<ApiResponse?> addTransformation(
      String imagePublicId, Map<String, dynamic> transformation) async {
    try {
      final res = await dio.post(
        '/image/add-transformation',
        data: {
          "imagePublicId": imagePublicId,
          "transformation": transformation,
        },
      );
      return ApiResponse.fromMap(res.data);
    } catch (e, stackTrace) {
      throw ErrorHandler.handle(e, stackTrace);
    }
  }

  @override
  Future<ApiResponse?> updateTransformation(String imagePublicId,
      Map<String, dynamic> transformation, String transformationId) async {
    try {
      final res = await dio.post('/image/update-transformation', data: {
        "imagePublicId": imagePublicId,
        "transformation": transformation,
        "transformationId": transformationId
      });
      return ApiResponse.fromMap(res.data);
    } catch (e, stackTrace) {
      throw ErrorHandler.handle(e, stackTrace);
    }
  }

  @override
  Future<ApiResponse?> deleteTransformation(
      String imagePublicId, String transformationId) async {
    try {
      final res = await dio.post('/image/delete-transformation', data: {
        "imagePublicId": imagePublicId,
        "transformationId": transformationId
      });
      return ApiResponse.fromMap(res.data);
    } catch (e, stackTrace) {
      throw ErrorHandler.handle(e, stackTrace);
    }
  }

  @override
  Future<ApiResponse?> clearTransformation(String imagePublicId) async {
    try {
      final res = await dio.post('/image/clear-transformation', data: {
        "imagePublicId": imagePublicId,
      });
      return ApiResponse.fromMap(res.data);
    } catch (e, stackTrace) {
      throw ErrorHandler.handle(e, stackTrace);
    }
  }

  @override
  Future<ApiResponse?> saveTransformation(
      {required String imagePublicId}) async {
    try {
      final res = await dio.post('/image/save', data: {
        "imagePublicId": imagePublicId,
      });
      return ApiResponse.fromMap(res.data);
    } catch (e, stackTrace) {
      throw ErrorHandler.handle(e, stackTrace);
    }
  }
}
