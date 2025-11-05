import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:unsplash_client/unsplash_client.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class UnsplashProvider extends ChangeNotifier {
  late UnsplashClient client;

  UnsplashProvider() {
    client = UnsplashClient(
      settings: ClientSettings(
        debug: true,
        credentials: AppCredentials(
          accessKey: dotenv.env['UNSPLASH_ACCESS_KEY'] ?? '',
          secretKey: dotenv.env['UNSPLASH_SECRET_KEY'] ?? '',
        ),
      ),
    );
  }

  final List<Photo> _photos = [];
  bool _isLoading = false;

  List<Photo> get photos => _photos;
  bool get isLoading => _isLoading;

  int _currentPage = 1;

  Future<void> fetchPhotos(String query, {int perPage = 10}) async {
    if (_isLoading) return; // Prevent duplicate requests
    _isLoading = true;

    try {
      final response = await client.search
          .photos(
            query,
            page: _currentPage,
            perPage: perPage,
          )
          .goAndGet();
      _photos.addAll(response.results);
      _currentPage++;
    } finally {
      _isLoading = false;
    }
    notifyListeners();
  }

  Future<File?> downloadAndSaveImage(
      String url, Function(double) onProgress) async {
    try {
      Dio dio = Dio();

      //get the directory to save the image
      final directory = await getTemporaryDirectory();

      // Generate a custom filename
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final randomId = DateTime.now().millisecondsSinceEpoch.toString();
      final fileName = 'Image_${timestamp}_$randomId.jpg';

      // Save the image to the file
      final filePath = File('${directory.path}/$fileName');

      //start download
      print("Unsplash Image Url: $url");
      // Fetch the image bytes from the URL
      final response = await dio.download(
        url,
        filePath.path,
        onReceiveProgress: (recieved, total) {
          if (total != -1) {
            onProgress(recieved / total);
          }
        },
      );
      print("Image downloaded successfully $filePath");
      print(response.data);
      return filePath;
    } catch (e) {
      debugPrint('Error downloading image: $e');
      return null;
    }
  }
}
