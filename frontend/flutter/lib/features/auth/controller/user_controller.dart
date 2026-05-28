import 'package:flutter/material.dart';
import 'dart:async';
import 'package:creatorio/common/message.dart';
import 'package:creatorio/common/storage.dart';
import 'package:creatorio/common/widgets/api_error.dart';
import 'package:creatorio/core/network/token_manager.dart';
import 'package:creatorio/features/auth/repository/user_repository.dart';
import 'package:creatorio/model/user_model.dart';

class UserController extends ChangeNotifier {
  final userRepository = UserRepository();

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  bool _googleLoading = false;

  bool get isGoogleLoading => _googleLoading;

  bool _githubLoading = false;

  bool get isGithubLoading => _githubLoading;

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

      final res = await userRepository.registerUser(
          userName, email, password, profilePhoto);
      if (res == null) {
        _message = Message(
            "Registration failed. Please try again.", MessageType.error);
        return false;
      }
      return true;
    } on ApiError catch (e) {
      _message = Message(e.message, MessageType.error);
      return false;
    } catch (e, stackTrace) {
      debugPrint("Unexpected error during registration: $e");
      debugPrintStack(stackTrace: stackTrace);
      _message =
          Message("Unexpected error during registration", MessageType.error);
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

      /// Save in memory
      await TokenManager.setAccessToken(
        accessToken,
      );

      /// Save in storage
      await SecureStorageService.saveAccessToken(
        accessToken,
      );

      await SecureStorageService.saveRefreshToken(
        refreshToken,
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
      TokenManager.clear();

      await SecureStorageService.clear();
      _userInfo = null;
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

  Future<bool> deleteAccount() async {
    try {
      _message = null;
      _isLoading = true;
      notifyListeners();

      final data = await userRepository.deleteAccount();
      if (data == null) {
        _message = Message("Delete account request failed. Please try again.",
            MessageType.error);
        return false;
      }
      TokenManager.clear();

      await SecureStorageService.clear();
      _userInfo = null;
      _message = Message("Account deleted successfully", MessageType.success);
      return true;
    } on ApiError catch (e) {
      _message = Message(e.message, MessageType.error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      _message = null;
      _isLoading = true;
      notifyListeners();

      oldPassword = oldPassword.trim();
      newPassword = newPassword.trim();
      if (oldPassword.isEmpty || newPassword.isEmpty) {
        _message = Message("Passwords are required", MessageType.info);
        return false;
      }
      final res = await userRepository.changePassword(oldPassword, newPassword);
      if (res == null) {
        _message = Message("Change password request failed. Please try again.",
            MessageType.error);
        return false;
      }
      _message = Message("Password updated successfully", MessageType.success);
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
      await SecureStorageService.saveUser(user);
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
      final res = await userRepository.updateProfilePhoto(profilePhoto);
      if (res == null) {
        _message = Message("Change avatar request failed. Please try again.",
            MessageType.error);
        return false;
      }

      final user = UserModel.fromMap(res.data);

      _userInfo = user;
      await SecureStorageService.saveUser(user);
      _message = Message("Avatar successfully updated", MessageType.success);
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
      await SecureStorageService.saveUser(user);
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

  Future<bool> signInWithGoogle() async {
    try {
      _googleLoading = true;
      _message = null;
      notifyListeners();
      final res = await userRepository.signInWithGoogle();
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

      /// Save in memory
      await TokenManager.setAccessToken(
        accessToken,
      );

      /// Save in storage
      await SecureStorageService.saveAccessToken(
        accessToken,
      );

      await SecureStorageService.saveRefreshToken(
        refreshToken,
      );
      _message = Message("Logged in successfully", MessageType.success);
      return true;
    } on ApiError catch (e) {
      _message = Message(e.message, MessageType.error);
      return false;
    } finally {
      _googleLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithGithub() async {
    try {
      _githubLoading = true;
      _message = null;
      notifyListeners();
      final res = await userRepository.signInWithGithub();
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

      /// Save in memory
      await TokenManager.setAccessToken(
        accessToken,
      );

      /// Save in storage
      await SecureStorageService.saveAccessToken(
        accessToken,
      );

      await SecureStorageService.saveRefreshToken(
        refreshToken,
      );
      _message = Message("Logged in successfully", MessageType.success);
      return true;
    } on ApiError catch (e) {
      _message = Message(e.message, MessageType.error);
      return false;
    } finally {
      _githubLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUserFromStorage() async {
    final user = await SecureStorageService.loadUser();
    if (user != null) {
      _userInfo = user;
      notifyListeners();
    }
  }
}
