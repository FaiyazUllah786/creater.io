import 'package:flutter/material.dart';
import 'dart:async';
import 'package:creatorio/common/message.dart';
import 'package:creatorio/common/storage.dart';
import 'package:creatorio/core/exceptions/app_exceptions.dart';
import 'package:creatorio/core/network/token_manager.dart';
import 'package:creatorio/features/auth/repository/i_user_repository.dart';
import 'package:creatorio/features/auth/repository/user_repository.dart';
import 'package:creatorio/model/user_model.dart';
import 'package:creatorio/core/services/analytics_service.dart';

class ProfileController extends ChangeNotifier {
  final IUserRepository _userRepository;

  ProfileController({IUserRepository? userRepository})
      : _userRepository = userRepository ?? UserRepository();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _profilePhotoLoading = false;
  bool get profilePhotoLoading => _profilePhotoLoading;

  Message? _message;
  Message? get message => _message;

  UserModel? _userInfo;
  UserModel? get userInfo => _userInfo;

  void clearMessage() {
    _message = null;
  }

  void clearProfile() {
    _userInfo = null;
    notifyListeners();
  }

  Future<bool> deleteAccount() async {
    try {
      _message = null;
      _isLoading = true;
      notifyListeners();

      final data = await _userRepository.deleteAccount();
      if (data == null) {
        _message = Message("Delete account request failed. Please try again.",
            MessageType.error);
        return false;
      }
      TokenManager.clear();
      await SecureStorageService.clear();
      _userInfo = null;
      _message = Message("Account deleted successfully", MessageType.success);
      
      await AnalyticsService.logEvent('delete_account');
      
      return true;
    } on AppException catch (e) {
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
      final res =
          await _userRepository.changePassword(oldPassword, newPassword);
      if (res == null) {
        _message = Message("Change password request failed. Please try again.",
            MessageType.error);
        return false;
      }
      _message = Message("Password updated successfully", MessageType.success);
      
      await AnalyticsService.logEvent('change_password');
      
      return true;
    } on AppException catch (e) {
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
      final res = await _userRepository.getCurrentUser();
      if (res == null) {
        _message = Message(
            "User data not found. Please try again.", MessageType.error);
        return;
      }
      final user = UserModel.fromMap(res.data);
      _userInfo = user;
      await SecureStorageService.saveUser(user);
    } on AppException catch (e) {
      _message = Message(e.message, MessageType.error);
      return;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfilePhoto(String profilePhoto) async {
    try {
      _profilePhotoLoading = true;
      _message = null;
      notifyListeners();
      if (profilePhoto.isEmpty) {
        _message = Message("Avatar image is required", MessageType.info);
        return false;
      }
      final res = await _userRepository.updateProfilePhoto(profilePhoto);
      if (res == null) {
        _message = Message("Change avatar request failed. Please try again.",
            MessageType.error);
        return false;
      }
      final user = UserModel.fromMap(res.data);
      _userInfo = user;
      await SecureStorageService.saveUser(user);
      _message = Message("Avatar successfully updated", MessageType.success);
      
      await AnalyticsService.logEvent('update_profile_photo');
      
      return true;
    } on AppException catch (e) {
      _message = Message(e.message, MessageType.error);
      return false;
    } finally {
      _profilePhotoLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateUserProfile(
      String email, String userName, String firstName, String lastName) async {
    try {
      _isLoading = true;
      _message = null;
      notifyListeners();
      final res = await _userRepository.updateUserProfile(
          email, userName, firstName, lastName);
      if (res == null) {
        _message = Message("Profile update request failed. Please try again.",
            MessageType.error);
        return false;
      }
      _message =
          Message("User profile successfully updated", MessageType.success);
      final user = UserModel.fromMap(res.data);
      _userInfo = user;
      await SecureStorageService.saveUser(user);
      
      await AnalyticsService.logEvent('update_user_profile');
      
      return true;
    } on AppException catch (e) {
      _message = Message(e.message, MessageType.error);
      return false;
    } finally {
      _isLoading = false;
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
