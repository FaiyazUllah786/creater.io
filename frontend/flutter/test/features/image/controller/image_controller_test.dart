import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:creatorio/features/image/controller/image_controller.dart';
import 'package:creatorio/features/image/repository/i_image_repository.dart';
import 'package:creatorio/core/models/api_response.dart';
import 'package:creatorio/core/exceptions/app_exceptions.dart';
import 'package:creatorio/common/message.dart';

class MockImageRepository implements IImageRepository {
  final Future<ApiResponse?> Function(File)? mockUploadImage;
  final Future<ApiResponse?> Function(int, int)? mockGetImages;
  final Future<ApiResponse?> Function(String)? mockDeleteImage;
  final Future<ApiResponse?> Function(String)? mockSaveImage;
  final Future<ApiResponse?> Function(String, Map<String, dynamic>)?
      mockAddTransformation;
  final Future<ApiResponse?> Function(String)? mockClearTransformation;

  MockImageRepository({
    this.mockUploadImage,
    this.mockGetImages,
    this.mockDeleteImage,
    this.mockSaveImage,
    this.mockAddTransformation,
    this.mockClearTransformation,
  });

  @override
  Future<ApiResponse?> uploadImage(File imageFiles) async {
    if (mockUploadImage != null) {
      return mockUploadImage!(imageFiles);
    }
    return null;
  }

  @override
  Future<ApiResponse?> getImages({int page = 1, int limit = 10}) async {
    if (mockGetImages != null) {
      return mockGetImages!(page, limit);
    }
    return null;
  }

  @override
  Future<ApiResponse?> deleteImage(String imageId) async {
    if (mockDeleteImage != null) {
      return mockDeleteImage!(imageId);
    }
    return null;
  }

  @override
  Future<ApiResponse?> saveImage(String imageUrl) async {
    if (mockSaveImage != null) {
      return mockSaveImage!(imageUrl);
    }
    return null;
  }

  @override
  Future<ApiResponse?> addTransformation(
      String imagePublicId, Map<String, dynamic> transformation) async {
    if (mockAddTransformation != null) {
      return mockAddTransformation!(imagePublicId, transformation);
    }
    return null;
  }

  @override
  Future<ApiResponse?> clearTransformation(String imagePublicId) async {
    if (mockClearTransformation != null) {
      return mockClearTransformation!(imagePublicId);
    }
    return null;
  }

  @override
  Future<ApiResponse?> saveTransformation({required String imagePublicId}) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse?> updateTransformation(String imagePublicId,
      Map<String, dynamic> transformation, String transformationId) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse?> deleteTransformation(
      String imagePublicId, String transformationId) {
    throw UnimplementedError();
  }
}

void main() {
  group('ImageController', () {
    test('getImages succeeds and populates images list', () async {
      final mockRepo = MockImageRepository(
        mockGetImages: (page, limit) async => ApiResponse(
          statusCode: 200,
          success: true,
          message: 'Success',
          data: {
            'docs': [
              {
                '_id': '1',
                'secureUrl': 'http://image1.com',
                'publicId': 'pub1',
                'height': 800,
                'width': 600,
                'author': 'user123',
                'createdAt': '2023-01-01T00:00:00.000Z',
              }
            ],
            'hasNextPage': false,
          },
        ),
      );
      final controller = ImageController(repository: mockRepo);

      final result = await controller.getAllImages(refresh: true);

      expect(result, isTrue);
      expect(controller.images.length, 1);
      expect(controller.images.first.id, '1');
      expect(controller.message?.message, 'Your gallery is updated');
      expect(controller.message?.messageType, MessageType.success);
    });

    test('getImages handles failures gracefully', () async {
      final mockRepo = MockImageRepository(
        mockGetImages: (page, limit) async => null,
      );
      final controller = ImageController(repository: mockRepo);

      final result = await controller.getAllImages(refresh: true);

      expect(result, isFalse);
      expect(controller.message?.message, 'Fetch failed....');
      expect(controller.message?.messageType, MessageType.error);
    });

    test('getImages handles exceptions', () async {
      final mockRepo = MockImageRepository(
        mockGetImages: (page, limit) async {
          throw ServerException(500, 'Server error');
        },
      );
      final controller = ImageController(repository: mockRepo);

      final result = await controller.getAllImages(refresh: true);

      expect(result, isFalse);
    });

    test('deleteImage succeeds', () async {
      final mockRepo = MockImageRepository(
        mockDeleteImage: (id) async => ApiResponse(
          statusCode: 200,
          success: true,
          message: 'Deleted',
          data: {},
        ),
      );
      final controller = ImageController(repository: mockRepo);

      final result = await controller.deleteImage('img123');

      expect(result, isTrue);
      expect(controller.message?.message, 'Image deleted successfully');
      expect(controller.message?.messageType, MessageType.success);
    });

    test('addTransformation updates previewUrl', () async {
      final mockRepo = MockImageRepository(
        mockAddTransformation: (pubId, trans) async => ApiResponse(
          statusCode: 200,
          success: true,
          message: 'Transformed',
          data: {
            'previewUrl': 'http://preview.url',
            'transfomationList': [],
          },
        ),
      );
      final controller = ImageController(repository: mockRepo);

      final result =
          await controller.addTransformation('pubId', {'type': 'blur'});

      expect(result, isTrue);
      expect(controller.transformedImageUrl, 'http://preview.url');
      expect(controller.hasUnsavedChanges, isTrue);
      expect(controller.message?.message, 'Tranfomation applied successfully');
    });

    test('clearTransformation resets state', () async {
      final mockRepo = MockImageRepository(
        mockClearTransformation: (pubId) async => ApiResponse(
          statusCode: 200,
          success: true,
          message: 'Cleared',
          data: {
            'previewUrl': 'http://original.url',
          },
        ),
      );
      final controller = ImageController(repository: mockRepo);
      controller.settransformedImageUrl('http://preview.url');

      final result = await controller.clearTransformation('pubId');

      expect(result, isTrue);
      expect(controller.transformedImageUrl, 'http://original.url');
      expect(controller.hasUnsavedChanges, isFalse);
    });
  });
}
