import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import '../../../common/ip.dart';
import '../../../common/storage.dart';
import '../../../common/widgets/api_error.dart';
import '../../../common/widgets/api_response.dart';

class ImageRepository {
  Future<ApiResponse?> uploadImage(File imageFiles) async {
    try {
      //  final accessToken = res.data['accessToken'];
      print("Uploading images in upload image repository");
      final accessToken = await storage.read(key: 'accessToken');
      final req =
          http.MultipartRequest("POST", Uri.parse("$myIp/image/upload"));
      req.headers["Authorization"] = "Bearer $accessToken";
      print("assigning image to req");
      final images =
          await http.MultipartFile.fromPath("images", imageFiles.path);
      print("image assigned to req");
      req.files.add(images);
      final res = await http.Response.fromStream(await req.send());
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        final data = ApiResponse.fromMap(body);
        print(" Image Data: ${data.toMap()}");
        return data;
      } else {
        print("upload image failed: " + body['message']);
        throw ApiError.fromMap(body);
      }
    } on ApiError catch (e) {
      print(e);
      rethrow;
    } catch (e) {
      print("Something went wrong" + e.toString());
      rethrow;
    }
  }

  Future<ApiResponse?> getImages() async {
    try {
      final accessToken = await storage.read(key: 'accessToken');
      final res = await http.get(Uri.parse('$myIp/image/get-images'),
          headers: {"Authorization": "Bearer $accessToken"});
      final body = jsonDecode(res.body);
      print(body);
      if (res.statusCode == 200) {
        final apiRes = ApiResponse.fromMap(body);
        print("Image Data : ${apiRes.toMap()}");
        return apiRes;
      } else {
        print("fetch images failed: " + body['message']);
        throw ApiError.fromMap(body);
      }
    } on ApiError catch (e) {
      print(e);
      rethrow;
    } catch (e) {
      print("Something went wrong" + e.toString());
      rethrow;
    }
  }

  Future<ApiResponse?> deleteImage(String imageId) async {
    try {
      final accessToken = await storage.read(key: 'accessToken');
      final res = await http.post(Uri.parse('$myIp/image/delete-image'),
          headers: {"Authorization": "Bearer $accessToken"},
          body: {"imageId": imageId});
      final body = jsonDecode(res.body);
      print(body);
      if (res.statusCode == 200) {
        final apiRes = ApiResponse.fromMap(body);
        print("Image deleted : ${apiRes.toMap()}");
        return apiRes;
      } else {
        print("delete images failed: " + body['message']);
        throw ApiError.fromMap(body);
      }
    } on ApiError catch (e) {
      print(e);
      rethrow;
    } catch (e) {
      print("Something went wrong" + e.toString());
      rethrow;
    }
  }

  Future<ApiResponse?> generativeFill(
      {required imageUrl,
      required String aspectRatio,
      int? height,
      int? width,
      required String gravity}) async {
    try {
      final accessToken = await storage.read(key: 'accessToken');
      final res =
          await http.post(Uri.parse('$myIp/image/generative-fill'), headers: {
        "Authorization": "Bearer $accessToken"
      }, body: {
        "imageUrl": imageUrl,
        "aspectRatio": aspectRatio,
        // "height": height,
        // "width": width,
        "gravity": gravity
      });
      final body = jsonDecode(res.body);
      print(body);
      if (res.statusCode == 200) {
        final apiRes = ApiResponse.fromMap(body);
        print("Image Transformed (Generative Fill) : ${apiRes.toMap()}");
        return apiRes;
      } else {
        print("Transformed images failed: " + body['message']);
        throw ApiError.fromMap(body);
      }
    } on ApiError catch (e) {
      print(e);
      rethrow;
    } catch (e) {
      print("Something went wrong" + e.toString());
      rethrow;
    }
  }

  Future<ApiResponse?> upscaleImage(String imageUrl) async {
    try {
      final accessToken = await storage.read(key: 'accessToken');
      final res =
          await http.post(Uri.parse('$myIp/image/image-upscale'), headers: {
        "Authorization": "Bearer $accessToken"
      }, body: {
        "imageUrl": imageUrl,
      });
      final body = jsonDecode(res.body);
      print(body);
      if (res.statusCode == 200) {
        final apiRes = ApiResponse.fromMap(body);
        print("Image Transformed (Upscale) : ${apiRes.toMap()}");
        return apiRes;
      } else {
        print("Transformed images failed: " + body['message']);
        throw ApiError.fromMap(body);
      }
    } on ApiError catch (e) {
      print(e);
      rethrow;
    } catch (e) {
      print("Something went wrong" + e.toString());
      rethrow;
    }
  }
}
