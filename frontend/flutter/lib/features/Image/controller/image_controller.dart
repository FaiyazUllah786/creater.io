import 'dart:io';
import 'package:flutter/material.dart';

import 'package:creatorio/common/message.dart';
import 'package:creatorio/features/Image/repository/image_repository.dart';
import 'package:creatorio/model/image_model.dart';

import '../../../common/widgets/api_error.dart';

enum ImageLoadingState {
  idle,
  uploading,
  fetching,
  deleting,
  saving,
  transforming,
}

class ImageController extends ChangeNotifier {
  ImageLoadingState _loadingState = ImageLoadingState.idle;

  ImageLoadingState get loadingState => _loadingState;

  Message? _message;

  Message? get message => _message;

  void _setLoading(ImageLoadingState state) {
    _loadingState = state;
    notifyListeners();
  }

  void clearMessage() {
    _message = null;
  }

  final imageRepository = ImageRepository();
  final List<ImageModel> _images = [];
  bool _hasUnsavedChanges = false;

  List<ImageModel> get images => _images;
  bool get hasUnsavedChanges => _hasUnsavedChanges;

  String? _transformedImageUrl;
  List<Map<String, dynamic>>? _transfomationList;
  List<dynamic>? get transfomationList => _transfomationList;
  String? get transformedImageUrl => _transformedImageUrl;

  Future<bool> uploadImage(File images) async {
    try {
      clearMessage();
      _setLoading(ImageLoadingState.uploading);

      final res = await imageRepository.uploadImage(images);
      if (res == null) {
        _message = Message("Image upload failed", MessageType.error);

        return false;
      }
      final imagesRes = res.data;

      for (int i = 0; i < imagesRes.length; i++) {
        final ImageModel imageModel = ImageModel.fromMap(imagesRes[i]);
        if (!_images.any((image) => image.id == imageModel.id)) {
          _images.add(imageModel);
        }
      }
      _images.sort(
        (a, b) =>
            a.createdAt.millisecondsSinceEpoch -
            b.createdAt.millisecondsSinceEpoch,
      );
      _message = Message("Image uploaded successfully", MessageType.success);
      return true;
    } on ApiError catch (e) {
      return false;
    } catch (e, stackTrace) {
      debugPrint("Unexpected error during image upload: $e");
      debugPrintStack(stackTrace: stackTrace);
      return false;
    } finally {
      _setLoading(ImageLoadingState.idle);
    }
  }

  Future<bool> getAllImages() async {
    try {
      clearMessage();
      _message = Message("Refreshing....", MessageType.info);
      _setLoading(ImageLoadingState.fetching);
      final res = await imageRepository.getImages();
      if (res == null) {
        _message = Message("Refresh failed....", MessageType.error);
        return false;
      }
      final images = res.data;
      for (int i = 0; i < images.length; i++) {
        final ImageModel imageModel = ImageModel.fromMap(images[i]);
        if (!_images.any((image) => image.id == imageModel.id)) {
          _images.add(imageModel);
        }
      }
      _images.sort(
        (a, b) =>
            a.createdAt.millisecondsSinceEpoch -
            b.createdAt.millisecondsSinceEpoch,
      );
      _message = Message("Your gallery is updated", MessageType.success);
      return true;
    } on ApiError catch (e) {
      return false;
    } catch (e, stackTrace) {
      debugPrint("Unexpected error during image upload: $e");
      debugPrintStack(stackTrace: stackTrace);
      return false;
    } finally {
      _setLoading(ImageLoadingState.idle);
    }
  }

  Future<bool> deleteImage(String imageId) async {
    try {
      clearMessage();
      _message = Message("Deleting image", MessageType.info);
      _setLoading(ImageLoadingState.deleting);

      final res = await imageRepository.deleteImage(imageId);
      if (res == null) {
        _message = Message("Image deletion failed", MessageType.error);

        return false;
      }
      _images.removeWhere((image) => image.id == imageId);
      _message = Message("Image deleted successfully", MessageType.success);

      return true;
    } on ApiError catch (e) {
      return false;
    } catch (e, stackTrace) {
      debugPrint("Unexpected error during image upload: $e");
      debugPrintStack(stackTrace: stackTrace);
      return false;
    } finally {
      _setLoading(ImageLoadingState.idle);
    }
  }

