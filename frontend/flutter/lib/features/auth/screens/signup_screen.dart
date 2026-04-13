import 'dart:io';

import 'package:creatorio/common/utils.dart';
import 'package:creatorio/features/auth/controller/user_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

  void _signUp() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final success = await context
          .read<UserController>()
          .registerUser(_userName, _email, _password, _profilePhoto);
      if (!mounted) return;
      if (success) {
        showAdaptiveDialog(
          barrierDismissible: false,
          context: context,
          builder: (context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 200,
                      child: Lottie.asset(
                          "assets/anim/success_celebration.json",
                          fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Account created successfully!",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Congratulations! Your account has been created. Please log in with your credentials to get started.",
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: whiteColor,
                          backgroundColor: blackColor,
                        ),
                        onPressed: () =>
                            Navigator.pushReplacementNamed(context, '/login'),
                        child: Text("Login to get started")),
                  ],
                ),
              ),
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userController = context.watch<UserController>();

    final size = MediaQuery.of(context).size;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final msg = userController.message;
      if (msg != null) {
        msg.show(context);
        userController.clearMessage(); // VERY IMPORTANT
      }
    });

    return Scaffold(
      body: AbsorbPointer(
        absorbing: userController.isLoading,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
              decelerationRate: ScrollDecelerationRate.fast),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: Container(
                height: size.height,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
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

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: whiteColor,
                            backgroundColor: blackColor,
                            minimumSize: Size(size.width, 50),
                          ),
                          onPressed: userController.isLoading ? () {} : _signUp,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: userController.isLoading
                                ? const Padding(
                                    key: ValueKey('loader'),
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 28.0),
                                    child: LinearProgressIndicator(
                                      backgroundColor: whiteColor,
                                      color: blackColor,
                                    ),
                                  )
                                : const Text(
                                    'Sign Up',
                                    key: ValueKey('text'),
                                    style: TextStyle(color: whiteColor),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 10,
                          children: [
                            Expanded(
                              child: Container(
                                height: 2,
                                color: Colors.grey,
                              ),
                            ),
                            Text("or"),
                            Expanded(
                              child: Container(
                                height: 2,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 10,
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    overlayColor: Colors.black),
                                onPressed: () {
                                  userController.signInWithGoogle(context);
                                },
                                child: SvgPicture.asset(
                                  'assets/icons/google.svg',
                                  semanticsLabel: 'Google Logo',
                                  height: 30,
                                ),
                              ),
                            ),
                            Expanded(
                                child: ElevatedButton(
                              onPressed: () {
                                userController.signInWithGithub(context);
                              },
                              child: SvgPicture.asset(
                                'assets/icons/github.svg',
                                semanticsLabel: 'Github Logo',
                                height: 30,
                                colorFilter: const ColorFilter.mode(
                                    Colors.white, BlendMode.srcIn),
                              ),
                            ))
                          ],
                        ),
                        const SizedBox(height: 20),
                        Align(
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
                        ),
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
      ),
    );
  }
}
