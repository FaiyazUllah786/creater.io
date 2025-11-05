import 'package:creatorio/common/theme/colors.dart';
import 'package:creatorio/common/utils.dart';
import 'package:creatorio/common/widgets/image_viewer.dart';
import 'package:flutter/material.dart';

showSourceSheet(BuildContext context) async => await showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Source",
              style: TextStyle(
                fontWeight: FontWeight.w100,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 15),
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
              ),
              children: [
                _buildSourceOption(
                    "assets/icons/camera.png", "Camera", pickImageFromCamera),
                _buildSourceOption("assets/icons/gallery.png", "Gallery",
                    () async {
                  final imageFile = await pickImageFromGallery();
                  if (imageFile == null) return;
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ImageViewer(imageFile),
                      ));
                }),
                _buildSourceOption("assets/icons/file-explorer.png", "Files",
                    () async {
                  final imageFile = await pickImageFromExplorer();
                  if (imageFile == null) return;
                  // Navigator.push(
                  //     context,
                  //     MaterialPageRoute(
                  //       builder: (context) => ImageViewer(imageFile),
                  //     ));
                }),
                _buildSourceOption("assets/icons/unsplash.png", "Unsplash",
                    () async {
                  Navigator.pushNamed(
                    context,
                    '/unsplash',
                    arguments: pickImageFromUnsplash,
                  );
                }),
                // Additional options can go here
              ],
            ),
          ],
        ),
      ),
    );

// Helper Widget for each source option
Widget _buildSourceOption(
    String iconPath, String label, VoidCallback function) {
  return InkWell(
    onTap: () {
      function();
    },
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          iconPath,
          height: 50,
          color: blackColor.withOpacity(0.8),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    ),
  );
}
