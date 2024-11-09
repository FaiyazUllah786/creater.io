import 'package:creatorio/common/widgets/image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

import '/common/provider/unsplash_provider.dart';
import '/common/theme/colors.dart';
import '/common/widgets/seach_field.dart';
import 'shimmer_loading.dart';

class UnsplashScreen extends StatefulWidget {
  Function pickImageFromUnsplash;
  static const String routeName = "/unsplash";
  UnsplashScreen({super.key, required this.pickImageFromUnsplash});

  @override
  State<UnsplashScreen> createState() => UnsplashScreenState();
}

class UnsplashScreenState extends State<UnsplashScreen> {
  late ScrollController _scrollController;
  String _query = "";
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    Provider.of<UnsplashProvider>(context, listen: false).fetchPhotos("latest");
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_query.isEmpty) {
        Provider.of<UnsplashProvider>(context, listen: false)
            .fetchPhotos("latest");
        return;
      }
      Provider.of<UnsplashProvider>(context, listen: false).fetchPhotos(_query);
    }
  }

  void _searchImages(String query) async {
    setState(() {
      _query = query;
    });
    final unsplash = Provider.of<UnsplashProvider>(context, listen: false);
    if (_query.isEmpty) {
      unsplash.fetchPhotos("latest");
      return;
    }
    unsplash.photos.clear();
    await unsplash.fetchPhotos(_query);
    print("query: $_query");
    print("photos length: ${unsplash.photos.length}");
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  bool _openSearchBox = false;
  Map<String, double> _progressMap = {};
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/icons/unsplash.png",
              fit: BoxFit.contain,
              height: 20,
            ),
            const SizedBox(width: 10),
            const Text("Unsplash Images"),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18.0),
            child: InkWell(
                onTap: () {
                  setState(() {
                    _openSearchBox = !_openSearchBox;
                  });
                },
                child: Icon(_openSearchBox ? Icons.close : Icons.search)),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_openSearchBox)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: AnimatedSearchField(
                performAction: _searchImages,
              ),
            ),
          Expanded(
            child: Consumer<UnsplashProvider>(
              builder: (context, unsplashProvider, child) {
                if (unsplashProvider.isLoading) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: GridView.builder(
                      itemCount: 10, // Show 10 shimmer tiles
                      gridDelegate: SliverQuiltedGridDelegate(
                        crossAxisCount: 4,
                        mainAxisSpacing: 4,
                        crossAxisSpacing: 4,
                        repeatPattern: QuiltedGridRepeatPattern.inverted,
                        pattern: const [
                          QuiltedGridTile(4, 2),
                          QuiltedGridTile(2, 2),
                          QuiltedGridTile(2, 2),
                          QuiltedGridTile(2, 4),
                        ],
                      ),
                      itemBuilder: (context, index) {
                        return const ShimmerLoading(); // Use shimmer effect placeholder
                      },
                    ),
                  );
                } else if (!unsplashProvider.isLoading &&
                    unsplashProvider.photos.isEmpty) {
                  return const Center(
                    child: Text(
                      "No Images Found!!!",
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: GridView.custom(
                    controller: _scrollController,
                    gridDelegate: SliverQuiltedGridDelegate(
                      crossAxisCount: 4,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                      repeatPattern: QuiltedGridRepeatPattern.inverted,
                      pattern: const [
                        QuiltedGridTile(4, 2),
                        QuiltedGridTile(2, 2),
                        QuiltedGridTile(2, 2),
                        QuiltedGridTile(2, 4),
                      ],
                    ),
                    childrenDelegate: SliverChildBuilderDelegate(
                        childCount: unsplashProvider.photos.length,
                        (context, index) {
                      final image = unsplashProvider.photos[index];
                      return InkWell(
                        onTap: () async {
                          print("Unsplash Url is passed here");
                          final imageFile = await widget.pickImageFromUnsplash(
                              image.urls.regular, (progress) {
                            setState(() {
                              _progressMap[image.urls.regular.toString()] =
                                  progress;
                            });
                          });
                          print(_progressMap[image.urls.regular.toString()]);
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ImageViewer(imageFile),
                              ));
                          setState(() {
                            _progressMap.remove(image.urls.regular.toString());
                          });
                        },
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              useOldImageOnUrlChange: true,
                              imageUrl: "${image.urls.regular}",
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  const ShimmerLoading(),
                            ),
                            if (_progressMap[image.urls.regular.toString()] !=
                                    null &&
                                _progressMap[image.urls.regular.toString()]! <
                                    1)
                              Center(
                                child: CircularProgressIndicator(
                                  value: _progressMap[
                                      image.urls.regular.toString()],
                                  backgroundColor: transparentColor,
                                  color: blackColor,
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
