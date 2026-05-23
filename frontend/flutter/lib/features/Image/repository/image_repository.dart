import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import '../../../common/ip.dart';
import '../../../common/storage.dart';
import '../../../common/widgets/api_error.dart';
import '../../../common/widgets/api_response.dart';

class ImageRepository {
  Future<ApiResponse?> uploadImage(File imageFiles) async {
    try {
      final accessToken = await storage.read(key: 'accessToken');
      final req =
          http.MultipartRequest("POST", Uri.parse("$myIp/image/upload"));
      req.headers["Authorization"] = "Bearer $accessToken";
      final images =
          await http.MultipartFile.fromPath("images", imageFiles.path);
      req.files.add(images);
      final res = await http.Response.fromStream(await req.send());
      final body = jsonDecode(res.body);
      debugPrint("Fetch image response body: $body");
      if (res.statusCode == 200) {
        return ApiResponse.fromMap(body);
      } else {
        throw ApiError.fromMap(body);
      }
    } on ApiError {
      rethrow;
    } catch (e, stackTrace) {
      debugPrint("Unexpected error during uploading image: $e");
      debugPrintStack(stackTrace: stackTrace);
      throw ApiError(
          statusCode: 500, message: "Something went wrong. Please try again.");
    }
  }

  Future<ApiResponse?> getImages() async {
    try {
      final accessToken = await storage.read(key: 'accessToken');
      final res = await http.get(Uri.parse('$myIp/image/get-images'),
          headers: {"Authorization": "Bearer $accessToken"});
      final body = jsonDecode(res.body);
      debugPrint("Fetch image response body: $body");
      if (res.statusCode == 200) {
        return ApiResponse.fromMap(body);
      } else {
        throw ApiError.fromMap(body);
      }
    } on ApiError {
      rethrow;
    } catch (e, stackTrace) {
      debugPrint("Unexpected error during fetch images: $e");
      debugPrintStack(stackTrace: stackTrace);
      throw ApiError(
          statusCode: 500, message: "Something went wrong. Please try again.");
    }
  }

  Future<ApiResponse?> deleteImage(String imageId) async {
    try {
      final accessToken = await storage.read(key: 'accessToken');
      final res = await http.post(Uri.parse('$myIp/image/delete-image'),
          headers: {"Authorization": "Bearer $accessToken"},
          body: {"imageId": imageId});
      final body = jsonDecode(res.body);
      debugPrint("Delete image response body: $body");
      if (res.statusCode == 200) {
        return ApiResponse.fromMap(body);
      } else {
        throw ApiError.fromMap(body);
      }
    } on ApiError {
      rethrow;
    } catch (e, stackTrace) {
      debugPrint("Unexpected error during deleting images: $e");
      debugPrintStack(stackTrace: stackTrace);
      throw ApiError(
          statusCode: 500, message: "Something went wrong. Please try again.");
    }
  }

  Future<ApiResponse?> saveImage(String imageUrl) async {
    try {
      final accessToken = await storage.read(key: 'accessToken');
      final res = await http.post(Uri.parse('$myIp/image/save-image'),
          headers: {"Authorization": "Bearer $accessToken"},
          body: {"imageUrl": imageUrl});
      final body = jsonDecode(res.body);
      debugPrint("Save image response body: $body");
      if (res.statusCode == 200) {
        return ApiResponse.fromMap(body);
      } else {
        throw ApiError.fromMap(body);
      }
    } on ApiError {
      rethrow;
    } catch (e, stackTrace) {
      debugPrint("Unexpected error during saving image: $e");
      debugPrintStack(stackTrace: stackTrace);
      throw ApiError(
          statusCode: 500, message: "Something went wrong. Please try again.");
    }
  }