  Future<bool> saveImage(String imageUrl) async {
    try {
      clearMessage();
      _setLoading(ImageLoadingState.saving);

      final res = await imageRepository.saveImage(imageUrl);
      if (res == null) {
        _message = Message("Failed to save image", MessageType.error);
        return false;
      }
      _message = Message("Image saved successfully", MessageType.success);
      return true;
    } on ApiError catch (e) {
      _message = Message("Failed to save image", MessageType.error);
      return false;
    } catch (e, stackTrace) {
      debugPrint("Unexpected error during image save: $e");
      debugPrintStack(stackTrace: stackTrace);
      return false;
    } finally {
      _setLoading(ImageLoadingState.idle);
    }
  }

  Future<bool> addTransformation(
      String imagePublicId, Map<String, dynamic> transformation) async {
    try {
      clearMessage();
      _setLoading(ImageLoadingState.transforming);

      final res = await imageRepository.addTransformation(
          imagePublicId, transformation);
      if (res == null) {
        _message = Message("Failed to add transformation", MessageType.error);
        return false;
      }
      _transformedImageUrl = res.data?['resUrl'];
      _transfomationList = List<Map<String, dynamic>>.from(
        res.data?['transfomationList'] ?? [],
      );
      print(_transfomationList);

      _hasUnsavedChanges = true;
      _message =
          Message("Tranfomation applied successfully", MessageType.success);
      return true;
    } on ApiError catch (e) {
      _message = Message("Failed to add transformation", MessageType.error);
      return false;
    } catch (e, stackTrace) {
      debugPrint("Unexpected error during image transformation: $e");
      debugPrintStack(stackTrace: stackTrace);
      return false;
    } finally {
      _setLoading(ImageLoadingState.idle);
    }
  }

  Future<bool> updateTransformation(String imagePublicId,
      Map<String, dynamic> transformation, String transformationId) async {
    try {
      clearMessage();
      _setLoading(ImageLoadingState.transforming);

      final res = await imageRepository.updateTransformation(
          imagePublicId, transformation, transformationId);
      if (res == null) {
        _message =
            Message("Failed to update transformation", MessageType.error);
        return false;
      }
      _transformedImageUrl = res.data?['resUrl'];
      _transfomationList = List<Map<String, dynamic>>.from(
        res.data?['transfomationList'] ?? [],
      );
      print(_transfomationList);

      _hasUnsavedChanges = true;
      _message =
          Message("Tranfomation applied successfully", MessageType.success);
      return true;
    } on ApiError catch (e) {
      _message = Message("Failed to update transformation", MessageType.error);
      return false;
    } catch (e, stackTrace) {
      debugPrint("Unexpected error during image transformation: $e");
      debugPrintStack(stackTrace: stackTrace);
      return false;
    } finally {
      _setLoading(ImageLoadingState.idle);
    }
  }

  Future<bool> deleteTransformation(
      String imagePublicId, String transformationId) async {
    try {
      clearMessage();
      _setLoading(ImageLoadingState.transforming);

      final res = await imageRepository.deleteTransformation(
          imagePublicId, transformationId);
      if (res == null) {
        _message =
            Message("Failed to delete transformation", MessageType.error);
        return false;
      }
      _transformedImageUrl = res.data?['resUrl'];
      _transfomationList = List<Map<String, dynamic>>.from(
        res.data?['transfomationList'] ?? [],
      );
      print(_transfomationList);

      _hasUnsavedChanges = true;
      _message =
          Message("Tranfomation delete successfully", MessageType.success);
      return true;
    } on ApiError catch (e) {
      _message = Message("Failed to delete transformation", MessageType.error);
      return false;
    } catch (e, stackTrace) {
      debugPrint("Unexpected error during image transformation delete: $e");
      debugPrintStack(stackTrace: stackTrace);
      return false;
    } finally {
      _setLoading(ImageLoadingState.idle);
    }
  }

  Future<bool> clearTransformation(String imagePublicId) async {
    try {
      clearMessage();
      _setLoading(ImageLoadingState.transforming);

      final res = await imageRepository.clearTransformation(imagePublicId);
      if (res == null) {
        _message = Message("Failed to clear transformation", MessageType.error);
        return false;
      }
      _transformedImageUrl = res.data?['resUrl'];
      _hasUnsavedChanges = false;
      _message =
          Message("Tranfomation cleared successfully", MessageType.success);
      return true;
    } on ApiError catch (e) {
      _message = Message("Failed to clear transformation", MessageType.error);
      return false;
    } catch (e, stackTrace) {
      debugPrint("Unexpected error during image transformation clear: $e");
      debugPrintStack(stackTrace: stackTrace);
      return false;
    } finally {
      _setLoading(ImageLoadingState.idle);
    }
  }
}
