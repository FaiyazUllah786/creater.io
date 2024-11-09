import 'dart:async';
import 'package:creatorio/common/storage.dart';
import 'package:creatorio/common/utils.dart';
import 'package:creatorio/common/widgets/api_error.dart';
import 'package:creatorio/features/auth/repository/user_repository.dart';
import 'package:creatorio/model/user_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class UserController extends ChangeNotifier {
  final userRepository = UserRepository();

  UserModel? _userInfo = null;

  UserModel? get userInfo => _userInfo;

  Future<dynamic> registerUser(BuildContext context, String userName,
      String email, String password, String profilePhoto) async {
    try {
      userName = userName.trim();
      email = email.trim();
      password = password.trim();

      if (userName.isEmpty || email.isEmpty || password.isEmpty) {
        return null;
      } else if (profilePhoto.isEmpty) {
        showSnackBar(context, "Profile photo is required", SnackBarType.info);
        return null;
      }

      final data = await userRepository.registerUser(
          context, userName, email, password, profilePhoto);
      showSnackBar(
          context, 'User registered successfully', SnackBarType.success);
      return data;
    } on ApiError catch (e) {
      print("Error occured in user register repository: $e");
      showSnackBar(
          context, 'Registration failed: ${e.message}', SnackBarType.error);
      return null;
    } catch (e) {
      print("Error occured in user register controller: $e");
      return null;
    }
  }

  Future<dynamic> loginUser(
      BuildContext context, String email, String password) async {
    try {
      email = email.trim();
      password = password.trim();
      if (email.isEmpty || password.isEmpty) {
        showSnackBar(
            context, "Email and Password is required", SnackBarType.info);
        return null;
      }
      final res = await userRepository.loginUser(email, password);
      showSnackBar(context, 'Logged in successfully', SnackBarType.success);

      if (res != null && res.statusCode == 200) {
        print("accessToken: ${res.data['accessToken']}\n");
        print("refreshToken: ${res.data['refreshToken']}\n");
        await getCurrentUser();
        Navigator.pushReplacementNamed(context, '/home');
      }
      return res;
    } on ApiError catch (e) {
      print("Error occured in user login repository: $e");
      showSnackBar(context, 'Login failed: ${e.message}', SnackBarType.error);
      return null;
    } catch (e) {
      print("Error occured in user register controller: $e");
      return null;
    }
  }

  Future<dynamic> logout(BuildContext context) async {
    try {
      final data = await userRepository.logout();
      if (data != null) {
        if (kDebugMode) print("logout :${data.statusCode}");
      }
      await storage.deleteAll();
      _userInfo = null;
      notifyListeners();
      Navigator.pushReplacementNamed(context, "/login");
      return data;
    } on ApiError catch (e) {
      print("Error occured in user logout repository: $e");
      return null;
    } catch (e) {
      print("Error occured in user logout controller: $e");
      return null;
    }
  }

  Future<dynamic> getCurrentUser() async {
    try {
      final res = await userRepository.getCurrentUser();
      print("I am here");
      if (res != null && res.statusCode == 200) {
        print(res);
        print(res.data);
        _userInfo = UserModel.fromMap(res.data);
        notifyListeners();
        print("userinfo: $userInfo");
        return _userInfo;
      }
    } on ApiError catch (e) {
      print("Error occured fetching account info: $e");
      return null;
    } catch (e) {
      print("Error occured in fetch account info controller: $e");
      return null;
    }
  }

  Future<dynamic> updateProfilePhoto(
      BuildContext context, String profilePhoto) async {
    try {
      if (profilePhoto.isEmpty) {
        showSnackBar(context, "Profile photo is required", SnackBarType.info);
        return null;
      }
      final data = await userRepository.updateProfilePhoto(profilePhoto);
      showSnackBar(context, 'User profile photo update', SnackBarType.success);
      Navigator.pop(context);
      notifyListeners();
      return data;
    } on ApiError catch (e) {
      print("Error occured in user register repository: $e");
      showSnackBar(
          context, 'Registration failed: ${e.message}', SnackBarType.error);
      return null;
    } catch (e) {
      print("Error occured in user register controller: $e");
      return null;
    }
  }

  Future<dynamic> updateUserProfile(BuildContext context, String email,
      String userName, String firstName, String lastName) async {
    try {
      final res = await userRepository.updateUserProfile(
          email, userName, firstName, lastName);
      showSnackBar(context, 'User profile updated', SnackBarType.success);
      print("Update User Profile Data:${res!.data["updatedUser"]}");
      _userInfo = UserModel.fromMap(res.data["updatedUser"]);
      notifyListeners();
      return res;
    } on ApiError catch (e) {
      print("Error occured in user profile update repository: $e");
      showSnackBar(context, 'Update failed: ${e.message}', SnackBarType.error);
      return null;
    } catch (e) {
      print("Error occured in user profile update  controller: $e");
      return null;
    }
  }
}
