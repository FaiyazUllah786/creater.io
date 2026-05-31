import 'dart:io';

import 'package:creatorio/common/theme/colors.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
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
        textAlign: TextAlign.left,
        messagePadding: EdgeInsetsGeometry.symmetric(horizontal: 60),
        message: data,
        backgroundColor: greenColor,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: whiteColor,
        ),
        iconPositionLeft: 5,
        icon: const Icon(
          Icons.check_circle_outline_rounded,
          size: 50,
          color: whiteColor,
        ),
      ),
    );
  } else if (type == SnackBarType.info) {
    showTopSnackBar(
      Overlay.of(context),
      CustomSnackBar.info(
        textAlign: TextAlign.left,
        messagePadding: EdgeInsetsGeometry.symmetric(horizontal: 60),
        message: data,
        backgroundColor: blueColor,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: whiteColor,
        ),
        iconPositionLeft: 5,
        icon: const Icon(
          Icons.info_outline_rounded,
          size: 50,
          color: whiteColor,
        ),
      ),
    );
  } else if (type == SnackBarType.error) {
    showTopSnackBar(
      Overlay.of(context),
      CustomSnackBar.info(
        textAlign: TextAlign.left,
        messagePadding: EdgeInsetsGeometry.symmetric(horizontal: 60),
        message: data,
        backgroundColor: redColor,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: whiteColor,
        ),
        iconPositionLeft: 5,
        icon: const Icon(
          Icons.close_rounded,
          size: 50,
          color: whiteColor,
        ),
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
  return imageFile;
}

DateTime parseTimeStamp(int timeStamp) {
  return DateTime.fromMillisecondsSinceEpoch(timeStamp * 1000);
}

void handleMessage(BuildContext context, dynamic controller) {
  final msg = controller.message;
  if (msg != null) {
    msg.show(context);
    controller.clearMessage(); // VERY IMPORTANT
  }
}

Future<bool> colorPickerDialog({
  required BuildContext context,
  required Color dialogPickerColor,
  required Function(Color) onColorChanged,
}) async {
  return ColorPicker(
    // Use the dialogPickerColor as start and active color.
    color: dialogPickerColor,
    // Update the dialogPickerColor using the callback.
    onColorChanged: onColorChanged,
    width: 40,
    height: 40,
    borderRadius: 20,
    spacing: 5,
    runSpacing: 5,
    wheelDiameter: 155,
    heading: Text(
      'Select color',
      style: Theme.of(context).textTheme.titleSmall,
    ),
    subheading: Text(
      'Select color shade',
      style: Theme.of(context).textTheme.titleSmall,
    ),
    wheelSubheading: Text(
      'Selected color and its shades',
      style: Theme.of(context).textTheme.titleSmall,
    ),
    pickersEnabled: const <ColorPickerType, bool>{
      ColorPickerType.both: false,
      ColorPickerType.primary: true,
      ColorPickerType.accent: true,
      ColorPickerType.bw: false,
      ColorPickerType.custom: true,
      ColorPickerType.wheel: true,
    },
  ).showPickerDialog(
    context,
    // New in version 3.0.0 custom transitions support.
    transitionBuilder: (BuildContext context, Animation<double> a1,
        Animation<double> a2, Widget widget) {
      final double curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
      return Transform(
        transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
        child: Opacity(
          opacity: a1.value,
          child: widget,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 400),
    constraints:
        const BoxConstraints(minHeight: 460, minWidth: 300, maxWidth: 320),
  );
}
