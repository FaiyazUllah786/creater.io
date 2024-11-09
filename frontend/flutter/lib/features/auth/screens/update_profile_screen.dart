import 'package:creatorio/features/auth/controller/user_controller.dart';
import 'package:creatorio/model/user_model.dart';
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
  GlobalKey<FormState> _formKey = GlobalKey();

  String _email = "";
  String _userName = "";
  String _firstName = "";
  String _lastName = "";

  bool _isLoading = false;

  void _updateUserProfile() async {
    setState(() {
      _isLoading = true;
    });
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      print("$_email,$_userName,$_firstName,$_lastName");
      await Provider.of<UserController>(context, listen: false)
          .updateUserProfile(context, _email, _userName, _firstName, _lastName);
    }
    setState(() {
      _isLoading = false;
    });
  }

  UserModel? _userInfo;

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserController>(context);
    _userInfo = userProvider.userInfo;
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Update Profile",
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: SizedBox(
            height: size.height - kToolbarHeight - kBottomNavigationBarHeight,
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
                        initialValue: _userInfo?.email ?? "",
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
                        initialValue: _userInfo?.userName ?? "",
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
                        initialValue: _userInfo?.firstName ?? "",
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
                        initialValue: _userInfo?.lastName ?? "",
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: whiteColor,
                          backgroundColor: blackColor,
                          minimumSize: Size(size.width, 50),
                          shape: ContinuousRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: !_isLoading ? _updateUserProfile : () {},
                        child: _isLoading
                            ? const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 28.0),
                                child: LinearProgressIndicator(
                                  backgroundColor: whiteColor,
                                  color: blackColor,
                                ),
                              )
                            : const Text(
                                "Save",
                                style:
                                    TextStyle(color: whiteColor, fontSize: 18),
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
  }
}
