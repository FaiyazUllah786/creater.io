import 'dart:io';

import 'package:creatorio/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
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

      debugPrint("Update photo Response: ${res.data}");

      return ApiResponse.fromMap(
        res.data,
      );
    } catch (e, stackTrace) {
      throw ErrorHandler.handle(e, stackTrace);
    }
  }

  @override
  Future<ApiResponse?> getImages() async {
    try {
      final res = await dio.get('/image/get-images');
      debugPrint("Get images Response: ${res.data}");
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
      debugPrint("Delete image response body: ${res.data}");
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
      debugPrint("Save image response body: ${res.data}");
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
      debugPrint("Add image transformation response body: ${res.data}");
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
      debugPrint("Update image transformation response body: ${res.data}");
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
      debugPrint("Delete image transformation response body: ${res.data}");
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
      debugPrint("Clear image transformation response body: ${res.data}");
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
      debugPrint("save image transformation response body: ${res.data}");
      return ApiResponse.fromMap(res.data);
    } catch (e, stackTrace) {
      throw ErrorHandler.handle(e, stackTrace);
    }
  }
}
