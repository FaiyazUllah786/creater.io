import 'dart:convert';
import 'package:creatorio/common/ip.dart';
import 'package:creatorio/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;

import '/common/widgets/api_error.dart';
import '/common/widgets/api_response.dart';
import 'package:google_sign_in/google_sign_in.dart';

class UserRepository {
  final GoogleSignIn _signIn = GoogleSignIn.instance;
  final Dio dio = DioClient.dio;
  Future<ApiResponse?> registerUser(String userName, String email,
      String password, String profilePhoto) async {
    try {
      FormData formData = FormData.fromMap({
        'userName': userName,
        'email': email,
        'password': password,
      });

      if (profilePhoto.isNotEmpty) {
        formData.files.add(
          MapEntry(
            'profilePhoto',
            await MultipartFile.fromFile(profilePhoto),
          ),
        );
      }

      final response = await dio.post(
        '/user/auth/register',
        data: formData,
      );
      return ApiResponse.fromMap(response.data);
    } on DioException catch (e, stackTrace) {
      debugPrint("Register Error: ${e.response?.data}");
      debugPrintStack(stackTrace: stackTrace);

      if (e.response?.data != null) {
        throw ApiError.fromMap(e.response!.data);
      }

      throw ApiError(
        statusCode: 500,
        message: "Network error occurred",
      );
    } catch (e, stackTrace) {
      debugPrint("Unexpected error during registration: $e");

      debugPrintStack(stackTrace: stackTrace);

      throw ApiError(
        statusCode: 500,
        message: "Something went wrong. Please try again.",
      );
    }
  }

  Future<ApiResponse?> loginUser(String email, String password) async {
    try {
      final res = await dio.post('/user/auth/login', data: {
        'email': email,
        'password': password,
      });

      debugPrint("Login Response: ${res.data}");

      return ApiResponse.fromMap(
        res.data,
      );
    } on DioException catch (e, stackTrace) {
      debugPrint("Login Error: ${e.response?.data}");

      debugPrintStack(stackTrace: stackTrace);

      if (e.response?.data != null) {
        throw ApiError.fromMap(
          e.response!.data,
        );
      }

      throw ApiError(
        statusCode: 500,
        message: "Network error occurred",
      );
    } catch (e, stackTrace) {
      debugPrint("Unexpected error during login: $e");

      debugPrintStack(stackTrace: stackTrace);

      throw ApiError(
        statusCode: 500,
        message: "Something went wrong. Please try again.",
      );
    }
  }

  Future<ApiResponse?> logout() async {
    try {
      final res = await dio.post('/user/auth/logout');
      debugPrint("Logout Response: ${res.data}");

      return ApiResponse.fromMap(
        res.data,
      );
    } on DioException catch (e, stackTrace) {
      debugPrint("Logout Error: ${e.response?.data}");

      debugPrintStack(stackTrace: stackTrace);

      if (e.response?.data != null) {
        throw ApiError.fromMap(
          e.response!.data,
        );
      }

      throw ApiError(
        statusCode: 500,
        message: "Network error occurred",
      );
    } catch (e, stackTrace) {
      debugPrint("Unexpected error during logout: $e");

      debugPrintStack(stackTrace: stackTrace);

      throw ApiError(
        statusCode: 500,
        message: "Something went wrong. Please try again.",
      );
    }
  }

  Future<ApiResponse?> deleteAccount() async {
    try {
      final res = await dio.post('/user/delete-user');

      debugPrint("Delete account Response: ${res.data}");

      return ApiResponse.fromMap(
        res.data,
      );
    } on DioException catch (e, stackTrace) {
      debugPrint("Delete account Error: ${e.response?.data}");

      debugPrintStack(stackTrace: stackTrace);

      if (e.response?.data != null) {
        throw ApiError.fromMap(
          e.response!.data,
        );
      }

      throw ApiError(
        statusCode: 500,
        message: "Network error occurred",
      );
    } catch (e, stackTrace) {
      debugPrint("Unexpected error during delete account: $e");

      debugPrintStack(stackTrace: stackTrace);

      throw ApiError(
        statusCode: 500,
        message: "Something went wrong. Please try again.",
      );
    }
  }

