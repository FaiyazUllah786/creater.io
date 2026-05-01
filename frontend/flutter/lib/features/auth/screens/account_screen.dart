import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:creatorio/common/theme/colors.dart';
import 'package:creatorio/common/utils.dart';
import 'package:creatorio/common/widgets/source_sheet.dart';
import 'package:creatorio/features/auth/controller/user_controller.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:image_cropper/image_cropper.dart';

class AccountScreen extends StatefulWidget {
  static const String routeName = "/account";

  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => AccountScreenState();
}

class AccountScreenState extends State<AccountScreen> {
  final TextEditingController _cofirmEditingController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey();

  bool _seePassword = false;
  String _oldPassword = "";
  String _newPassword = "";
  String _confirmPassword = "";

  void _logout() async {
    await showAdaptiveDialog<bool>(
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
                                  handleMessage(context, userController);
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
  }

  void _deleteAccount() async {
    _cofirmEditingController.clear();
    await showAdaptiveDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Consumer<UserController>(
          builder: (context, userController, _) =>
              StatefulBuilder(builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 150,
                      child: Lottie.asset('assets/anim/error.json'),
                    ),
                    Text(
                      "Are you sure you want to delete your account?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "The account will no longer be available and all data will be permanently deleted.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Enter the word Confirm below to perform this action.",
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _cofirmEditingController,
                      onChanged: (value) => setState(() {}),
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 7,
                      decoration: const InputDecoration(
                          labelText: 'CONFIRM',
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(30))),
                          prefixIcon: Icon(Icons.key_rounded),
                          counterText: ''),
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
                                  : () {
                                      _cofirmEditingController.clear();
                                      Navigator.pop(dialogContext);
                                    },
                              child: Text(
                                "Cancel",
                                style: TextStyle(fontSize: 14),
                              )),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              foregroundColor: whiteColor,
                              backgroundColor: redColor,
                            ),
                            onPressed: _cofirmEditingController.text
                                        .trim()
                                        .toLowerCase() !=
                                    'confirm'
                                ? null
                                : userController.isLoading
                                    ? () {}
                                    : () async {
                                        FocusManager.instance.primaryFocus
                                            ?.unfocus();
                                        await Future.delayed(
                                            const Duration(milliseconds: 100));
                                        final success = await userController
                                            .deleteAccount();
                                        if (!mounted) return;
                                        handleMessage(context, userController);
                                        if (success) {
                                          _cofirmEditingController.clear();
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
                                  : Text(
                                      "Delete account",
                                      style: TextStyle(fontSize: 14),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    ).then((_) {
      _cofirmEditingController.clear();
    });
  }

  Future<CroppedFile?> _changeAvatar(File? imageFile) async {
    if (imageFile == null) return null;
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile!.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Crop Image',
          aspectRatioLockEnabled: true,
        ),
      ],
    );
    return croppedFile;
  }

  @override
  void dispose() {
    super.dispose();
    _cofirmEditingController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final userController = context.watch<UserController>();
    final userInfo = userController.userInfo;
    final photo = userInfo?.profilePhoto;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Account"),
        actions: [
          IconButton(
            onPressed: () async {
              await userController.getCurrentUser();
              handleMessage(context, userController);
            },
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
          )
        ],
      ),
      body: userInfo == null
          ? const Center(
              child: Text("User data not found!"),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Stack(
                          alignment: AlignmentGeometry.center,
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
                                      backgroundColor: greyColor,
                                      maxRadius: size.width * 0.25 - 15,
                                      backgroundImage:
                                          CachedNetworkImageProvider(photo),
                                    ),
                            ),
                            if (userController.isLoading)
                              Container(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                alignment: Alignment.center,
                                child: CircularProgressIndicator(
                                  backgroundColor: blackColor,
                                  color: whiteColor,
                                ),
                              ),
                          ],
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
                      onTap: () async {
                        final File? imageFile = await showSourceSheet(context);
                        final croppedImage = await _changeAvatar(imageFile);
                        if (croppedImage == null) return;
                        await userController
                            .updateProfilePhoto(croppedImage.path);
                        if (!mounted) return;
                        handleMessage(context, userController);
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
                      onTap: () => Navigator.pushNamed(
                        context,
                        "/updateProfile",
                      ),
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
                    InkWell(
                      onTap: () => Navigator.pushNamed(
                        context,
                        "/updatePassword",
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 28.0),
                        child: const Row(
                          children: [
                            Icon(Icons.lock_outline_rounded),
                            SizedBox(width: 20),
                            Text(
                              "Update Password",
                              style: TextStyle(
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
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
                    InkWell(
                      onTap: () {
                        _deleteAccount();
                      },
                      child: Container(
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
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
