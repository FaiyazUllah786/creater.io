import 'package:creatorio/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import 'package:creatorio/core/models/api_error.dart';
import 'package:creatorio/core/models/api_response.dart';
import 'package:creatorio/core/utils/error_handler.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'i_user_repository.dart';

class UserRepository implements IUserRepository {
  final GoogleSignIn _signIn = GoogleSignIn.instance;
  final Dio dio = DioClient.dio;
  @override
  @override
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
    } catch (e, stackTrace) {
      throw ErrorHandler.handle(e, stackTrace);
    }
  }
  @override
  @override
  Future<ApiResponse?> loginUser(String email, String password) async {
    try {
      final res = await dio.post('/user/auth/login', data: {
        'email': email,
        'password': password,
      });



      return ApiResponse.fromMap(
        res.data,
      );
    } catch (e, stackTrace) {
      throw ErrorHandler.handle(e, stackTrace);
    }
  }
  @override
  @override
  Future<ApiResponse?> logout() async {
    try {
      final res = await dio.post('/user/auth/logout');
      debugPrint("Logout Response: ${res.data}");

      return ApiResponse.fromMap(
        res.data,
      );
    } catch (e, stackTrace) {
      throw ErrorHandler.handle(e, stackTrace);
    }
  }
  @override
  @override
  Future<ApiResponse?> deleteAccount() async {
    try {
      final res = await dio.post('/user/delete-user');

      debugPrint("Delete account Response: ${res.data}");

      return ApiResponse.fromMap(
        res.data,
      );
    } catch (e, stackTrace) {
      throw ErrorHandler.handle(e, stackTrace);
    }
  }
  @override
  @override
  Future<ApiResponse?> changePassword(
      String oldPassword, String newPassword) async {
    try {
      final res = await dio.post('/user/update-password', data: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      });


      return ApiResponse.fromMap(
        res.data,
      );
    } catch (e, stackTrace) {
      throw ErrorHandler.handle(e, stackTrace);
    }
  }
  @override
  @override
  Future<ApiResponse?> getCurrentUser() async {
    try {
      final res = await dio.get('/user/current-user');


      return ApiResponse.fromMap(
        res.data,
      );
    } catch (e, stackTrace) {
      throw ErrorHandler.handle(e, stackTrace);
    }
  }
  @override
  @override
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



      return ApiResponse.fromMap(
        res.data,
      );
    } catch (e, stackTrace) {
      throw ErrorHandler.handle(e, stackTrace);
    }
  }
  @override
  @override
  Future<ApiResponse?> updateUserProfile(
      String email, String userName, String firstName, String lastName) async {
    try {
      final res = await dio.post('/user/update-account', data: {
        "userName": userName,
        "email": email,
        "firstName": firstName,
        "lastName": lastName,
      });



      return ApiResponse.fromMap(
        res.data,
      );
    } catch (e, stackTrace) {
      throw ErrorHandler.handle(e, stackTrace);
    }
  }
  @override
  @override
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


      return ApiResponse.fromMap(res.data);
    } catch (e, stackTrace) {
      throw ErrorHandler.handle(e, stackTrace);
    }
  }
  @override
  @override
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


      return ApiResponse.fromMap(res.data);
    } catch (e, stackTrace) {
      throw ErrorHandler.handle(e, stackTrace);
    }
  }
}
