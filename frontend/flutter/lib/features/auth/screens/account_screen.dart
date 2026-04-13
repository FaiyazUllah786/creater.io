import 'package:cached_network_image/cached_network_image.dart';
import 'package:creatorio/common/theme/colors.dart';
import 'package:creatorio/common/widgets/source_sheet.dart';
import 'package:creatorio/features/auth/controller/user_controller.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class AccountScreen extends StatefulWidget {
  static const String routeName = "/account";

  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => AccountScreenState();
}

class AccountScreenState extends State<AccountScreen> {
  void _logout() async {
    final confirm = await showAdaptiveDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Consumer<UserController>(
          builder: (context, userController, _) => Dialog(
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
                    child: Lottie.asset("assets/anim/success_celebration.json",
                        fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Are you sure you want to logout?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              foregroundColor: whiteColor,
                              backgroundColor: blackColor,
                            ),
                            onPressed: userController.isLoading
                                ? () {}
                                : () => Navigator.pop(dialogContext),
                            child: Text("Cancel")),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: whiteColor,
                            backgroundColor: redColor,
                          ),
                          onPressed: userController.isLoading
                              ? () {}
                              : () async {
                                  final success = await userController.logout();
                                  if (!mounted) return;
                                  if (success) {
                                    Navigator.pushNamedAndRemoveUntil(
                                      context,
                                      "/login",
                                      (_) => false,
                                    );
                                  }
                                },
                          child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: userController.isLoading
                                  ? const Padding(
                                      key: ValueKey('loader'),
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 8.0),
                                      child: LinearProgressIndicator(
                                        backgroundColor: whiteColor,
                                        color: redColor,
                                      ),
                                    )
                                  : Text("Log out")),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (confirm != true) return;
    final success = await context.read<UserController>().logout();

    if (!mounted) return;
    if (success) {
      Navigator.pushReplacementNamed(context, "/login");
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserController>().getCurrentUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Account"),
      ),
      body: Consumer<UserController>(
        builder: (context, userController, child) {
          final userInfo = userController.userInfo;
          if (userInfo == null) {
            return const Center(
              child: Text("User data not found!"),
            );
          }
          final photo = userInfo.profilePhoto;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        alignment: Alignment.center,
                        child: (photo == null || photo.isEmpty)
                            ? CircleAvatar(
                                backgroundColor: blackColor,
                                maxRadius: 60,
                                child: const Icon(
                                  Icons.person_outline_rounded,
                                  color: whiteColor,
                                  size: 40,
                                ),
                              )
                            : CircleAvatar(
                                maxRadius: size.width * 0.25 - 15,
                                backgroundImage:
                                    CachedNetworkImageProvider(photo),
                              ),
                      ),
                      Text(
                        "${userInfo.firstName ?? ""} ${userInfo.lastName ?? ""}",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        "@${userInfo.userName}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        userInfo.email,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w100,
                        ),
                      ),
                    ],
                  ),
                  Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      height: 1,
                      color: blackColor),
                  //Functional parts
                  InkWell(
                    onTap: () {
                      showSourceSheet(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 28.0),
                      child: const Row(
                        children: [
                          Icon(Icons.account_circle_outlined),
                          SizedBox(width: 20),
                          Text(
                            "Change Avatar",
                            style: TextStyle(
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pushNamed(context, "/updateProfile",
                        arguments: () {}),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 28.0),
                      child: const Row(
                        children: [
                          Icon(Icons.edit_note_rounded),
                          SizedBox(width: 20),
                          Text(
                            "Update Profile",
                            style: TextStyle(
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (userInfo.authProvider == "local")
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 28.0),
                      child: const Row(
                        children: [
                          Icon(Icons.lock_outline_rounded),
                          SizedBox(width: 20),
                          Text(
                            "Change Password",
                            style: TextStyle(
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (userInfo.authProvider == "local")
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 28.0),
                      child: const Row(
                        children: <Widget>[
                          Icon(Icons.lock_reset_rounded),
                          SizedBox(width: 20),
                          Text(
                            "Forget Password",
                            style: TextStyle(
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  InkWell(
                    onTap: () {
                      _logout();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 28.0),
                      child: const Row(
                        children: [
                          Icon(Icons.logout_rounded),
                          SizedBox(width: 20),
                          Text(
                            "Logout Account",
                            style: TextStyle(
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 28.0),
                    child: const Row(
                      children: [
                        Icon(Icons.delete_outline_rounded),
                        SizedBox(width: 20),
                        Text(
                          "Delete Account",
                          style: TextStyle(
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
