import 'package:creatorio/features/auth/controller/user_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart' as rive;
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';

class Auth extends StatefulWidget {
  const Auth({super.key});

  @override
  State<Auth> createState() => _AuthState();
}

class _AuthState extends State<Auth> {
  bool _isLogin = false;

  void changeAuthScreen(bool isLogin) {
    print(_isLogin);
    setState(() {
      _isLogin = isLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userController = Provider.of<UserController>(context);
    return Center(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        // child: LoginScreen()
      ),
    );
  }
}
