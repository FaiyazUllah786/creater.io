import 'package:creatorio/common/message.dart';
import 'package:creatorio/common/theme/colors.dart';
import 'package:flutter/material.dart';

class AppSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    MessageType type = MessageType.info,
  }) {
    Color backgroundColor;
    IconData icon;

    switch (type) {
      case MessageType.success:
        backgroundColor = greenColor;
        icon = Icons.check_circle;
        break;

      case MessageType.error:
        backgroundColor = redColor;
        icon = Icons.warning_amber_rounded;
        break;

      case MessageType.info:
        backgroundColor = blueColor;
        icon = Icons.info;
        break;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: backgroundColor,
          dismissDirection: DismissDirection.horizontal,
          shape: ContinuousRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          content: Row(
            children: [
              Icon(
                icon,
                color: whiteColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: whiteColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
