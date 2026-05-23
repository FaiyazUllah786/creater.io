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

class EditHelper extends StatefulWidget {
  final ImageModel image;
  const EditHelper({super.key, required this.image});

  @override
  State<EditHelper> createState() => _EditHelperState();
}

class _EditHelperState extends State<EditHelper> {
  final List<String> transformationTools = [
    'Generative background fill',
    'Generative background replace',
    'AI imageEnhancer',
    'Generative object replace',
    'Generative object remove',
    'Background removal',
    'Generative recolor',
    'Generative restore',
    'Generative upscale',
    'Content extraction'
  ];

  void callback(String label) {
    switch (label) {
      case 'Generative background fill':
        showModalBottomSheet(
            isScrollControlled: true,
            context: context,
            builder: (context) {
              return GenerativeFill(
                imageId: widget.image.publicId,
              );
            });
        break;
      case 'Generative background replace':
        showModalBottomSheet(
            isScrollControlled: true,
            context: context,
            builder: (context) {
              return GenBackgroundReplace(
                imageId: widget.image.publicId,
              );
            });
        break;
      case 'AI imageEnhancer':
        context.read<ImageController>().addTransformation(
            widget.image.publicId, {"effectType": "enhance"});
        break;
      case 'Generative object replace':
        showModalBottomSheet(
            isScrollControlled: true,
            context: context,
            builder: (context) {
              return GenReplace(
                imageId: widget.image.publicId,
              );
            });
        break;
      case 'Generative object remove':
        showModalBottomSheet(
            isScrollControlled: true,
            context: context,
            builder: (context) {
              return GenRemove(
                imageId: widget.image.publicId,
              );
            });
        break;
      case 'Background removal':
        context.read<ImageController>().addTransformation(
            widget.image.publicId, {"effectType": "background_removal"});
        break;
      case 'Generative recolor':
        showModalBottomSheet(
            isScrollControlled: true,
            context: context,
            builder: (context) {
              return GenRecolor(
                imageId: widget.image.publicId,
              );
            });
        break;
      case 'Generative restore':
        context.read<ImageController>().addTransformation(
            widget.image.publicId, {"effectType": "gen_restore"});
        break;
      case 'Generative upscale':
        context.read<ImageController>().addTransformation(
            widget.image.publicId, {"effectType": "upscale"});
        break;
      case 'Content extraction':
        showModalBottomSheet(
            isScrollControlled: true,
            context: context,
            builder: (context) {
              return GenExtract(
                imageId: widget.image.publicId,
              );
            });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.60,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Choose tranformation style:"),
            SizedBox(height: 10),
            Flexible(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 18, horizontal: 0),
                shrinkWrap: true,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      Navigator.pop(context);
                      callback(transformationTools[index]);
                    },
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          border: Border.all(width: 0.5),
                          borderRadius: BorderRadius.circular(18)),
                      child: Text(transformationTools[index]),
                    ),
                  ),
                ),
                itemCount: transformationTools.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
