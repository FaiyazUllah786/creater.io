import 'package:cached_network_image/cached_network_image.dart';
import 'package:creatorio/common/theme/colors.dart';
import 'package:creatorio/common/utils.dart';
import 'package:creatorio/features/Image/controller/image_controller.dart';
import 'package:creatorio/features/Image/screens/image_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

import '../../../common/widgets/shimmer_loading.dart';

class ImageGallery extends StatefulWidget {
  const ImageGallery({super.key});

  @override
  State<ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<ImageGallery> {
  void getImages() async {
    await Provider.of<ImageController>(context, listen: false).getAllImages();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ImageController>(context, listen: false).getAllImages();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Creator.io"),
        actions: [
          IconButton(onPressed: getImages, icon: const Icon(Icons.refresh))
        ],
      ),
      body: Consumer<ImageController>(
        builder: (context, imageController, child) {
          if (imageController.isLoading) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: GridView.builder(
                gridDelegate: SliverQuiltedGridDelegate(
                  crossAxisCount: 4,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  repeatPattern: QuiltedGridRepeatPattern.inverted,
                  pattern: const [
                    QuiltedGridTile(4, 2),
                    QuiltedGridTile(2, 2),
                    QuiltedGridTile(2, 2),
                  ],
                ),
                itemBuilder: (context, index) {
                  return const ShimmerLoading(); // Use shimmer effect placeholder
                },
              ),
            );
          } else if (!imageController.isLoading &&
              imageController.images.isEmpty) {
            return const Center(
              child: Text(
                "No Images Found!!!",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: GridView.custom(
              // controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              gridDelegate: SliverQuiltedGridDelegate(
                crossAxisCount: 4,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                repeatPattern: QuiltedGridRepeatPattern.inverted,
                pattern: const [
                  QuiltedGridTile(4, 2),
                  QuiltedGridTile(2, 2),
                  QuiltedGridTile(2, 2),
                ],
              ),
              childrenDelegate: SliverChildBuilderDelegate(
                childCount: imageController.images.length,
                (context, index) {
                  final image = imageController.images[index];
                  return InkWell(
                    onTap: () async {
                      //edit an image
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ImageEditor(imageUrl: image.secureUrl),
                          ));
                    },
                    onLongPress: () async {
                      //delete image
                      showSnackBar(
                          context, "Deleting image", SnackBarType.info);
                      await imageController.deleteImage(image.id);
                      showSnackBar(
                          context, "Image Deleted", SnackBarType.success);
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: image.secureUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const ShimmerLoading(),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
