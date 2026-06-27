import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:creatorio/core/network/dio_client.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class UnsplashPhotoUrls {
  final String regular;
  UnsplashPhotoUrls({required this.regular});
}

class UnsplashPhoto {
  final String id;
  final UnsplashPhotoUrls urls;

  UnsplashPhoto({required this.id, required this.urls});

  factory UnsplashPhoto.fromJson(Map<String, dynamic> json) {
    return UnsplashPhoto(
      id: json['id'] ?? '',
      urls: UnsplashPhotoUrls(regular: json['urls']?['regular'] ?? ''),
    );
  }
}

class UnsplashProvider extends ChangeNotifier {
  final Dio dio = DioClient.dio;

  final List<UnsplashPhoto> _photos = [];
  bool _isLoading = false;

  List<UnsplashPhoto> get photos => _photos;
  bool get isLoading => _isLoading;

  int _currentPage = 1;

  void reset() {
    _photos.clear();
    _currentPage = 1;
    notifyListeners();
  }

  Future<void> fetchPhotos(String query, {int perPage = 10}) async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      final response = await dio.get('/unsplash/photos', queryParameters: {
        'query': query,
        'page': _currentPage,
        'perPage': perPage,
      });

      final List<dynamic> results = response.data['data'] ?? [];
      _photos.addAll(results.map((e) => UnsplashPhoto.fromJson(e)).toList());
      _currentPage++;
    } catch (e) {
      debugPrint("Error fetching photos: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<File?> downloadAndSaveImage(
      String url, String photoId, Function(double) onProgress) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Trigger download tracking via our secure backend proxy
      final triggerResponse =
          await dio.post('/unsplash/photos/$photoId/download');

      // The Unsplash CDN URL is returned
      final directUrl = triggerResponse.data['data']?['url'] ?? url;

      final directory = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final randomId = DateTime.now().millisecondsSinceEpoch.toString();
      final fileName = 'Image_${timestamp}_$randomId.jpg';
      final filePath = File('${directory.path}/$fileName');

      // Use a fresh Dio instance to download the binary directly from Unsplash Edge CDN
      Dio rawDio = Dio();
      await rawDio.download(
        directUrl,
        filePath.path,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total);
          }
        },
      );
      debugPrint('Downloaded to $filePath');
      return filePath;
    } catch (e) {
      debugPrint('Error downloading image: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
