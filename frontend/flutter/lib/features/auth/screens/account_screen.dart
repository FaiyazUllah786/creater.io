import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:creatorio/common/theme/colors.dart';
import 'package:creatorio/common/utils.dart';
import 'package:creatorio/common/widgets/source_sheet.dart';

import 'package:creatorio/features/auth/controller/profile_controller.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:creatorio/features/auth/widgets/logout_dialog.dart';
import 'package:creatorio/features/auth/widgets/delete_account_dialog.dart';
import 'package:creatorio/common/widgets/theme_selection_dialog.dart';
import 'package:image_cropper/image_cropper.dart';

class AccountScreen extends StatefulWidget {
  static const String routeName = "/account";

  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => AccountScreenState();
}

class AccountScreenState extends State<AccountScreen> {
  
  void _logout() async {
    await showAdaptiveDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const LogoutDialog(),
    );
  }
  void _deleteAccount() async {
    await showAdaptiveDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const DeleteAccountDialog(),
    );
  }

  Future<CroppedFile?> _changeAvatar(File? imageFile) async {
    if (imageFile == null) return null;
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
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

  void _changeTheme() async {
    showDialog(
      context: context,
      builder: (_) => const ThemeSelectionDialog(),
    );
  }
  @override
  void dispose() {
    super.dispose();
    
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final userController = context.watch<ProfileController>();
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
                            if (userController.profilePhotoLoading)
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
                      onTap: _changeTheme,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 28.0),
                        child: const Row(
                          children: [
                            Icon(Icons.brightness_4_outlined),
                            SizedBox(width: 20),
                            Text(
                              "Change theme",
                              style: TextStyle(
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
