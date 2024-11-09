import 'package:cached_network_image/cached_network_image.dart';
import 'package:creatorio/common/provider/unsplash_provider.dart';
import 'package:creatorio/common/widgets/error.dart';
import 'package:creatorio/common/widgets/shimmer_loading.dart';
import 'package:creatorio/features/Image/controller/image_controller.dart';
import 'package:creatorio/features/Image/screens/generative_fill_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class ImageEditor extends StatefulWidget {
  final String imageUrl;
  const ImageEditor({super.key, required this.imageUrl});

  @override
  State<ImageEditor> createState() => _ImageEditorState();
}

class _ImageEditorState extends State<ImageEditor> {
  late String _imageToTransform;
  @override
  void initState() {
    super.initState();
    Provider.of<ImageController>(context, listen: false)
        .imageTransformed
        .clear();
    _imageToTransform = widget.imageUrl;
    print("ImageToTransform: $_imageToTransform");
  }

  bool _hasUnsavedChanges = false;
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
                  onPressed: () =>
                      Navigator.of(context).pop(true), // User chose to exit
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
    return WillPopScope(
      onWillPop: () async {
        if (_hasUnsavedChanges) {
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
        drawer: Drawer(
          child: Consumer<ImageController>(
            builder: (context, imageController, child) {
              return ListView.builder(
                itemCount: imageController.imageTransformed.length,
                itemBuilder: (context, index) {
                  final transform = imageController.imageTransformed[index]
                      .contains("b_gen_fill");
                  return ListTile(
                    title: Text("$transform"),
                  );
                },
              );
            },
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          onTap: (index) async {
            switch (index) {
              case 0:
                print("case 0 Share $index");
                // Share.share(_imageToTransform);
                final file = await UnsplashProvider()
                    .downloadAndSaveImage(_imageToTransform, (progress) {
                  print(progress);
                });
                if (file != null) {
                  Share.shareXFiles([XFile(file.path)]);
                } else {
                  Share.share(_imageToTransform);
                }
                break;
              case 1:
                print("case 1 Edit $index");
                showModalBottomSheet(
                  isScrollControlled: true,
                  context: context,
                  builder: (context) {
                    return GenerativeFillScreen(
                      imageUrl: _imageToTransform,
                    );
                  },
                );

                break;
              case 2:
                print("case 2 Save $index");
                setState(() {
                  //to safely exit if something changes
                  _hasUnsavedChanges = true;
                });
                break;
              case 3:
                print("case 3 Delete $index");
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
            _imageToTransform = imageController.imageTransformed.isNotEmpty
                ? imageController.imageTransformed.last
                : widget.imageUrl;
            print("Image Transformed Url: $_imageToTransform ");
            return SafeArea(
              child: Stack(
                children: [
                  Center(
                    child: CachedNetworkImage(
                      errorWidget: (context, url, error) {
                        imageController.imageTransformed.removeLast();
                        return const ErrorScreen(
                            error: "Something not right,Try again");
                      },
                      placeholder: (context, url) => const ShimmerLoading(),
                      imageUrl: _imageToTransform,
                      fit: BoxFit.contain,
                    ),
                  ),
                  if (imageController.isTransforming)
                    const Center(
                      child: ShimmerLoading(),
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
