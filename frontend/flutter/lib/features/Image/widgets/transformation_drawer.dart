import 'package:creatorio/common/theme/colors.dart';
import 'package:creatorio/common/theme/theme_provider.dart';
import 'package:creatorio/features/Image/controller/image_controller.dart';
import 'package:creatorio/features/Image/widgets/gen_background_replace.dart';
import 'package:creatorio/features/Image/widgets/gen_extract.dart';
import 'package:creatorio/features/Image/widgets/gen_fill.dart';
import 'package:creatorio/features/Image/widgets/gen_recolor.dart';
import 'package:creatorio/features/Image/widgets/gen_remove.dart';
import 'package:creatorio/features/Image/widgets/gen_replace.dart';
import 'package:creatorio/model/image_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TransformationDrawer extends StatefulWidget {
  final ImageModel image;

  const TransformationDrawer({super.key, required this.image});

  @override
  State<TransformationDrawer> createState() => _TransformationDrawerState();
}

class _TransformationDrawerState extends State<TransformationDrawer> {
  final Map<String, String> transformationTypes = {
    'gen_fill': 'Generative background fill',
    'gen_background_replace': 'Generative background replace',
    'enhance': 'AI imageEnhancer',
    'gen_replace': 'Generative object replace',
    'gen_remove': 'Generative object remove',
    'background_removal': 'Background removal',
    'gen_recolor': 'Generative recolor',
    'gen_restore': 'Generative restore',
    'upscale': 'Generative upscale',
    'extract': 'Content extraction'
  };

  void callback(String label, Map<String, dynamic> transformationEffect,
      String tranformationId) {
    switch (label) {
      case 'Generative background fill':
        final aspectRatio = transformationEffect['aspectRatio'];
        final gravity = transformationEffect['gravity'];
        showModalBottomSheet(
            isScrollControlled: true,
            context: context,
            builder: (context) {
              return GenerativeFill(
                imageId: widget.image.publicId,
                aspectRatio: aspectRatio,
                gravity: gravity,
                tranformationId: tranformationId,
              );
            });
        break;
      case 'Generative background replace':
        final String prompt = transformationEffect['prompt'];
        showModalBottomSheet(
            isScrollControlled: true,
            context: context,
            builder: (context) {
              return GenBackgroundReplace(
                imageId: widget.image.publicId,
                prompt: prompt,
                tranformationId: tranformationId,
              );
            });
        break;
      case 'Generative object replace':
        final String itemToReplace = transformationEffect['itemToReplace'];
        final String replaceWith = transformationEffect['replaceWith'];
        showModalBottomSheet(
            isScrollControlled: true,
            context: context,
            builder: (context) {
              return GenReplace(
                imageId: widget.image.publicId,
                itemToReplace: itemToReplace,
                replaceWith: replaceWith,
                tranformationId: tranformationId,
              );
            });
        break;
      case 'Generative object remove':
        final List<String> prompts = List<String>.from(
          transformationEffect['prompts'] ?? [],
        );
        showModalBottomSheet(
            isScrollControlled: true,
            context: context,
            builder: (context) {
              return GenRemove(
                imageId: widget.image.publicId,
                prompts: prompts,
                tranformationId: tranformationId,
              );
            });
        break;
      case 'Generative recolor':
        final List<String> prompts = List<String>.from(
          transformationEffect['prompts'] ?? [],
        );
        final String color = transformationEffect['color'];
        showModalBottomSheet(
            isScrollControlled: true,
            context: context,
            builder: (context) {
              return GenRecolor(
                imageId: widget.image.publicId,
                prompts: prompts,
                color: color,
                tranformationId: tranformationId,
              );
            });
        break;
      case 'Content extraction':
        final List<String> prompts = List<String>.from(
          transformationEffect['prompts'] ?? [],
        );
        showModalBottomSheet(
            isScrollControlled: true,
            context: context,
            builder: (context) {
              return GenExtract(
                imageId: widget.image.publicId,
                prompts: prompts,
                tranformationId: tranformationId,
              );
            });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final textTheme = Theme.of(context).textTheme;
    final isDark = themeProvider.isDarkMode;
    return Drawer(
      child: Consumer<ImageController>(
        builder: (context, imageController, child) {
          final transformations = imageController.transfomationList ?? [];

          if (transformations.isEmpty) {
            return const Center(
              child: Text("No transformations applied yet!"),
            );
          }
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Transformations:",
                    style: textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: transformations.length,
                      itemBuilder: (context, index) {
                        final item = transformations[index];

                        final id = item['id'];

                        final transformation = item['transformation'];

                        final effectType = transformation['effectType'];
                        return Container(
                          margin: EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 10,
                            ),
                            tileColor: isDark ? oledBlack : glassBlack,
                            shape: ContinuousRectangleBorder(
                              borderRadius: BorderRadiusGeometry.circular(20),
                            ),
                            title: Text(
                              transformationTypes[effectType] ?? 'Unknown',
                              softWrap: true,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (effectType != "enhance" &&
                                    effectType != "gen_restore" &&
                                    effectType != "upscale" &&
                                    effectType != "background_removal")
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      final label =
                                          transformationTypes[effectType] ?? '';
                                      Navigator.pop(context);
                                      callback(label, transformation, id);
                                    },
                                    icon: Icon(
                                      Icons.edit,
                                    ),
                                  ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    imageController.deleteTransformation(
                                        widget.image.publicId, id);
                                  },
                                  icon: Icon(
                                    Icons.delete,
                                    color: redColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
