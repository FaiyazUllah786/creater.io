import 'package:cached_network_image/cached_network_image.dart';
import 'package:creatorio/features/image/controller/image_controller.dart';
import 'package:creatorio/features/image/screens/image_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

import '../../../common/widgets/shimmer_loading.dart';
import '../../../common/widgets/empty_state.dart';
import '../../../common/widgets/error_state.dart';
import '../../../common/message.dart';

class ImageGallery extends StatefulWidget {
  const ImageGallery({super.key});

  @override
  State<ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<ImageGallery> {
  final hasTransformationChange = false;
  final ScrollController _scrollController = ScrollController();

  void getImages() async {
    await context.read<ImageController>().getAllImages(refresh: true);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final imageController = context.read<ImageController>();
      if (imageController.images.isEmpty) {
        await imageController.getAllImages(refresh: true);
      }
    });
    
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        final imageController = context.read<ImageController>();
        if (!imageController.isPaginating) {
          imageController.getAllImages(refresh: false);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Creator.io"),
        actions: [
          IconButton(onPressed: getImages, icon: const Icon(Icons.refresh))
        ],
      ),
      body: Consumer<ImageController>(
        builder: (context, imageController, child) {
          if (imageController.loadingState == ImageLoadingState.uploading ||
              imageController.loadingState == ImageLoadingState.fetching) {
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
          } else if (imageController.loadingState == ImageLoadingState.idle &&
              imageController.message?.messageType == MessageType.error &&
              imageController.images.isEmpty) {
            return ErrorStateWidget(
              title: "Failed to load images",
              subtitle: imageController.message?.message ?? "An unexpected error occurred.",
              onRetry: getImages,
            );
          } else if (imageController.loadingState == ImageLoadingState.idle &&
              imageController.images.isEmpty) {
            return EmptyStateWidget(
              title: "No Images Found",
              subtitle: "Upload your first image to get started!",
              icon: Icons.photo_library_outlined,
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Column(
              children: [
                Expanded(
                  child: GridView.custom(
                    controller: _scrollController,
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
                            imageController.settransformedImageUrl(image.secureUrl);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ImageEditor(image: image),
                              ),
                            );
                          },
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CachedNetworkImage(
                                imageUrl: image.secureUrl,
                                fit: BoxFit.cover,
                                memCacheWidth: 400, // Limit memory cache size for thumbnails
                                placeholder: (context, url) => const ShimmerLoading(),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (imageController.isPaginating)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
