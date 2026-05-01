import 'package:creatorio/common/utils.dart';
import 'package:creatorio/features/auth/controller/user_controller.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
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
      final userController = context.read<UserController>();
      final success = await userController.updateUserProfile(
          _email, _userName, _firstName, _lastName);
      if (!mounted) return;
      handleMessage(context, userController);
      if (success) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Update Profile",
        ),
      ),
      body: Consumer<UserController>(builder: (context, userProvider, child) {
        if (userProvider.userInfo == null) {
          return const Center(
            child: Text("User data not found!"),
          );
        }
        final userInfo = userProvider.userInfo;
        return AbsorbPointer(
          absorbing: userProvider.isLoading,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: SizedBox(
                height:
                    size.height - kToolbarHeight - kBottomNavigationBarHeight,
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.disabled,
                  child: Stack(
                    // fit: StackFit.expand,
                    alignment: Alignment.center,
                    children: [
                      Lottie.asset("assets/anim/form.json",
                          height: size.width, fit: BoxFit.cover),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Spacer(flex: 1),
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
                            validator: (userName) {
                              if (userName == null ||
                                  userName.toString().trim().isEmpty) {
                                return 'userName is required';
                              }
                              return null;
                            },
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
                          ElevatedButton(
                            onPressed: !userProvider.isLoading
                                ? _updateUserProfile
                                : () {},
                            child: userProvider.isLoading
                                ? const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 28.0),
                                    child: LinearProgressIndicator(
                                      backgroundColor: whiteColor,
                                      color: blackColor,
                                    ),
                                  )
                                : const Text(
                                    "Save",
                                    style: TextStyle(
                                        color: whiteColor, fontSize: 18),
                                  ),
                          ),
                          // const SizedBox(height: 20),
                          const Spacer(flex: 1),
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
