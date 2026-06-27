import 'package:creatorio/common/utils.dart';
import 'package:creatorio/core/utils/validators.dart';
import 'package:creatorio/features/auth/controller/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/theme/colors.dart';

class UpdateProfileScreen extends StatefulWidget {
  static const String routeName = "/updateProfile";

  const UpdateProfileScreen({super.key});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey();

  String _email = "";
  String _userName = "";
  String _firstName = "";
  String _lastName = "";

  void _updateUserProfile() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final userController = context.read<ProfileController>();
      final success = await userController.updateUserProfile(
          _email, _userName, _firstName, _lastName);
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
          "Update Profile",
        ),
      ),
      body:
          Consumer<ProfileController>(builder: (context, userProvider, child) {
        if (userProvider.userInfo == null) {
          return const Center(
            child: Text("User data not found!"),
          );
        }
        final userInfo = userProvider.userInfo;
        return AbsorbPointer(
          absorbing: userProvider.isLoading,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.disabled,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(30))),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: AppValidators.validateEmail,
                      onSaved: (email) {
                        _email = email!;
                      },
                      initialValue: userInfo?.email ?? "",
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(30))),
                        prefixIcon: Icon(Icons.account_circle_outlined),
                      ),
                      validator: AppValidators.validateUsername,
                      onSaved: (userName) {
                        _userName = userName!;
                      },
                      initialValue: userInfo?.userName ?? "",
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(30))),
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      onSaved: (firstName) {
                        _firstName = firstName!;
                      },
                      initialValue: userInfo?.firstName ?? "",
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'LastName',
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(30))),
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      onSaved: (lastName) {
                        _lastName = lastName!;
                      },
                      initialValue: userInfo?.lastName ?? "",
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
                                ? _updateUserProfile
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
