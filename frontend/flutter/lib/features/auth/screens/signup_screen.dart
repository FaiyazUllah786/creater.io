import 'dart:io';

import 'package:creatorio/common/utils.dart';
import 'package:creatorio/common/storage.dart';
import 'package:creatorio/features/auth/controller/user_controller.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../../../common/theme/colors.dart';

class SignupScreen extends StatefulWidget {
  static const String routeName = '/signup';
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SingUpState();
}

class _SingUpState extends State<SignupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey();

  String _userName = "";

  String _email = "";

  String _password = "";

  String _profilePhoto = '';

  bool _seePassword = false;

  void _visiblePassword() {
    setState(() {
      _seePassword = !_seePassword;
    });
  }

  bool _isLoading = false;

  late final UserController userController;

  void _signUp() async {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      print("userName: $_userName");
      print("email: $_email");
      print("password: $_password");
      print("profilePhoto: $_profilePhoto");
      setState(() {
        _isLoading = true;
      });
      final registrationResponse = await userController.registerUser(
          context, _userName, _email, _password, _profilePhoto);
      if (registrationResponse != null) {
        final loginResponse =
            await userController.loginUser(context, _email, _password);
        print("loginResponse: ${loginResponse.data}");
        if (loginResponse != null) {
          await storeTokens(
              accessToken: loginResponse.data['accessToken'],
              refreshToken: loginResponse.data['refreshToken']);
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    userController = Provider.of<UserController>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(
            decelerationRate: ScrollDecelerationRate.fast),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: Container(
              height: size.height,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.disabled,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Spacer(flex: 1),
                      const Text(
                        "Welcome!",
                        style: TextStyle(
                            fontSize: 36, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Sign up to get started.",
                        style: TextStyle(fontSize: 14),
                      ),
                      // const SizedBox(height: 40),
                      const Spacer(flex: 1),
                      InkWell(
                        onTap: () async {
                          final image = await pickImageFromGallery();
                          print(image);
                          if (image != null) {
                            _profilePhoto = image.path;
                          }
                          setState(() {});
                        },
                        child: Stack(
                          children: [
                            CircleAvatar(
                              backgroundImage: _profilePhoto.isNotEmpty
                                  ? FileImage(File(_profilePhoto))
                                  : null,
                              backgroundColor: blackColor,
                              maxRadius: 60,
                              child: _profilePhoto.isEmpty
                                  ? const Icon(
                                      Icons.person_outline_rounded,
                                      color: whiteColor,
                                      size: 40,
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      // const Spacer(flex: 1),
                      const SizedBox(height: 40),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(30))),
                          prefixIcon: Icon(Icons.account_circle_outlined),
                        ),
                        validator: (userName) {
                          if (userName == null ||
                              userName.toString().trim().isEmpty) {
                            return 'Username is required';
                          }
                          return null;
                        },
                        onSaved: (username) {
                          _userName = username!;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(30))),
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (email) {
                          if (email == null ||
                              email.toString().trim().isEmpty) {
                            return 'Email is required';
                          } else if (!RegExp(
                                  r'^[a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$')
                              .hasMatch(email)) {
                            return 'Not a valid email';
                          }
                          return null;
                        },
                        onSaved: (email) {
                          _email = email!;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(30))),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffix: InkWell(
                            onTap: _visiblePassword,
                            child: Icon(_seePassword
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded),
                          ),
                        ),
                        obscureText: !_seePassword,
                        validator: (password) {
                          if (password == null ||
                              password.toString().trim().isEmpty) {
                            return 'Password is required';
                          } else if (password.length < 6) {
                            return 'Password must contain 6 or more characters';
                          }
                          return null;
                        },
                        onSaved: (password) {
                          _password = password!;
                        },
                      ),
                      const SizedBox(height: 20),
                      _isLoading
                          ? Lottie.asset('assets/loading.json', height: 100)
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  foregroundColor: whiteColor,
                                  backgroundColor: blackColor,
                                  minimumSize: Size(size.width, 50),
                                  shape: ContinuousRectangleBorder(
                                      borderRadius: BorderRadius.circular(10))),
                              onPressed: _signUp,
                              child: const Text(
                                'Sign Up',
                                style: TextStyle(color: whiteColor),
                              ),
                            ),
                      const SizedBox(height: 20),
                      !_isLoading
                          ? Align(
                              alignment: Alignment.centerRight,
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  const Text(
                                    "Already have an account? ",
                                    style: TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => Navigator.pushReplacementNamed(
                                        context, '/login'),
                                    child: const Text(
                                      "Login",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: blackColor,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            )
                          : const SizedBox(),
                      // const SizedBox(height: 20),
                      const Spacer(flex: 2),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text("Made with "),
                          Icon(
                            Icons.favorite,
                            color: Colors.red,
                          ),
                          Text(" India"),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
