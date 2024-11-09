import 'dart:io';

import 'package:creatorio/common/utils.dart';
import 'package:creatorio/features/Image/controller/image_controller.dart';
import 'package:creatorio/features/auth/controller/user_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';

class ImageViewer extends StatefulWidget {
  File imageFile;
  ImageViewer(this.imageFile);

  @override
  _ImageViewerState createState() => _ImageViewerState();
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
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: widget.imageFile != null
          ? Center(
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
                                fixedSize: const Size.fromHeight(50),
                                foregroundColor: whiteColor,
                                backgroundColor: brownColor,
                                shape: ContinuousRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                textStyle: const TextStyle(fontSize: 16),
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
                              style: ElevatedButton.styleFrom(
                                fixedSize: const Size.fromHeight(50),
                                foregroundColor: whiteColor,
                                backgroundColor: blackColor,
                                shape: ContinuousRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                textStyle: const TextStyle(fontSize: 16),
                              ),
                              onPressed: () async {
                                // await UserController().updateProfilePhoto(
                                //     context, widget.imageFile.path);
                                setState(() {
                                  _isLoading = true;
                                });
                                await Provider.of<ImageController>(context,
                                        listen: false)
                                    .uploadImage(widget.imageFile);
                                setState(() {
                                  _isLoading = false;
                                });
                                Navigator.pop(context);
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
            )
          : const Center(
              child: Text("No Image Selected!!!"),
            ),
    );
  }
}
