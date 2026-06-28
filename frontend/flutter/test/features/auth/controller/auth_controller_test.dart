import 'package:flutter_test/flutter_test.dart';
import 'package:creatorio/features/auth/controller/auth_controller.dart';
import 'package:creatorio/features/auth/repository/i_user_repository.dart';
import 'package:creatorio/core/models/api_response.dart';
import 'package:creatorio/core/exceptions/app_exceptions.dart';
import 'package:creatorio/common/message.dart';
import 'package:creatorio/core/network/token_manager.dart';
import 'package:flutter/services.dart';

class MockUserRepository implements IUserRepository {
  final Future<ApiResponse?> Function(String, String, String, String)?
      mockRegisterUser;
  final Future<ApiResponse?> Function(String, String)? mockLoginUser;
  final Future<ApiResponse?> Function()? mockLogout;
  final Future<ApiResponse?> Function()? mockSignInWithGoogle;
  final Future<ApiResponse?> Function()? mockSignInWithGithub;

  MockUserRepository({
    this.mockRegisterUser,
    this.mockLoginUser,
    this.mockLogout,
    this.mockSignInWithGoogle,
    this.mockSignInWithGithub,
  });

  @override
  Future<ApiResponse?> registerUser(String userName, String email,
      String password, String profilePhoto) async {
    if (mockRegisterUser != null) {
      return mockRegisterUser!(userName, email, password, profilePhoto);
    }
    return null;
  }

  @override
  Future<ApiResponse?> loginUser(String email, String password) async {
    if (mockLoginUser != null) {
      return mockLoginUser!(email, password);
    }
    return null;
  }

  @override
  Future<ApiResponse?> logout() async {
    if (mockLogout != null) {
      return mockLogout!();
    }
    return null;
  }

  @override
  Future<ApiResponse?> signInWithGoogle() async {
    if (mockSignInWithGoogle != null) {
      return mockSignInWithGoogle!();
    }
    return null;
  }

  @override
  Future<ApiResponse?> signInWithGithub() async {
    if (mockSignInWithGithub != null) {
      return mockSignInWithGithub!();
    }
    return null;
  }

  @override
  Future<ApiResponse?> changePassword(String oldPassword, String newPassword) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse?> deleteAccount() {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse?> getCurrentUser() {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse?> updateProfilePhoto(String profilePhoto) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse?> updateUserProfile(
      String email, String userName, String firstName, String lastName) {
    throw UnimplementedError();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    const channel =
        MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return null; // Mock all storage operations
    });
  });

  group('AuthController', () {
    test('loginUser fails when email or password is empty', () async {
      final controller = AuthController(userRepository: MockUserRepository());

      final result = await controller.loginUser('', 'password');

      expect(result, isFalse);
      expect(controller.message?.message, 'Email and Password are required');
      expect(controller.message?.messageType, MessageType.info);
    });

    test('loginUser succeeds with valid credentials', () async {
      final mockRepo = MockUserRepository(
        mockLoginUser: (email, password) async => ApiResponse(
          statusCode: 200,
          success: true,
          message: 'Logged in',
          data: {
            'accessToken': 'access_token',
            'refreshToken': 'refresh_token'
          },
        ),
      );
      final controller = AuthController(userRepository: mockRepo);

      final result =
          await controller.loginUser('test@example.com', 'password123');

      expect(result, isTrue);
      expect(controller.message?.message, 'Logged in successfully');
      expect(controller.message?.messageType, MessageType.success);
      expect(TokenManager.accessToken, 'access_token');
    });

    test('loginUser catches AppException and sets error message', () async {
      final mockRepo = MockUserRepository(
        mockLoginUser: (email, password) async {
          throw AuthException('Invalid credentials');
        },
      );
      final controller = AuthController(userRepository: mockRepo);

      final result = await controller.loginUser('test@example.com', 'wrong');

      expect(result, isFalse);
      expect(controller.message?.message, 'Invalid credentials');
      expect(controller.message?.messageType, MessageType.error);
    });

    test('registerUser fails when fields are empty', () async {
      final controller = AuthController(userRepository: MockUserRepository());

      final result = await controller.registerUser('', 'email', 'pass', '');

      expect(result, isFalse);
      expect(controller.message?.message, 'All fields are required');
    });

    test('registerUser succeeds', () async {
      final mockRepo = MockUserRepository(
        mockRegisterUser: (userName, email, password, profilePhoto) async =>
            ApiResponse(
          statusCode: 201,
          success: true,
          message: 'Account created',
          data: {},
        ),
      );
      final controller = AuthController(userRepository: mockRepo);

      final result = await controller.registerUser(
          'testuser', 'test@example.com', 'password123', '');

      expect(result, isTrue);
      expect(controller.message, isNull);
    });

    test('logout clears tokens', () async {
      TokenManager.setAccessToken('test_token');
      final mockRepo = MockUserRepository(
        mockLogout: () async => ApiResponse(
          statusCode: 200,
          success: true,
          message: 'Logged out',
          data: {},
        ),
      );
      final controller = AuthController(userRepository: mockRepo);

      final result = await controller.logout();

      expect(result, isTrue);
      expect(TokenManager.accessToken, isNull);
      expect(controller.message?.message, 'Logged out successfully');
    });
  });
}
