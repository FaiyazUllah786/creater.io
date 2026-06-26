import 'package:cached_network_image/cached_network_image.dart';
import 'package:creatorio/common/provider/unsplash_provider.dart';
import 'package:creatorio/common/theme/colors.dart';
import 'package:creatorio/common/theme/theme_provider.dart';
import 'package:creatorio/common/utils.dart';
import 'package:creatorio/common/widgets/app_snackbar.dart';
import 'package:creatorio/common/widgets/error.dart';
import 'package:creatorio/features/image/controller/image_controller.dart';
import 'package:creatorio/features/image/widgets/edit_widget.dart';
import 'package:creatorio/features/image/widgets/transformation_drawer.dart';
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
  Future<bool?> _showExitConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Are you sure?"),
          content:
              const Text("All changes will be discarded if you don't save."),
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
    ); // Default to false if dialog is dismissed
  }

  Future<bool?> _deleteImageModal() async {
    return await showDialog<bool>(
      context: context,
      builder: (deleteModalContext) {
        return AlertDialog(
          title: const Text("Are you sure?"),
          content:
              const Text("Once the image is deleted, it cannot be restored."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(deleteModalContext)
                  .pop(false), // User chose to stay
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(deleteModalContext).pop(true),
              child: const Text(
                "Delete",
                style: TextStyle(color: redColor),
              ),
            ),
          ],
        );
      },
    );
  }

  void _share() async {
    final imageController = context.read<ImageController>();
    final file = await UnsplashProvider().downloadAndSaveImage(
        imageController.transformedImageUrl, (progress) {});
    if (file != null) {
      final params = ShareParams(
        files: [XFile(file.path)],
      );

      final result = await SharePlus.instance.share(params);

      if (result.status == ShareResultStatus.success) {}
    } else {
      final params = ShareParams(
        uri: Uri.parse(imageController.transformedImageUrl),
      );

      final result = await SharePlus.instance.share(params);

      if (result.status == ShareResultStatus.success) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageController = context.watch<ImageController>();

    return WillPopScope(
      onWillPop: () async {
        if (imageController.hasUnsavedChanges) {
          // Show the confirmation dialog if there are unsaved changes
          final exit = await _showExitConfirmationDialog();
          return exit == true; // Return true to exit, false to stay
        }
        return true; // No unsaved changes, allow exit
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Image Transformation"),
          actionsPadding: EdgeInsets.only(right: 10),
          actions: [
            IconButton(
              onPressed: () async {
                final confirmed = await _deleteImageModal();
                if (confirmed != true) return;
                final success =
                    await imageController.deleteImage(widget.image.id);
                final message = imageController.message;
                if (message != null) {
                  AppSnackbar.show(
                    context,
                    message: message.message,
                    type: message.messageType,
                  );
                }
                if (success) {
                  imageController.getAllImages();

                  if (!mounted) return;
                  Navigator.pop(context);
                }
              },
              icon: Icon(
                Icons.delete_outline,
                color: redColor,
              ),
            )
          ],
        ),
        drawer: TransformationDrawer(image: widget.image),
        bottomNavigationBar: BottomAppBar(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: _share,
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => showModalBottomSheet(
                  isScrollControlled: true,
                  context: context,
                  builder: (modalContext) {
                    return EditHelper(image: widget.image);
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.save_alt_outlined),
                onPressed: () async {
                  await imageController
                      .saveImage(imageController.transformedImageUrl);
                  final message = imageController.message;
                  if (message != null) {
                    AppSnackbar.show(
                      context,
                      message: message.message,
                      type: message.messageType,
                    );
                  }
                  imageController.getAllImages();
                },
              ),
            ],
          ),
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
                      imageUrl: imageController.transformedImageUrl,
                      fit: BoxFit.contain,
                      progressIndicatorBuilder:
                          (context, url, downloadProgress) {
                        final progress = (downloadProgress.progress ?? 0) * 100;

                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                value: downloadProgress.progress,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${progress.toStringAsFixed(0)}%',
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  if (imageController.loadingState ==
                      ImageLoadingState.deleting)
                    Center(child: CircularProgressIndicator()),
                  if (imageController.loadingState ==
                      ImageLoadingState.transforming)
                    Center(child: CircularProgressIndicator()),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
