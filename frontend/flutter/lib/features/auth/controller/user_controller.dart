import 'dart:async';
import 'dart:convert';
import 'package:creatorio/common/message.dart';
import 'package:creatorio/common/storage.dart';
import 'package:creatorio/common/utils.dart';
import 'package:creatorio/common/widgets/api_error.dart';
import 'package:creatorio/features/auth/repository/user_repository.dart';
import 'package:creatorio/model/user_model.dart';
import 'package:flutter/material.dart';

class UserController extends ChangeNotifier {
  final userRepository = UserRepository();

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Message? _message;

  Message? get message => _message;

  UserModel? _userInfo;

  UserModel? get userInfo => _userInfo;

  void clearMessage() {
    _message = null;
  }

  Future<bool> registerUser(String userName, String email, String password,
      String profilePhoto) async {
    try {
      _message = null;
      _isLoading = true;
      notifyListeners();

      userName = userName.trim();
      email = email.trim();
      password = password.trim();

      if (userName.isEmpty || email.isEmpty || password.isEmpty) {
        _message = Message("All fields are required", MessageType.info);
        return false;
      }

      await userRepository.registerUser(
          userName, email, password, profilePhoto);
      return true;
    } on ApiError catch (e) {
      _message = Message(e.message, MessageType.error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loginUser(String email, String password) async {
    try {
      _message = null;
      _isLoading = true;
      notifyListeners();

      email = email.trim();
      password = password.trim();
      if (email.isEmpty || password.isEmpty) {
        _message = Message("Email and Password are required", MessageType.info);
        return false;
      }
      final res = await userRepository.loginUser(email, password);
      if (res == null) {
        _message =
            Message("Login failed. Please try again.", MessageType.error);
        return false;
      }
      final accessToken = res.data['accessToken'];
      final refreshToken = res.data['refreshToken'];
      if (accessToken == null || refreshToken == null) {
        _message = Message("Invalid server response", MessageType.error);
        return false;
      }
      await storeTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      _message = Message("Logged in successfully", MessageType.success);
      return true;
    } on ApiError catch (e) {
      _message = Message(e.message, MessageType.error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> logout() async {
    try {
      _message = null;
      _isLoading = true;
      notifyListeners();

      final data = await userRepository.logout();
      if (data == null) {
        _message = Message(
            "Logout request failed. Please try again.", MessageType.error);
        return false;
      }
      await storage.delete(key: 'user');
      await storage.deleteAll();
      _userInfo = null;
      notifyListeners();
      _message = Message("Logged out successfully", MessageType.success);
      return true;
    } on ApiError catch (e) {
      _message = Message(e.message, MessageType.error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getCurrentUser() async {
    try {
      _isLoading = true;
      _message = null;
      notifyListeners();
      final res = await userRepository.getCurrentUser();
      if (res == null) {
        _message = Message(
            "User data not found. Please try again.", MessageType.error);
        return;
      }
      final user = UserModel.fromMap(res.data);

      _userInfo = user;
      await saveUser(user);

      notifyListeners();
    } on ApiError catch (e) {
      _message = Message(e.message, MessageType.error);
      return;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfilePhoto(String profilePhoto) async {
    try {
      _isLoading = true;
      _message = null;
      notifyListeners();
      if (profilePhoto.isEmpty) {
        _message = Message("Avatar image is required", MessageType.info);
        return false;
      }
      final data = await userRepository.updateProfilePhoto(profilePhoto);
      if (data == null) {
        _message = Message("Change avatar request failed. Please try again.",
            MessageType.error);
        return false;
      }
      _message = Message("Avatar successfully updated", MessageType.success);
      // Navigator.pop(context);
      notifyListeners();
      return true;
    } on ApiError catch (e) {
      _message = Message(e.message, MessageType.error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateUserProfile(
      String email, String userName, String firstName, String lastName) async {
    try {
      _isLoading = true;
      _message = null;
      notifyListeners();
      final res = await userRepository.updateUserProfile(
          email, userName, firstName, lastName);
      if (res == null) {
        _message = Message("Profile update request failed. Please try again.",
            MessageType.error);
        return false;
      }
      _message =
          Message("User profile successfully updated", MessageType.success);
      final user = UserModel.fromMap(res.data["updatedUser"]);
      _userInfo = user;
      await saveUser(user);
      notifyListeners();
      return true;
    } on ApiError catch (e) {
      _message = Message(e.message, MessageType.error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<dynamic> signInWithGoogle(BuildContext context) async {
    try {
      final res = await userRepository.signInWithGoogle();
      if (res != null && res.statusCode == 200) {
        showSnackBar(context, 'Logged in successfully', SnackBarType.success);
        print("accessToken: ${res.data['accessToken']}\n");
        print("refreshToken: ${res.data['refreshToken']}\n");
        notifyListeners();
        Navigator.pushReplacementNamed(context, '/home');
      }
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

  Future<dynamic> signInWithGithub(BuildContext context) async {
    try {
      final res = await userRepository.signInWithGithub();
      print(res);
      print('---------------------------------------');
      if (res != null && res.statusCode == 200) {
        showSnackBar(context, 'Logged in successfully', SnackBarType.success);
        print("accessToken: ${res.data['accessToken']}\n");
        print("refreshToken: ${res.data['refreshToken']}\n");
        notifyListeners();
        Navigator.pushReplacementNamed(context, '/home');
      }
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

  Future<void> saveUser(UserModel user) async {
    final jsonString = jsonEncode(user.toMap());
    debugPrint("saveUser: $jsonString");
    await storage.write(key: 'user', value: jsonString);
  }

  Future<UserModel?> loadUser() async {
    final data = await storage.read(key: 'user');
    debugPrint("loadUser: $data");

    if (data == null) return null;

    return UserModel.fromMap(jsonDecode(data));
  }

  Future<void> loadUserFromStorage() async {
    final user = await loadUser();
    debugPrint("loadUserFromStorage: $user");

    if (user != null) {
      _userInfo = user;
      notifyListeners();
    }
  }
}
