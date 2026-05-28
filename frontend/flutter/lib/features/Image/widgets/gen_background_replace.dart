import 'package:creatorio/common/theme/colors.dart';
import 'package:creatorio/features/Image/controller/image_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GenBackgroundReplace extends StatefulWidget {
  final String imageId;
  final String? prompt;
  final String? tranformationId;

  const GenBackgroundReplace(
      {super.key, required this.imageId, this.prompt, this.tranformationId});

  @override
  State<GenBackgroundReplace> createState() => _GenBackgroundReplaceState();
}

class _GenBackgroundReplaceState extends State<GenBackgroundReplace> {
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _textController.text = widget.prompt ?? "";
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
            top: 12,
            left: 12,
            right: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                margin: EdgeInsets.symmetric(vertical: 20),
                child: Text("Prompt:")),
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                label: Text("Enter you prompt here"),
              ),
            ),
            SizedBox(height: 40),
            Row(
              spacing: 20,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Cancel"),
                  ),
                ),
                Flexible(
                  child: ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: brownColor),
                    onPressed: () {
                      final imageController = context.read<ImageController>();

                      if (widget.tranformationId != null) {
                        imageController.updateTransformation(
                            widget.imageId,
                            {
                              'id': widget.tranformationId as String,
                              'prompt': _textController.text.trim(),
                              'effectType': 'gen_background_replace'
                            },
                            widget.tranformationId as String);
                      } else {
                        imageController.addTransformation(
                          widget.imageId,
                          {
                            'prompt': _textController.text.trim(),
                            'effectType': 'gen_background_replace'
                          },
                        );
                      }

                      Navigator.pop(context);
                    },
                    child: Text("Apply"),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
