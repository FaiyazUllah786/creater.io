import 'package:flutter/material.dart';
import 'dart:async';
import 'package:creatorio/common/message.dart';
import 'package:creatorio/common/storage.dart';
import 'package:creatorio/core/exceptions/api_error.dart';
import 'package:creatorio/core/network/token_manager.dart';
import 'package:creatorio/features/auth/repository/i_user_repository.dart';
import 'package:creatorio/features/auth/repository/user_repository.dart';

class AuthController extends ChangeNotifier {
  final IUserRepository _userRepository;

  AuthController({IUserRepository? userRepository}) 
      : _userRepository = userRepository ?? UserRepository();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _googleLoading = false;
  bool get isGoogleLoading => _googleLoading;

  bool _githubLoading = false;
  bool get isGithubLoading => _githubLoading;

  Message? _message;
  Message? get message => _message;

  void clearMessage() {
    _message = null;
  }

  Future<bool> registerUser(String userName, String email, String password, String profilePhoto) async {
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

      final res = await _userRepository.registerUser(userName, email, password, profilePhoto);
      if (res == null) {
        _message = Message("Registration failed. Please try again.", MessageType.error);
        return false;
      }
      return true;
    } on ApiError catch (e) {
      _message = Message(e.message, MessageType.error);
      return false;
    } catch (e) {
      _message = Message("Unexpected error during registration", MessageType.error);
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
      final res = await _userRepository.loginUser(email, password);
      if (res == null) {
        _message = Message("Login failed. Please try again.", MessageType.error);
        return false;
      }
      final accessToken = res.data['accessToken'];
      final refreshToken = res.data['refreshToken'];
      if (accessToken == null || refreshToken == null) {
        _message = Message("Invalid server response", MessageType.error);
        return false;
      }

      await TokenManager.setAccessToken(accessToken);
      await SecureStorageService.saveAccessToken(accessToken);
      await SecureStorageService.saveRefreshToken(refreshToken);

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

      final data = await _userRepository.logout();
      if (data == null) {
        _message = Message("Logout request failed. Please try again.", MessageType.error);
        return false;
      }
      TokenManager.clear();
      await SecureStorageService.clear();
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

  Future<bool> signInWithGoogle() async {
    try {
      _googleLoading = true;
      _message = null;
      notifyListeners();
      
      final res = await _userRepository.signInWithGoogle();
      if (res == null) {
        _message = Message("Google sign-in failed.", MessageType.error);
        return false;
      }
      final accessToken = res.data['accessToken'];
      final refreshToken = res.data['refreshToken'];

      if (accessToken == null || refreshToken == null) {
        _message = Message("Invalid server response", MessageType.error);
        return false;
      }

      await TokenManager.setAccessToken(accessToken);
      await SecureStorageService.saveAccessToken(accessToken);
      await SecureStorageService.saveRefreshToken(refreshToken);
      return true;
    } on ApiError catch (e) {
      _message = Message(e.message, MessageType.error);
      return false;
    } catch (e) {
      _message = Message("Something went wrong. Please try again.", MessageType.error);
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

      final res = await _userRepository.signInWithGithub();
      if (res == null) {
        _message = Message("Github sign-in failed.", MessageType.error);
        return false;
      }
      final accessToken = res.data['accessToken'];
      final refreshToken = res.data['refreshToken'];

      if (accessToken == null || refreshToken == null) {
        _message = Message("Invalid server response", MessageType.error);
        return false;
      }

      await TokenManager.setAccessToken(accessToken);
      await SecureStorageService.saveAccessToken(accessToken);
      await SecureStorageService.saveRefreshToken(refreshToken);
      return true;
    } on ApiError catch (e) {
      _message = Message(e.message, MessageType.error);
      return false;
    } catch (e) {
      _message = Message("Something went wrong. Please try again.", MessageType.error);
      return false;
    } finally {
      _githubLoading = false;
      notifyListeners();
    }
  }
}
