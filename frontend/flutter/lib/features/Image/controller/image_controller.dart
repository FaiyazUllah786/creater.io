import 'dart:io';

import 'package:creatorio/features/Image/repository/image_repository.dart';
import 'package:creatorio/model/image_model.dart';
import 'package:flutter/material.dart';

import '../../../common/widgets/api_error.dart';

class ImageController extends ChangeNotifier {
  final imageRepository = ImageRepository();
  List<ImageModel> _images = [];
  bool _isLoading = false;

  List<ImageModel> get images => _images;
  bool get isLoading => _isLoading;

  List<String> _imageTransformed = [];
  List<String> get imageTransformed => _imageTransformed;

  bool _isTransforming = false;
  bool get isTransforming => _isTransforming;

  Future<void> uploadImage(File images) async {
    try {
      final res = await imageRepository.uploadImage(images);
      print("I am uploaded images");
      if (res != null && res.statusCode == 200) {
        print("images uploaded");
        final images = res.data;
        print("upload response $images");
        for (int i = 0; i < images.length; i++) {
          final ImageModel imageModel = ImageModel.fromMap(images[i]);
          print("_imageModel: $imageModel");
          if (!_images.any((image) => image.id == imageModel.id)) {
            _images.add(imageModel);
            _images.sort(
              (a, b) =>
                  a.createdAt.millisecondsSinceEpoch -
                  b.createdAt.millisecondsSinceEpoch,
            );
          }
        }
      }
    } on ApiError catch (e) {
      print("Error occured uploading images repository: $e");
    } catch (e) {
      print("Error occured in uploading images controller: $e");
    }
    notifyListeners();
    print(_images.length);
  }

  Future<void> getAllImages() async {
    try {
      _isLoading = true;
      notifyListeners();
      final res = await imageRepository.getImages();
      if (res != null && res.statusCode == 200) {
        final images = res.data;
        for (int i = 0; i < images.length; i++) {
          final ImageModel imageModel = ImageModel.fromMap(images[i]);
          print("_imageModel: $imageModel");
          if (!_images.any((image) => image.id == imageModel.id)) {
            _images.add(imageModel);
            _images.sort(
              (a, b) =>
                  a.createdAt.millisecondsSinceEpoch -
                  b.createdAt.millisecondsSinceEpoch,
            );
          }
        }
        print("image List: $_images");
      }
    } on ApiError catch (e) {
      print("Error occured fetching images repository: $e");
    } catch (e) {
      print("Error occured in fetch images controller: $e");
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteImage(String imageId) async {
    try {
      final res = await imageRepository.deleteImage(imageId);
      if (res != null && res.statusCode == 200) {
        print("Image Deleted: ${res.data[0]}");
        _images.removeWhere((image) => image.id == imageId);
      }
    } on ApiError catch (e) {
      print("Error occured delete images repository: $e");
    } catch (e) {
      print("Error occured in delete images controller: $e");
    }
    notifyListeners();
  }

  Future<void> generativeFill({
    required String imageUrl,
    String aspectRatio = "1:1",
    int? height,
    int? width,
    String gravity = "center",
  }) async {
    try {
      _isTransforming = true;
      notifyListeners();
      final res = await imageRepository.generativeFill(
        imageUrl: imageUrl,
        aspectRatio: aspectRatio,
        gravity: gravity,
      );

      if (res != null && res.statusCode == 200) {
        final transformedUrl = res.data;
        print("Transformed Url: $transformedUrl");
        // if (!_imageTransformed.contains(transformedUrl)) {
        // }
        _imageTransformed.add(transformedUrl);
        print("Length: ${_imageTransformed.length}");
      }
    } on ApiError catch (e) {
      print("Error in generativeFill: $e");
    } catch (e) {
      print("Unexpected error in generativeFill: $e");
    }
    _isTransforming = false;
    notifyListeners();
  }

  Future<void> upscaleImage({required String imageUrl}) async {
    try {
      _isTransforming = true;
      notifyListeners();
      final res = await imageRepository.upscaleImage(imageUrl);

      if (res != null && res.statusCode == 200) {
        final transformedUrl = res.data;
        print("Transformed Url: $transformedUrl");
        // if (!_imageTransformed.contains(transformedUrl)) {
        // }
        _imageTransformed.add(transformedUrl);
        print("Length: ${_imageTransformed.length}");
      }
    } on ApiError catch (e) {
      print("Error in upscael: $e");
    } catch (e) {
      print("Unexpected error in upscale: $e");
    }
    _isTransforming = false;
    notifyListeners();
  }
}
