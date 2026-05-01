import 'dart:convert';
import 'package:creatorio/common/ip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;

import '/common/storage.dart';
import '/common/widgets/api_error.dart';
import '/common/widgets/api_response.dart';
import 'package:google_sign_in/google_sign_in.dart';

class UserRepository {
  final GoogleSignIn _signIn = GoogleSignIn.instance;

  Future<ApiResponse?> registerUser(String userName, String email,
      String password, String profilePhoto) async {
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
      }

      final res = await http.Response.fromStream(await req.send());
      final body = jsonDecode(res.body);
      debugPrint("Register Response body: $body");
      if (res.statusCode == 200) {
        return ApiResponse.fromMap(body);
      } else {
        throw ApiError.fromMap(body);
      }
    } on ApiError {
      rethrow;
    } catch (e, stackTrace) {
      debugPrint("Unexpected error during registration: $e");
      debugPrintStack(stackTrace: stackTrace);
      throw ApiError(
          statusCode: 500, message: "Something went wrong. Please try again.");
    }
  }

  Future<ApiResponse?> loginUser(String email, String password) async {
    try {
      final res = await http.post(Uri.parse('$myIp/user/auth/login'), body: {
        'email': email,
        'password': password,
      });
      final body = jsonDecode(res.body);
      debugPrint("Login Response body: $body");
      if (res.statusCode == 200) {
        return ApiResponse.fromMap(body);
      } else {
        throw ApiError.fromMap(body);
      }
    } on ApiError {
      rethrow;
    } catch (e, stackTrace) {
      debugPrint("Unexpected error during login: $e");
      debugPrintStack(stackTrace: stackTrace);
      throw ApiError(
          statusCode: 500, message: "Something went wrong. Please try again.");
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
        await storeTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
        return true;
        // return false;
      }
      return false;
    } catch (e, stackTrace) {
      debugPrint("Unexpected error during login: $e");
      debugPrintStack(stackTrace: stackTrace);
      throw ApiError(
          statusCode: 500, message: "Something went wrong. Please try again.");
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
      final body = jsonDecode(res.body);
      debugPrint("Logout Response body: $body");
      if (res.statusCode == 200) {
        return ApiResponse.fromMap(body);
      } else {
        throw ApiError.fromMap(body);
      }
    } on ApiError {
      rethrow;
    } catch (e, stackTrace) {
      debugPrint("Unexpected error during login: $e");
      debugPrintStack(stackTrace: stackTrace);
      throw ApiError(
          statusCode: 500, message: "Something went wrong. Please try again.");
    }
  }

  Future<ApiResponse?> deleteAccount() async {
    try {
      final accessToken = await storage.read(key: "accessToken");
      final res = await http.post(
          Uri.parse(
            '$myIp/user/delete-user',
          ),
          headers: {"Authorization": "Bearer $accessToken"});
      final body = jsonDecode(res.body);
      debugPrint("Logout Response body: $body");
      if (res.statusCode == 200) {
        return ApiResponse.fromMap(body);
      } else {
        throw ApiError.fromMap(body);
      }
    } on ApiError {
      rethrow;
    } catch (e, stackTrace) {
      debugPrint("Unexpected error during login: $e");
      debugPrintStack(stackTrace: stackTrace);
      throw ApiError(
          statusCode: 500, message: "Something went wrong. Please try again.");
    }
  }

  Future<ApiResponse?> changePassword(
      String oldPassword, String newPassword) async {
    try {
      final accessToken = await storage.read(key: "accessToken");
      final res =
          await http.post(Uri.parse('$myIp/user/update-password'), body: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      }, headers: {
        "Authorization": "Bearer $accessToken"
      });
      final body = jsonDecode(res.body);
      debugPrint("Change Password Response body: $body");
      if (res.statusCode == 200) {
        return ApiResponse.fromMap(body);
      } else {
        throw ApiError.fromMap(body);
      }
    } on ApiError {
      rethrow;
    } catch (e, stackTrace) {
      debugPrint("Unexpected error during login: $e");
      debugPrintStack(stackTrace: stackTrace);
      throw ApiError(
          statusCode: 500, message: "Something went wrong. Please try again.");
    }
  }

  Future<ApiResponse?> getCurrentUser() async {
    try {
      final accessToken = await storage.read(key: 'accessToken');
      final res = await http.get(Uri.parse('$myIp/user/current-user'),
          headers: {"Authorization": "Bearer $accessToken"});
      final body = jsonDecode(res.body);
      debugPrint("Current user response body: $body");
      if (res.statusCode == 200) {
        return ApiResponse.fromMap(body);
      } else {
        throw ApiError.fromMap(body);
      }
    } on ApiError {
      rethrow;
    } catch (e, stackTrace) {
      debugPrint("Unexpected error during login: $e");
      debugPrintStack(stackTrace: stackTrace);
      throw ApiError(
          statusCode: 500, message: "Something went wrong. Please try again.");
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
      final body = jsonDecode(res.body);
      debugPrint("Current user response body: $body");
      if (res.statusCode == 200) {
        return ApiResponse.fromMap(body);
      } else {
        throw ApiError.fromMap(body);
      }
    } on ApiError {
      rethrow;
    } catch (e, stackTrace) {
      debugPrint("Unexpected error during login: $e");
      debugPrintStack(stackTrace: stackTrace);
      throw ApiError(
          statusCode: 500, message: "Something went wrong. Please try again.");
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

      final body = jsonDecode(res.body);
      debugPrint("Current user response body: $body");
      if (res.statusCode == 200) {
        return ApiResponse.fromMap(body);
      } else {
        throw ApiError.fromMap(body);
      }
    } on ApiError {
      rethrow;
    } catch (e, stackTrace) {
      debugPrint("Unexpected error during login: $e");
      debugPrintStack(stackTrace: stackTrace);
      throw ApiError(
          statusCode: 500, message: "Something went wrong. Please try again.");
    }
  }

  Future<ApiResponse?> signInWithGoogle() async {
    try {
      await _signIn.initialize();

      final GoogleSignInAccount account = await _signIn.authenticate();

      final auth = account.authentication;

      final idToken = auth.idToken;

      if (idToken == null) {
        throw ApiError(statusCode: 400, message: "No ID token found");
      }
      final res = await http.post(
        Uri.parse('$myIp/auth/google/mobile'),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "idToken": idToken,
        }),
      );
      final body = jsonDecode(res.body);
      debugPrint("Current user response body: $body");
      if (res.statusCode == 200) {
        return ApiResponse.fromMap(body);
      } else {
        throw ApiError.fromMap(body);
      }
    } on ApiError {
      rethrow;
    } catch (e, stackTrace) {
      debugPrint("Unexpected error during login: $e");
      debugPrintStack(stackTrace: stackTrace);
      throw ApiError(
          statusCode: 500, message: "Something went wrong. Please try again.");
    }
  }

  Future<ApiResponse?> signInWithGithub() async {
    try {
      final result = await FlutterWebAuth2.authenticate(
        url: "https://github.com/login/oauth/authorize"
            "?client_id=Ov23lijSn5Gpp1EEBtzi"
            "&scope=user:email",
        callbackUrlScheme: "createrio",
      );

      final uri = Uri.parse(result);
      final code = uri.queryParameters['code'];

      if (code == null) {
        throw ApiError(statusCode: 400, message: "No code received");
      }
      final res = await http.post(
        Uri.parse('$myIp/auth/github/mobile'),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "code": code,
        }),
      );
      final body = jsonDecode(res.body);
      debugPrint("Github user response body: $body");
      if (res.statusCode == 200) {
        return ApiResponse.fromMap(body);
      } else {
        throw ApiError.fromMap(body);
      }
    } on ApiError {
      rethrow;
    } catch (e, stackTrace) {
      debugPrint("Unexpected error during login: $e");
      debugPrintStack(stackTrace: stackTrace);
      throw ApiError(
          statusCode: 500, message: "Something went wrong. Please try again.");
    }
  }
}
