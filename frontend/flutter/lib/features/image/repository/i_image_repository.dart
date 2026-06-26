import 'dart:io';
import 'package:creatorio/core/models/api_response.dart';

abstract class IImageRepository {
  Future<ApiResponse?> uploadImage(File imageFiles);
  Future<ApiResponse?> getImages();
  Future<ApiResponse?> deleteImage(String imageId);
  Future<ApiResponse?> saveImage(String imageUrl);
  Future<ApiResponse?> addTransformation(
      String imagePublicId, Map<String, dynamic> transformation);
  Future<ApiResponse?> updateTransformation(String imagePublicId,
      Map<String, dynamic> transformation, String transformationId);
  Future<ApiResponse?> deleteTransformation(
      String imagePublicId, String transformationId);
  Future<ApiResponse?> clearTransformation(String imagePublicId);
  Future<ApiResponse?> saveTransformation({required String imagePublicId});
}
