import 'package:creatorio/common/utils.dart';
import 'package:flutter/cupertino.dart';

enum MessageType { success, error, info }

class Message {
  final String message;
  final MessageType messageType;

  Message(this.message, this.messageType);

  void show(BuildContext context) {
    final snackBarType = switch (messageType) {
      MessageType.success => SnackBarType.success,
      MessageType.error => SnackBarType.error,
      MessageType.info => SnackBarType.info
    };
    showSnackBar(context, message, snackBarType);
  }
}
