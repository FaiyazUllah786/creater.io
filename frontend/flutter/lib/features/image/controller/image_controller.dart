import 'package:creatorio/core/exceptions/app_exceptions.dart';
import 'dart:io';
import 'package:flutter/material.dart';

import 'package:creatorio/common/message.dart';
import 'package:creatorio/features/image/repository/image_repository.dart';
import 'package:creatorio/features/image/repository/i_image_repository.dart';
import 'package:creatorio/model/image_model.dart';
import 'package:creatorio/core/services/analytics_service.dart';

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

  late final IImageRepository imageRepository;
  final List<ImageModel> _images = [];

  ImageController({IImageRepository? repository}) {
    imageRepository = repository ?? ImageRepository();
  }

  List<ImageModel> get images => _images;

  bool _hasUnsavedChanges = false;

  bool get hasUnsavedChanges => _hasUnsavedChanges;

  String _transformedImageUrl = '';
  String get transformedImageUrl => _transformedImageUrl;
  void settransformedImageUrl(String value) {
    _transformedImageUrl = value;
    notifyListeners();
  }

  List<Map<String, dynamic>>? _transfomationList;
  List<dynamic>? get transfomationList => _transfomationList;

  int _currentPage = 1;
  bool _hasMore = true;
  bool _isPaginating = false;
  bool get isPaginating => _isPaginating;

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

      await AnalyticsService.logEvent('upload_image');

      return true;
    } on AppException catch (e) {
      debugPrint("Unexpected error during image upload: $e");

      return false;
    } catch (e, stackTrace) {
      debugPrint("Unexpected error during image upload: $e");
      debugPrintStack(stackTrace: stackTrace);
      return false;
    } finally {
      _setLoading(ImageLoadingState.idle);
    }
  }

  Future<bool> getAllImages({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
    }

    if (!_hasMore || _isPaginating) return false;

    try {
      clearMessage();
      if (refresh) {
        _message = Message("Refreshing....", MessageType.info);
        _setLoading(ImageLoadingState.fetching);
      } else {
        _isPaginating = true;
        notifyListeners();
      }

      final res =
          await imageRepository.getImages(page: _currentPage, limit: 12);
      if (res == null) {
        _message = Message("Fetch failed....", MessageType.error);
        return false;
      }

      if (refresh) _images.clear();
      final docs = res.data['docs'] as List<dynamic>? ?? [];
      final hasNextPage = res.data['hasNextPage'] as bool? ?? false;

      for (int i = 0; i < docs.length; i++) {
        final ImageModel imageModel = ImageModel.fromMap(docs[i]);
        _images.add(imageModel);
      }
      _images.sort(
        (a, b) =>
            b.createdAt.millisecondsSinceEpoch -
            a.createdAt.millisecondsSinceEpoch,
      );

      _hasMore = hasNextPage;
      if (hasNextPage) {
        _currentPage++;
      }

      if (refresh) {
        _message = Message("Your gallery is updated", MessageType.success);
      }
      return true;
    } on AppException catch (e) {
      debugPrint("Unexpected error during image fetch: $e");

      return false;
    } catch (e, stackTrace) {
      debugPrint("Unexpected error during image fetch: $e");
      debugPrintStack(stackTrace: stackTrace);
      return false;
    } finally {
      if (refresh) {
        _setLoading(ImageLoadingState.idle);
      } else {
        _isPaginating = false;
        notifyListeners();
      }
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
      _hasUnsavedChanges = false;
      _transformedImageUrl = '';
      _message = Message("Image deleted successfully", MessageType.success);

      await AnalyticsService.logEvent('delete_image');

      return true;
    } on AppException catch (e) {
      debugPrint("Unexpected error during image delete: $e");

      return false;
    } catch (e, stackTrace) {
      debugPrint("Unexpected error during image delete: $e");
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
      _hasUnsavedChanges = false;
      _message = Message("Image saved successfully", MessageType.success);

      await AnalyticsService.logEvent('save_image');

      return true;
    } on AppException catch (e) {
      _message = Message("Failed to save image", MessageType.error);
      debugPrint("Unexpected error during image save: $e");

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
      _transformedImageUrl = res.data?['previewUrl'];
      _transfomationList = List<Map<String, dynamic>>.from(
        res.data?['transfomationList'] ?? [],
      );

      _hasUnsavedChanges = true;
      _message =
          Message("Tranfomation applied successfully", MessageType.success);

      await AnalyticsService.logEvent('add_transformation');

      return true;
    } on AppException catch (e) {
      _message = Message("Failed to add transformation", MessageType.error);
      debugPrint("Unexpected error during add transformation: $e");
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
      _transformedImageUrl = res.data?['previewUrl'];
      _transfomationList = List<Map<String, dynamic>>.from(
        res.data?['transfomationList'] ?? [],
      );

      _hasUnsavedChanges = true;
      _message =
          Message("Tranfomation applied successfully", MessageType.success);

      await AnalyticsService.logEvent('update_transformation');

      return true;
    } on AppException catch (e) {
      _message = Message("Failed to update transformation", MessageType.error);
      debugPrint("Unexpected error during update transformation: $e");

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
      _transformedImageUrl = res.data?['previewUrl'];
      _transfomationList = List<Map<String, dynamic>>.from(
        res.data?['transfomationList'] ?? [],
      );

      _message =
          Message("Tranfomation delete successfully", MessageType.success);

      await AnalyticsService.logEvent('delete_transformation');

      return true;
    } on AppException catch (e) {
      _message = Message("Failed to delete transformation", MessageType.error);
      debugPrint("Unexpected error during image transformation: $e");
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
      _hasUnsavedChanges = false;
      _transfomationList = [];
      _transformedImageUrl = "";

      final res = await imageRepository.clearTransformation(imagePublicId);
      if (res == null) {
        _message = Message("Failed to clear transformation", MessageType.error);
        return false;
      }
      _transformedImageUrl = res.data?['previewUrl'];
      _message =
          Message("Tranfomation cleared successfully", MessageType.success);

      await AnalyticsService.logEvent('clear_transformation');

      return true;
    } on AppException catch (e) {
      _message = Message("Failed to clear transformation", MessageType.error);
      debugPrint("Unexpected error during transformation clear: $e");
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
