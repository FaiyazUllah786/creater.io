import 'dart:io';

import 'package:creatorio/common/theme/colors.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import '../common/provider/unsplash_provider.dart';

enum SnackBarType { success, info, error }

void showSnackBar(BuildContext context, String data, SnackBarType type) {
  if (type == SnackBarType.success) {
    showTopSnackBar(
      Overlay.of(context),
      CustomSnackBar.info(
        message: data,
        backgroundColor: greenColor,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: whiteColor,
        ),
        icon: const Icon(
          Icons.check_circle_outline_rounded,
          size: 100,
          color: whiteColor,
        ),
        iconPositionLeft: -10,
      ),
    );
  } else if (type == SnackBarType.info) {
    showTopSnackBar(
      Overlay.of(context),
      CustomSnackBar.info(
        message: data,
        backgroundColor: blueColor,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: whiteColor,
        ),
        icon: const Icon(
          Icons.info_outline_rounded,
          size: 100,
          color: whiteColor,
        ),
        iconPositionLeft: -10,
      ),
    );
  } else if (type == SnackBarType.error) {
    showTopSnackBar(
      Overlay.of(context),
      CustomSnackBar.info(
        message: data,
        backgroundColor: redColor,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: whiteColor,
        ),
        icon: const Icon(
          Icons.close_rounded,
          size: 100,
          color: whiteColor,
        ),
        iconPositionLeft: -10,
      ),
    );
  }

  // final size = MediaQuery.of(context).size;
  // ScaffoldMessenger.of(context).showSnackBar(
  //   SnackBar(
  //     margin: EdgeInsets.only(
  //       left: 16,
  //       right: 16,
  //       bottom: size.height - kToolbarHeight - kBottomNavigationBarHeight,
  //     ),
  //     padding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
  //     behavior: SnackBarBehavior.floating,
  //     backgroundColor: whiteColor,
  //     dismissDirection: DismissDirection.horizontal,
  //     shape: ContinuousRectangleBorder(
  //       borderRadius: BorderRadius.circular(40),
  //       side: const BorderSide(color: Colors.grey, width: 1),
  //     ),
  //     elevation: 5,
  //     content: Text(
  //       '$data',
  //       style: const TextStyle(
  //           fontSize: 14, color: blackColor, fontWeight: FontWeight.w600),
  //     ),
  //   ),
  // );
}

Future<File?> pickImageFromGallery() async {
  final image = await FilePicker.platform.pickFiles(type: FileType.image);
  if (image == null || image.files.single.path == null) {
    return null;
  }
  return File(image.files.single.path!);
}

Future<File?> pickImageFromCamera() async {
  final image = await ImagePicker().pickImage(source: ImageSource.camera);
  if (image == null) {
    return null;
  }
  return File(image.path);
}

Future<File?> pickImageFromExplorer() async {
  final image = await FilePicker.platform.pickFiles(
    allowMultiple: true,
    type: FileType.custom,
    allowedExtensions: ['jpg', 'png', 'jpeg', 'svg'],
  );
  if (image == null || image.files.single.path == null) {
    return null;
  }
  return File(image.files.single.path!);
}

Future<File?> pickImageFromUnsplash(unsplashImageUrl, onProgress) async {
  final String image = unsplashImageUrl.toString();
  final imageFile =
      await UnsplashProvider().downloadAndSaveImage(image, onProgress);
  if (imageFile == null) {
    return null;
  }
  print(imageFile);
  return imageFile;
}

DateTime parseTimeStamp(int timeStamp) {
  return DateTime.fromMillisecondsSinceEpoch(timeStamp * 1000);
}