  Future<ApiResponse?> addTransformation(
      String imagePublicId, Map<String, dynamic> transformation) async {
    try {
      final accessToken = await storage.read(key: 'accessToken');
      final res = await http.post(
        Uri.parse('$myIp/image/add-transformation'),
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json"
        },
        body: jsonEncode({
          "imagePublicId": imagePublicId,
          "transformation": transformation,
        }),
      );
      final body = jsonDecode(res.body);
      debugPrint("Add image transformation response body: $body");
      if (res.statusCode == 200) {
        return ApiResponse.fromMap(body);
      } else {
        throw ApiError.fromMap(body);
      }
    } on ApiError {
      rethrow;
    } catch (e, stackTrace) {
      debugPrint("Unexpected error during add image transformation: $e");
      debugPrintStack(stackTrace: stackTrace);
      throw ApiError(
          statusCode: 500, message: "Something went wrong. Please try again.");
    }
  }

  Future<ApiResponse?> updateTransformation(String imagePublicId,
      Map<String, dynamic> transformation, String transformationId) async {
    try {
      final accessToken = await storage.read(key: 'accessToken');
      final res = await http.post(
          Uri.parse('$myIp/image/update-transformation'),
          headers: {
            "Authorization": "Bearer $accessToken",
            "Content-Type": "application/json"
          },
          body: jsonEncode({
            "imagePublicId": imagePublicId,
            "transformation": transformation,
            "transformationId": transformationId
          }));
      final body = jsonDecode(res.body);
      debugPrint("Update image transformation response body: $body");
      if (res.statusCode == 200) {
        return ApiResponse.fromMap(body);
      } else {
        throw ApiError.fromMap(body);
      }
    } on ApiError {
      rethrow;
    } catch (e, stackTrace) {
      debugPrint("Unexpected error during update image transformation: $e");
      debugPrintStack(stackTrace: stackTrace);
      throw ApiError(
          statusCode: 500, message: "Something went wrong. Please try again.");
    }
  }

  Future<ApiResponse?> deleteTransformation(
      String imagePublicId, String transformationId) async {
    try {
      final accessToken = await storage.read(key: 'accessToken');
      final res = await http
          .post(Uri.parse('$myIp/image/delete-transformation'), headers: {
        "Authorization": "Bearer $accessToken"
      }, body: {
        "imagePublicId": imagePublicId,
        "transformationId": transformationId
      });
      final body = jsonDecode(res.body);
      debugPrint("Delete image transformation response body: $body");
      if (res.statusCode == 200) {
        return ApiResponse.fromMap(body);
      } else {
        throw ApiError.fromMap(body);
      }
    } on ApiError {
      rethrow;
    } catch (e, stackTrace) {
      debugPrint("Unexpected error during delete image transformation: $e");
      debugPrintStack(stackTrace: stackTrace);
      throw ApiError(
          statusCode: 500, message: "Something went wrong. Please try again.");
    }
  }

  Future<ApiResponse?> clearTransformation(String imagePublicId) async {
    try {
      final accessToken = await storage.read(key: 'accessToken');
      final res = await http
          .post(Uri.parse('$myIp/image/clear-transformation'), headers: {
        "Authorization": "Bearer $accessToken"
      }, body: {
        "imagePublicId": imagePublicId,
      });
      final body = jsonDecode(res.body);
      debugPrint("Delete image transformation response body: $body");
      if (res.statusCode == 200) {
        return ApiResponse.fromMap(body);
      } else {
        throw ApiError.fromMap(body);
      }
    } on ApiError {
      rethrow;
    } catch (e, stackTrace) {
      debugPrint("Unexpected error during delete image transformation: $e");
      debugPrintStack(stackTrace: stackTrace);
      throw ApiError(
          statusCode: 500, message: "Something went wrong. Please try again.");
    }
  }

  Future<ApiResponse?> saveTransformation(
      {required String imagePublicId}) async {
    try {
      final accessToken = await storage.read(key: 'accessToken');
      final res = await http.post(Uri.parse('$myIp/image/save'), headers: {
        "Authorization": "Bearer $accessToken"
      }, body: {
        "imagePublicId": imagePublicId,
      });
      final body = jsonDecode(res.body);
      debugPrint("save image transformation response body: $body");
      if (res.statusCode == 200) {
        return ApiResponse.fromMap(body);
      } else {
        throw ApiError.fromMap(body);
      }
    } on ApiError {
      rethrow;
    } catch (e, stackTrace) {
      debugPrint("Unexpected error during save image transformation: $e");
      debugPrintStack(stackTrace: stackTrace);
      throw ApiError(
          statusCode: 500, message: "Something went wrong. Please try again.");
    }
  }
}
