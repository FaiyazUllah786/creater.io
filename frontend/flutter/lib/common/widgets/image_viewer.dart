import 'dart:io';

import 'package:creatorio/features/auth/controller/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';

class ImageViewer extends StatefulWidget {
  final File imageFile;

  const ImageViewer({required this.imageFile, super.key});

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  bool _buttonsVisible = true;

  void _hideButtons() {
    setState(() {
      _buttonsVisible = false;
    });
  }

  void _showButtons() {
    setState(() {
      _buttonsVisible = true;
    });
  }

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Listener(
            onPointerDown: (_) => _hideButtons(),
            onPointerUp: (_) => _showButtons(),
            child: Container(
              // margin: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                image: DecorationImage(
                    fit: BoxFit.contain,
                    image: FileImage(
                      widget.imageFile,
                    )),
              ),
              // child: CircleAvatar(
              //   radius: size.width * 0.5 - 20,
              //   // maxRadius: 70,
              //   backgroundImage: FileImage(
              //     widget.imageFile,
              //   ),
              // ),
            ),
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                backgroundColor: transparentColor,
                color: blackColor,
              ),
            ),
          if (_buttonsVisible && !_isLoading)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: whiteColor,
                        backgroundColor: brownColor,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text("Discard"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        // await UserController().updateProfilePhoto(
                        //     context, widget.imageFile.path);
                        setState(() {
                          _isLoading = true;
                        });
                        await Provider.of<ProfileController>(context,
                                listen: false)
                            .updateProfilePhoto(widget.imageFile.path);
                        setState(() {
                          _isLoading = false;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text("Select"),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ));
  }
}
