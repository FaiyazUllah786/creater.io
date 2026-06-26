import 'package:creatorio/core/models/api_response.dart';

abstract class IUserRepository {
  Future<ApiResponse?> registerUser(
      String userName, String email, String password, String profilePhoto);
  Future<ApiResponse?> loginUser(String email, String password);
  Future<ApiResponse?> logout();
  Future<ApiResponse?> deleteAccount();
  Future<ApiResponse?> changePassword(String oldPassword, String newPassword);
  Future<ApiResponse?> getCurrentUser();
  Future<ApiResponse?> updateProfilePhoto(String profilePhoto);
  Future<ApiResponse?> updateUserProfile(
      String email, String userName, String firstName, String lastName);
  Future<ApiResponse?> signInWithGoogle();
  Future<ApiResponse?> signInWithGithub();
}
