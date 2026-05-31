import 'package:creatorio/common/utils.dart';
import 'package:creatorio/features/auth/controller/user_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/theme/colors.dart';

class UpdatePasswordScreen extends StatefulWidget {
  static const String routeName = "/updatePassword";

  const UpdatePasswordScreen({super.key});

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _seePassword = false;
  bool _seeNewPassword = false;
  String _oldPassword = "";
  String _newPassword = "";

  void _changeUserPassword() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final userController = context.read<UserController>();
      final success =
          await userController.changePassword(_oldPassword, _newPassword);
      debugPrint("_changeUserPassword: $success");
      if (!mounted) return;
      handleMessage(context, userController);
      if (success) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Update Password",
        ),
      ),
      body: Consumer<UserController>(builder: (context, userProvider, child) {
        if (userProvider.userInfo == null) {
          return const Center(
            child: Text("User data not found!"),
          );
        }
        return AbsorbPointer(
          absorbing: userProvider.isLoading,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.disabled,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Enter and confirm your new password.",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
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
                        _oldPassword = password!;
                      },
                      maxLength: 16,
                      obscureText: !_seePassword,
                      decoration: InputDecoration(
                        labelText: 'Old password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: InkWell(
                          splashFactory: NoSplash.splashFactory,
                          onTap: () => setState(() {
                            _seePassword = !_seePassword;
                          }),
                          child: Icon(_seePassword
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded),
                        ),
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      controller: _newPassController,
                      validator: (password) {
                        final newPass = password?.trim() ?? "";

                        if (newPass.isEmpty) {
                          return 'Password is required';
                        } else if (newPass.length < 6) {
                          return 'Password must contain 6 or more characters';
                        }
                        return null;
                      },
                      onSaved: (password) {
                        _newPassword = password!;
                      },
                      obscureText: !_seeNewPassword,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.key_rounded),
                        labelText: 'New password',
                        suffixIcon: InkWell(
                          splashFactory: NoSplash.splashFactory,
                          onTap: () => setState(() {
                            _seeNewPassword = !_seeNewPassword;
                          }),
                          child: Icon(_seeNewPassword
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded),
                        ),
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      controller: _confirmPassController,
                      validator: (password) {
                        final confirm = password?.trim() ?? "";
                        final newPass = _newPassController.text.trim();

                        if (confirm.isEmpty) {
                          return 'Password is required';
                        } else if (confirm.length < 6) {
                          return 'Password must contain 6 or more characters';
                        } else if (confirm != newPass) {
                          debugPrint("confirm='$confirm' | new='$newPass'");
                          return "Passwords must match";
                        }
                        return null;
                      },
                      onSaved: (password) {},
                      obscureText: true,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.key_rounded),
                        labelText: 'Confirm password',
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 18,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: !userProvider.isLoading
                                ? () => Navigator.pop(context)
                                : null,
                            child: const Text(
                              "Cancel",
                            ),
                          ),
                        ),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: !userProvider.isLoading
                                ? _changeUserPassword
                                : () {},
                            style: ElevatedButton.styleFrom(
                              foregroundColor: whiteColor,
                              backgroundColor: brownColor,
                            ),
                            child: userProvider.isLoading
                                ? const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 28.0),
                                    child: LinearProgressIndicator(
                                      backgroundColor: whiteColor,
                                      color: redColor,
                                    ),
                                  )
                                : const Text(
                                    "Update",
                                  ),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
