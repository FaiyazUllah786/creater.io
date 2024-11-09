import 'package:cached_network_image/cached_network_image.dart';
import 'package:creatorio/common/theme/colors.dart';
import 'package:creatorio/common/widgets/source_sheet.dart';
import 'package:creatorio/features/auth/controller/user_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AccountScreen extends StatefulWidget {
  static const String routeName = "/account";

  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => AccountScreenState();
}

class AccountScreenState extends State<AccountScreen> {
  late UserController _userController;
  @override
  void initState() {
    super.initState();
    _userController = Provider.of<UserController>(context, listen: false);
    _userController.getCurrentUser();
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
          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 28.0, vertical: 8.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 15),
                        alignment: Alignment.center,
                        child: CircleAvatar(
                          maxRadius: size.width * 0.25 - 15,
                          backgroundImage: CachedNetworkImageProvider(
                            userInfo.profilePhoto,
                          ),
                        ),
                      ),
                      if (userInfo.firstName != null ||
                          userInfo.lastName != null)
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
                    color: blackColor.withOpacity(0.2),
                  ),
                  //Functional parts
                  InkWell(
                    onTap: () {
                      showSourceSheet(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
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
                      padding: const EdgeInsets.symmetric(vertical: 15),
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
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
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
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: const Row(
                      children: [
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
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
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
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
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
