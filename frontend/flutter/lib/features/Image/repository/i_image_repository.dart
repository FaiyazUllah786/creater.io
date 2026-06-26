import 'dart:io';
import 'package:creatorio/core/models/api_response.dart';

abstract class IImageRepository {
  Future<ApiResponse?> uploadImage(File imageFiles);
}
