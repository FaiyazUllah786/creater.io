import 'package:creatorio/features/auth/controller/user_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart' as rive;
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';

class Auth extends StatefulWidget {
  static const String routeName = '/auth';
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
    return Scaffold(
      body: Center(
        child: Container(
          margin: EdgeInsets.all(20),
          padding: EdgeInsets.symmetric(horizontal: 40,vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey,width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 20,
            children: [
              ElevatedButton(onPressed: (){}, child: Text("Google")),
              ElevatedButton(onPressed: (){}, child: Text("Github")),
              ElevatedButton(onPressed: (){}, child: Text("Email"))
            ],
          ),
        )
      ),
    );
  }
}
