import 'dart:convert';
import 'package:creatorio/common/ip.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '/common/storage.dart';
import '/common/widgets/api_error.dart';
import '/common/widgets/api_response.dart';

class UserRepository {
  Future<dynamic> registerUser(BuildContext context, String userName,
      String email, String password, String profilePhoto) async {
    try {
      final req =
          http.MultipartRequest('POST', Uri.parse('$myIp/user/auth/register'));
      req.fields['userName'] = userName;
      req.fields['email'] = email;
      req.fields['password'] = password;

      if (profilePhoto.isNotEmpty) {
        final image =
            await http.MultipartFile.fromPath('profilePhoto', profilePhoto);
        req.files.add(image);
      } else {
        throw ApiError(statusCode: 400, message: 'Profile photo is required');
      }

      final res = await http.Response.fromStream(await req.send());
      final data = jsonDecode(res.body);
      print(data['message']);
      if (res.statusCode == 200) {
        print(data);
        return ApiResponse.fromMap(data);
      } else {
        print('Registration failed: ${res.statusCode} - ${res.body}');
        throw ApiError.fromMap(data);
      }
    } on ApiError catch (e) {
      print(e);
      rethrow;
    } catch (e) {
      print('Something went wrong' + e.toString());
    }
  }

  Future<ApiResponse?> loginUser(String email, String password) async {
    try {
      final res = await http.post(Uri.parse('$myIp/user/auth/login'), body: {
        'email': email,
        'password': password,
      });
      print("logged in response: $res");
      final body = jsonDecode(res.body);
      print("Response Data: $body");
      if (res.statusCode == 200) {
        final res = ApiResponse.fromMap(body);
        print(res);
        final accessToken = res.data['accessToken'];
        final refreshToken = res.data['refreshToken'];
        print("New Access Token : $accessToken");
        print("New Refresh Token : $refreshToken");
        await storeTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
        return res;
      } else {
        print("login failed: " + body['message']);
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

  Future<bool> refreshTokens() async {
    print("refreshing access and refresh token");
    try {
      final refreshToken = await storage.read(key: 'refreshToken');
      if (refreshToken == null) return false;
      print("found refreshToken: $refreshToken");
      final response = await http.post(
        Uri.parse('$myIp/user/auth/refresh-tokens'),
        body: {'refreshToken': refreshToken},
      );
      print("Response of refresh func: ${response.statusCode}");
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        print(body);
        final res = ApiResponse.fromMap(body);
        print(res);
        final accessToken = res.data['accessToken'];
        final refreshToken = res.data['refreshToken'];
        print("New Access Token : $accessToken");
        print("New Refresh Token : $refreshToken");
        await storeTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
        return true;
        // return false;
      }
      return false;
    } catch (e) {
      print("Error refreshing token: $e");
      return false;
    }
  }

  Future<ApiResponse?> logout() async {
    try {
      final accessToken = await storage.read(key: "accessToken");
      final res = await http.post(
          Uri.parse(
            '$myIp/user/auth/logout',
          ),
          headers: {"Authorization": "Bearer $accessToken"});
      print("logout response: $res");
      final data = jsonDecode(res.body);
      print("Response Data: $data");
      if (res.statusCode == 200) {
        return ApiResponse.fromMap(data);
      } else {
        print("logout failed: " + data['message']);
        throw ApiError.fromMap(data);
      }
    } on ApiError catch (e) {
      print(e);
      rethrow;
    } catch (e) {
      print("Something went wrong" + e.toString());
      rethrow;
    }
  }

  Future<ApiResponse?> getCurrentUser() async {
    try {
      //  final accessToken = res.data['accessToken'];
      final accessToken = await storage.read(key: 'accessToken');

      final res = await http.get(Uri.parse('$myIp/user/current-user'),
          headers: {"Authorization": "Bearer $accessToken"});
      final body = jsonDecode(res.body);
      print(body);
      if (res.statusCode == 200) {
        final res = ApiResponse.fromMap(body);
        print("Current User: $res");
        return res;
      } else {
        print("login failed: " + body['message']);
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

  Future<ApiResponse?> updateProfilePhoto(String profilePhoto) async {
    try {
      final accessToken = await storage.read(key: "accessToken");
      final req = http.MultipartRequest(
        'POST',
        Uri.parse('$myIp/user/profile-photo'),
      );
      if (profilePhoto.isNotEmpty) {
        final image =
            await http.MultipartFile.fromPath('profilePhoto', profilePhoto);
        req.files.add(image);
        req.headers["Authorization"] = "Bearer $accessToken";
      } else {
        throw ApiError(statusCode: 400, message: 'Profile photo is required');
      }

      final res = await http.Response.fromStream(await req.send());
      final data = jsonDecode(res.body);
      print(data['message']);
      if (res.statusCode == 200) {
        print(data);
        return ApiResponse.fromMap(data);
      } else {
        print('Registration failed: ${res.statusCode} - ${res.body}');
        throw ApiError.fromMap(data);
      }
    } on ApiError catch (e) {
      print(e);
      rethrow;
    } catch (e) {
      print(e);
    }
  }

  Future<ApiResponse?> updateUserProfile(
      String email, String userName, String firstName, String lastName) async {
    try {
      final accessToken = await storage.read(key: "accessToken");
      if (accessToken == null) {
        throw ApiError(statusCode: 400, message: "AccessToken Expired");
      }
      final res =
          await http.post(Uri.parse("$myIp/user/update-account"), headers: {
        "Authorization": "Bearer $accessToken"
      }, body: {
        "userName": userName,
        "email": email,
        "firstName": firstName,
        "lastName": lastName,
      });

      final data = jsonDecode(res.body);
      print(data['message']);
      if (res.statusCode == 200) {
        print(data);
        return ApiResponse.fromMap(data);
      } else {
        print('Registration failed: ${res.statusCode} - ${res.body}');
        throw ApiError.fromMap(data);
      }
    } on ApiError catch (e) {
      print(e);
      rethrow;
    } catch (e) {
      print(e);
    }
  }
}
