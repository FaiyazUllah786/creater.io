import 'dart:io';

import 'package:creatorio/common/navigator_key.dart';
import 'package:creatorio/common/utils.dart';
import 'package:creatorio/common/widgets/app_snackbar.dart';
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
      final userController = context.read<UserController>();
      final success = await userController.registerUser(
          _userName, _email, _password, _profilePhoto);
      if (!mounted) return;
      if (success) {
        showAdaptiveDialog(
          barrierDismissible: false,
          context: context,
          builder: (context) {
            final textTheme = Theme.of(context).textTheme;

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
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Account created successfully!",
                      style: textTheme.labelMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Congratulations! Your account has been created. Please log in with your credentials to get started.",
                      style: textTheme.bodyMedium,
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
      } else {
        final message = userController.message;
        if (message != null) {
          AppSnackbar.show(
            context,
            message: message.message,
            type: message.messageType,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userController = context.watch<UserController>();

    final textTheme = Theme.of(context).textTheme;

    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          "Creater.io",
        ),
      ),
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: userController.isLoading ||
              userController.isGoogleLoading ||
              userController.isGithubLoading,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.disabled,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48.0,
                          vertical: 20,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 10),
                            Text("Welcome!", style: textTheme.headlineLarge),
                            const SizedBox(height: 10),
                            const Text(
                              "Sign up to get started.",
                            ),
                            const SizedBox(height: 40),
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
                              onPressed:
                                  userController.isLoading ? () {} : _signUp,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: userController.isLoading
                                    ? const Padding(
                                        key: ValueKey('loader'),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 28.0),
                                        child: LinearProgressIndicator(
                                          backgroundColor: whiteColor,
                                          color: blackColor,
                                        ),
                                      )
                                    : Text(
                                        'Sign Up',
                                        key: ValueKey('text'),
                                        style: textTheme.bodyMedium!
                                            .copyWith(color: whiteColor),
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
                                    onPressed: userController.isGoogleLoading
                                        ? () {}
                                        : () async {
                                            final success = await userController
                                                .signInWithGoogle();
                                            if (!mounted) return;
                                            if (success) {
                                              navigatorKey.currentState
                                                  ?.pushReplacementNamed(
                                                      '/home');
                                            }
                                          },
                                    child: AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      child: userController.isGoogleLoading
                                          ? Padding(
                                              key: const ValueKey('loader'),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 28.0),
                                              child: Lottie.asset(
                                                  'assets/anim/google_loading.json'),
                                            )
                                          : SvgPicture.asset(
                                              'assets/icons/google.svg',
                                              semanticsLabel: 'Google Logo',
                                              height: 30,
                                            ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: userController.isGithubLoading
                                        ? () {}
                                        : () async {
                                            final success = await userController
                                                .signInWithGithub();
                                            if (!mounted) return;
                                            if (success) {
                                              navigatorKey.currentState
                                                  ?.pushReplacementNamed(
                                                      '/home');
                                            }
                                          },
                                    child: AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      child: userController.isGithubLoading
                                          ? SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                key: ValueKey("loader"),
                                                backgroundColor: whiteColor,
                                                color: blackColor,
                                              ),
                                            )
                                          : SvgPicture.asset(
                                              'assets/icons/github_color_svg.svg',
                                              semanticsLabel: 'Github Logo',
                                              height: 30,
                                            ),
                                    ),
                                  ),
                                )
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
                                  ),
                                  InkWell(
                                    onTap: () => Navigator.pushReplacementNamed(
                                        context, '/login'),
                                    child: Text(
                                      "Login",
                                      style: textTheme.bodyLarge,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (!isKeyboardOpen)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: const Row(
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
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}
