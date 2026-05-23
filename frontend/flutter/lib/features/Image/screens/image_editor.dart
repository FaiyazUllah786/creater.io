import 'package:cached_network_image/cached_network_image.dart';
import 'package:creatorio/common/provider/unsplash_provider.dart';
import 'package:creatorio/common/theme/colors.dart';
import 'package:creatorio/common/utils.dart';
import 'package:creatorio/common/widgets/error.dart';
import 'package:creatorio/common/widgets/shimmer_loading.dart';
import 'package:creatorio/features/Image/controller/image_controller.dart';
import 'package:creatorio/features/Image/widgets/edit_widget.dart';
import 'package:creatorio/features/Image/widgets/transformation_drawer.dart';
import 'package:creatorio/model/image_model.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class ImageEditor extends StatefulWidget {
  final ImageModel image;
  const ImageEditor({super.key, required this.image});

  @override
  State<ImageEditor> createState() => _ImageEditorState();
}

class _ImageEditorState extends State<ImageEditor> {
  Future<bool> _showExitConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("Are you sure?"),
              content: const Text(
                  "All changes will be discarded if you don't save."),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).pop(false), // User chose to stay
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    final imageController = context.read<ImageController>();
                    imageController.clearTransformation(widget.image.publicId);
                    Navigator.of(context).pop(true);
                  },
                  child: const Text("Exit"),
                ),
              ],
            );
          },
        ) ??
        false; // Default to false if dialog is dismissed
  }

  @override
  Widget build(BuildContext context) {
    final imageController = context.watch<ImageController>();
    return WillPopScope(
      onWillPop: () async {
        if (imageController.hasUnsavedChanges) {
          // Show the confirmation dialog if there are unsaved changes
          final exit = await _showExitConfirmationDialog();
          return exit; // Return true to exit, false to stay
        }
        return true; // No unsaved changes, allow exit
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Image Transformation"),
        ),
        drawer: TransformationDrawer(image: widget.image),
        bottomNavigationBar: BottomNavigationBar(
          onTap: (index) async {
            switch (index) {
              case 0:
                final file = await UnsplashProvider().downloadAndSaveImage(
                    imageController.transformedImageUrl ??
                        widget.image.secureUrl, (progress) {
                  print(progress);
                });
                if (file != null) {
                  final params = ShareParams(
                    files: [XFile(file.path)],
                  );

                  final result = await SharePlus.instance.share(params);

                  if (result.status == ShareResultStatus.success) {
                    print('Thank you for sharing the picture!');
                  }
                } else {
                  final params = ShareParams(
                    uri: Uri.parse(widget.image.secureUrl),
                  );

                  final result = await SharePlus.instance.share(params);

                  if (result.status == ShareResultStatus.success) {
                    print('Thank you for sharing the picture!');
                  }
                }
                break;
              case 1:
                showModalBottomSheet(
                  isScrollControlled: true,
                  context: context,
                  builder: (modalContext) {
                    return EditHelper(image: widget.image);
                  },
                );

                break;
              case 2:
                await imageController.saveImage(widget.image.secureUrl);
                handleMessage(context, imageController);
                break;
              case 3:
                final success =
                    await imageController.deleteImage(widget.image.id);
                if (success) Navigator.pop(context);
                break;
            }
          },
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.share_outlined), label: "Share"),
            BottomNavigationBarItem(
                icon: Icon(Icons.edit_outlined), label: "Edit"),
            BottomNavigationBarItem(
                icon: Icon(Icons.save_alt_outlined), label: "Save"),
            BottomNavigationBarItem(
                icon: Icon(Icons.delete_outline), label: "Delete"),
          ],
        ),
        body: Consumer<ImageController>(
          builder: (context, imageController, child) {
            return SafeArea(
              child: Stack(
                children: [
                  Center(
                    child: CachedNetworkImage(
                      errorWidget: (context, url, error) {
                        return const ErrorScreen(
                            error: "Something not right, try again!");
                      },
                      placeholder: (context, url) => const ShimmerLoading(),
                      imageUrl: imageController.transformedImageUrl ??
                          widget.image.secureUrl,
                      fit: BoxFit.contain,
                    ),
                  ),
                  if (imageController.isTransforming)
                    Container(
                      height: double.maxFinite,
                      color: whiteColor.withAlpha(75),
                      child: Center(
                        child: ShaderMask(
                          shaderCallback: (bounds) {
                            return const LinearGradient(
                              colors: [
                                Color(0xFF00F5A0),
                                Color(0xFF00D9F5),
                                Color(0xFF9D4DFF),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds);
                          },
                          blendMode: BlendMode.srcATop,
                          child: Lottie.asset(
                            'assets/anim/ai_animation.json',
                            height: 90,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
