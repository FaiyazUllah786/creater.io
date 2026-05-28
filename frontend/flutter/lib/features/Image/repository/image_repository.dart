import 'dart:io';

import 'package:creatorio/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import '../../../common/widgets/api_error.dart';
import '../../../common/widgets/api_response.dart';

class ImageRepository {
  final Dio dio = DioClient.dio;

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
    } on DioException catch (e, stackTrace) {
      debugPrint("Update photo Error: ${e.response?.data}");

      debugPrintStack(stackTrace: stackTrace);

      if (e.response?.data != null) {
        throw ApiError.fromMap(
          e.response!.data,
        );
      }

      throw ApiError(
        statusCode: 500,
        message: "Network error occurred",
      );
    } catch (e, stackTrace) {
      debugPrint("Unexpected error during update photo: $e");

      debugPrintStack(stackTrace: stackTrace);

      throw ApiError(
        statusCode: 500,
        message: "Something went wrong. Please try again.",
      );
    }
  }

  Future<ApiResponse?> getImages() async {
    try {
      final res = await dio.get('/image/get-images');
      debugPrint("Get images Response: ${res.data}");
      return ApiResponse.fromMap(res.data);
    } on DioException catch (e, stackTrace) {
      debugPrint("Get images Error: ${e.response?.data}");

      debugPrintStack(stackTrace: stackTrace);

      if (e.response?.data != null) {
        throw ApiError.fromMap(
          e.response!.data,
        );
      }

      throw ApiError(
        statusCode: 500,
        message: "Network error occurred",
      );
    } catch (e, stackTrace) {
      debugPrint("Unexpected error during get images: $e");

      debugPrintStack(stackTrace: stackTrace);

      throw ApiError(
        statusCode: 500,
        message: "Something went wrong. Please try again.",
      );
    }
  }

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
    } on DioException catch (e, stackTrace) {
      debugPrint("Delete image Error: ${e.response?.data}");

      debugPrintStack(stackTrace: stackTrace);

      if (e.response?.data != null) {
        throw ApiError.fromMap(
          e.response!.data,
        );
      }

      throw ApiError(
        statusCode: 500,
        message: "Network error occurred",
      );
    } catch (e, stackTrace) {
      debugPrint("Unexpected error during delete image: $e");

      debugPrintStack(stackTrace: stackTrace);

      throw ApiError(
        statusCode: 500,
        message: "Something went wrong. Please try again.",
      );
    }
  }

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
    } on DioException catch (e, stackTrace) {
      debugPrint("Save image Error: ${e.response?.data}");

      debugPrintStack(stackTrace: stackTrace);

      if (e.response?.data != null) {
        throw ApiError.fromMap(
          e.response!.data,
        );
      }

      throw ApiError(
        statusCode: 500,
        message: "Network error occurred",
      );
    } catch (e, stackTrace) {
      debugPrint("Unexpected error during Save image: $e");

      debugPrintStack(stackTrace: stackTrace);

      throw ApiError(
        statusCode: 500,
        message: "Something went wrong. Please try again.",
      );
    }
  }

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
    } on DioException catch (e, stackTrace) {
      debugPrint("add image transformation image Error: ${e.response?.data}");

      debugPrintStack(stackTrace: stackTrace);

      if (e.response?.data != null) {
        throw ApiError.fromMap(
          e.response!.data,
        );
      }

      throw ApiError(
        statusCode: 500,
        message: "Network error occurred",
      );
    } catch (e, stackTrace) {
      debugPrint("Unexpected error during add image transformation: $e");

      debugPrintStack(stackTrace: stackTrace);

      throw ApiError(
        statusCode: 500,
        message: "Something went wrong. Please try again.",
      );
    }
  }

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
    } on DioException catch (e, stackTrace) {
      debugPrint(
          "Update image transformation transformation  Error: ${e.response?.data}");

      debugPrintStack(stackTrace: stackTrace);

      if (e.response?.data != null) {
        throw ApiError.fromMap(
          e.response!.data,
        );
      }

      throw ApiError(
        statusCode: 500,
        message: "Network error occurred",
      );
    } catch (e, stackTrace) {
      debugPrint("Unexpected error during update image transformation: $e");

      debugPrintStack(stackTrace: stackTrace);

      throw ApiError(
        statusCode: 500,
        message: "Something went wrong. Please try again.",
      );
    }
  }

  Future<ApiResponse?> deleteTransformation(
      String imagePublicId, String transformationId) async {
    try {
      final res = await dio.post('/image/delete-transformation', data: {
        "imagePublicId": imagePublicId,
        "transformationId": transformationId
      });
      debugPrint("Delete image transformation response body: ${res.data}");
      return ApiResponse.fromMap(res.data);
    } on DioException catch (e, stackTrace) {
      debugPrint("Delete image transformation Error: ${e.response?.data}");

      debugPrintStack(stackTrace: stackTrace);

      if (e.response?.data != null) {
        throw ApiError.fromMap(
          e.response!.data,
        );
      }

      throw ApiError(
        statusCode: 500,
        message: "Network error occurred",
      );
    } catch (e, stackTrace) {
      debugPrint("Unexpected error during delete image transformation: $e");

      debugPrintStack(stackTrace: stackTrace);

      throw ApiError(
        statusCode: 500,
        message: "Something went wrong. Please try again.",
      );
    }
  }

  Future<ApiResponse?> clearTransformation(String imagePublicId) async {
    try {
      final res = await dio.post('/image/clear-transformation', data: {
        "imagePublicId": imagePublicId,
      });
      debugPrint("Clear image transformation response body: ${res.data}");
      return ApiResponse.fromMap(res.data);
    } on DioException catch (e, stackTrace) {
      debugPrint("Clear image transformation Error: ${e.response?.data}");

      debugPrintStack(stackTrace: stackTrace);

      if (e.response?.data != null) {
        throw ApiError.fromMap(
          e.response!.data,
        );
      }

      throw ApiError(
        statusCode: 500,
        message: "Network error occurred",
      );
    } catch (e, stackTrace) {
      debugPrint("Unexpected error during clear image transformation: $e");

      debugPrintStack(stackTrace: stackTrace);

      throw ApiError(
        statusCode: 500,
        message: "Something went wrong. Please try again.",
      );
    }
  }

  Future<ApiResponse?> saveTransformation(
      {required String imagePublicId}) async {
    try {
      final res = await dio.post('/image/save', data: {
        "imagePublicId": imagePublicId,
      });
      debugPrint("save image transformation response body: ${res.data}");
      return ApiResponse.fromMap(res.data);
    } on DioException catch (e, stackTrace) {
      debugPrint("Save image transformation Error: ${e.response?.data}");

      debugPrintStack(stackTrace: stackTrace);

      if (e.response?.data != null) {
        throw ApiError.fromMap(
          e.response!.data,
        );
      }

      throw ApiError(
        statusCode: 500,
        message: "Network error occurred",
      );
    } catch (e, stackTrace) {
      debugPrint("Unexpected error during save image transformation: $e");

      debugPrintStack(stackTrace: stackTrace);

      throw ApiError(
        statusCode: 500,
        message: "Something went wrong. Please try again.",
      );
    }
  }
}