  Future<ApiResponse?> changePassword(
      String oldPassword, String newPassword) async {
    try {
      final res = await dio.post('/user/update-password', data: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      });
      debugPrint("change password Response: ${res.data}");

      return ApiResponse.fromMap(
        res.data,
      );
    } on DioException catch (e, stackTrace) {
      debugPrint("Change password Error: ${e.response?.data}");

      debugPrintStack(stackTrace: stackTrace);

      if (e.response?.data != null) {
        throw ApiError.fromMap(
          e.response!.data,
        );
      }

      throw ApiError(
        statusCode: 500,
        message: "Network error occurred",
      );
    } catch (e, stackTrace) {
      debugPrint("Unexpected error during change password: $e");

      debugPrintStack(stackTrace: stackTrace);

      throw ApiError(
        statusCode: 500,
        message: "Something went wrong. Please try again.",
      );
    }
  }

  Future<ApiResponse?> getCurrentUser() async {
    try {
      final res = await dio.get('/user/current-user');
      debugPrint("Current user Response: ${res.data}");

      return ApiResponse.fromMap(
        res.data,
      );
    } on DioException catch (e, stackTrace) {
      debugPrint("Current user Error: ${e.response?.data}");

      debugPrintStack(stackTrace: stackTrace);

      if (e.response?.data != null) {
        throw ApiError.fromMap(
          e.response!.data,
        );
      }

      throw ApiError(
        statusCode: 500,
        message: "Network error occurred",
      );
    } catch (e, stackTrace) {
      debugPrint("Unexpected error during current user: $e");

      debugPrintStack(stackTrace: stackTrace);

      throw ApiError(
        statusCode: 500,
        message: "Something went wrong. Please try again.",
      );
    }
  }

  Future<ApiResponse?> updateProfilePhoto(String profilePhoto) async {
    try {
      FormData formData = FormData();

      if (profilePhoto.isNotEmpty) {
        formData.files.add(
          MapEntry(
            'profilePhoto',
            await MultipartFile.fromFile(profilePhoto),
          ),
        );
      }

      final res = await dio.post(
        '/user/profile-photo',
        data: formData,
      );

      debugPrint("Update profile photo Response: ${res.data}");

      return ApiResponse.fromMap(
        res.data,
      );
    } on DioException catch (e, stackTrace) {
      debugPrint("Update profile photo Error: ${e.response?.data}");

      debugPrintStack(stackTrace: stackTrace);

      if (e.response?.data != null) {
        throw ApiError.fromMap(
          e.response!.data,
        );
      }

      throw ApiError(
        statusCode: 500,
        message: "Network error occurred",
      );
    } catch (e, stackTrace) {
      debugPrint("Unexpected error during update profile photo: $e");

      debugPrintStack(stackTrace: stackTrace);

      throw ApiError(
        statusCode: 500,
        message: "Something went wrong. Please try again.",
      );
    }
  }

  Future<ApiResponse?> updateUserProfile(
      String email, String userName, String firstName, String lastName) async {
    try {
      final res = await dio.post('/user/update-account', data: {
        "userName": userName,
        "email": email,
        "firstName": firstName,
        "lastName": lastName,
      });

      debugPrint("Update user profile Response: ${res.data}");

      return ApiResponse.fromMap(
        res.data,
      );
    } on DioException catch (e, stackTrace) {
      debugPrint("Update user profile Error: ${e.response?.data}");

      debugPrintStack(stackTrace: stackTrace);

      if (e.response?.data != null) {
        throw ApiError.fromMap(
          e.response!.data,
        );
      }

      throw ApiError(
        statusCode: 500,
        message: "Network error occurred",
      );
    } catch (e, stackTrace) {
      debugPrint("Unexpected error during update user profile: $e");

      debugPrintStack(stackTrace: stackTrace);

      throw ApiError(
        statusCode: 500,
        message: "Something went wrong. Please try again.",
      );
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

      final res = await dio.post('/auth/google/mobile', data: {
        "idToken": idToken,
      });

      debugPrint("Current user response body: ${res.data}");
      return ApiResponse.fromMap(res.data);
    } on DioException catch (e, stackTrace) {
      debugPrint("Signin with google error: ${e.response?.data}");

      debugPrintStack(stackTrace: stackTrace);

      if (e.response?.data != null) {
        throw ApiError.fromMap(
          e.response!.data,
        );
      }

      throw ApiError(
        statusCode: 500,
        message: "Network error occurred",
      );
    } catch (e, stackTrace) {
      debugPrint("Signin with google error: $e");

      debugPrintStack(stackTrace: stackTrace);

      throw ApiError(
        statusCode: 500,
        message: "Something went wrong. Please try again.",
      );
    }
  }

  Future<ApiResponse?> signInWithGithub() async {
    try {
      final clientId = dotenv.env['GITHUB_CLIENT_ID'] ?? '';

      final result = await FlutterWebAuth2.authenticate(
        url: "https://github.com/login/oauth/authorize"
            "?client_id=$clientId"
            "&scope=user:email",
        callbackUrlScheme: "createrio",
      );

      final uri = Uri.parse(result);
      final code = uri.queryParameters['code'];

      if (code == null) {
        throw ApiError(statusCode: 404, message: "No code received");
      }
      final res = await dio.post('/auth/github/mobile', data: {
        "code": code,
      });

      debugPrint("Github user response body: ${res.data}");
      return ApiResponse.fromMap(res.data);
    } on DioException catch (e, stackTrace) {
      debugPrint("Signin with github error: ${e.response?.data}");

      debugPrintStack(stackTrace: stackTrace);

      if (e.response?.data != null) {
        throw ApiError.fromMap(
          e.response!.data,
        );
      }

      throw ApiError(
        statusCode: 500,
        message: "Network error occurred",
      );
    } catch (e, stackTrace) {
      debugPrint("Signin with github error: $e");

      debugPrintStack(stackTrace: stackTrace);

      throw ApiError(
        statusCode: 500,
        message: "Something went wrong. Please try again.",
      );
    }
  }
}
