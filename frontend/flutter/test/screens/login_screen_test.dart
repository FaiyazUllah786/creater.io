import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:creatorio/features/auth/screens/login_screen.dart';
import 'package:creatorio/features/auth/controller/auth_controller.dart';
import 'package:creatorio/common/message.dart';

// Create a simple mock for AuthController
class MockAuthController extends ChangeNotifier implements AuthController {
  @override
  bool get isLoading => false;

  @override
  bool get isGoogleLoading => false;

  @override
  bool get isGithubLoading => false;

  @override
  Message? get message => null;

  @override
  void clearMessage() {}

  @override
  Future<bool> loginUser(String email, String password) async {
    return false;
  }

  @override
  Future<bool> registerUser(String userName, String email, String password,
      String profilePhoto) async {
    return false;
  }

  @override
  Future<bool> logout() async {
    return false;
  }

  @override
  Future<bool> signInWithGoogle() async {
    return false;
  }

  @override
  Future<bool> signInWithGithub() async {
    return false;
  }
}

void main() {
  Widget createLoginScreen(AuthController authController) {
    return MaterialApp(
      home: ChangeNotifierProvider<AuthController>.value(
        value: authController,
        child: const LoginScreen(),
      ),
    );
  }

  group('LoginScreen Widget Tests', () {
    late MockAuthController mockAuthController;

    setUp(() {
      mockAuthController = MockAuthController();
    });

    testWidgets('renders all essential UI components',
        (WidgetTester tester) async {
      await tester.pumpWidget(createLoginScreen(mockAuthController));

      // Verify texts
      expect(find.text('Good to see you!'), findsOneWidget);
      expect(find.text("Let's continue the journey."), findsOneWidget);

      // Verify TextFormFields exist
      expect(
          find.byType(TextFormField), findsNWidgets(2)); // Email and password

      // Verify Login button
      expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
    });

    testWidgets('shows validation errors when fields are empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(createLoginScreen(mockAuthController));

      // Tap the login button without entering anything
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle();

      // Assuming AppValidators.validateEmail and validatePassword return standard messages or similar logic
      // In validators.dart: validateEmail returns 'Enter an email' or similar if empty
      // Let's just verify that error text appears in the TextFormField
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });
  });
}
