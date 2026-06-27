import 'package:creatorio/common/theme/colors.dart';
import 'package:creatorio/core/utils/validators.dart';
import 'package:creatorio/features/image/controller/image_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GenReplace extends StatefulWidget {
  final String imageId;
  final String? itemToReplace;
  final String? replaceWith;
  final String? tranformationId;

  const GenReplace(
      {super.key,
      required this.imageId,
      this.itemToReplace,
      this.replaceWith,
      this.tranformationId});

  @override
  State<GenReplace> createState() => _GenReplaceState();
}

class _GenReplaceState extends State<GenReplace> {
  final _formKey = GlobalKey<FormState>();
  final _itemToReplaceController = TextEditingController();
  final _replaceWithController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _itemToReplaceController.text = widget.itemToReplace ?? "";
    _replaceWithController.text = widget.replaceWith ?? "";
  }

  void _applyTransformation() {
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      final imageController = context.read<ImageController>();
      if (widget.tranformationId != null) {
        context.read<ImageController>().updateTransformation(
            widget.imageId,
            {
              'id': widget.tranformationId as String,
              'itemToReplace': _itemToReplaceController.text.trim(),
              'replaceWith': _replaceWithController.text.trim(),
              'effectType': 'gen_replace'
            },
            widget.tranformationId as String);
      } else {
        imageController.addTransformation(
          widget.imageId,
          {
            'itemToReplace': _itemToReplaceController.text.trim(),
            'replaceWith': _replaceWithController.text.trim(),
            'effectType': 'gen_replace'
          },
        );
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsetsGeometry.only(
            top: 12,
            left: 12,
            right: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 20),
                    child: Text("Item to replace: "),
                  ),
                  TextFormField(
                    controller: _itemToReplaceController,
                    decoration:
                        InputDecoration(label: Text('Enter item to replace')),
                    validator: (value) => AppValidators.validateRequired(value, 'Prompt is required'),
                  ),
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 20),
                    child: Text("Replace with: "),
                  ),
                  TextFormField(
                    controller: _replaceWithController,
                    decoration: InputDecoration(
                        label: Text('Enter item to replace with')),
                    validator: (value) => AppValidators.validateRequired(value, "Please enter item to replace with"),
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
                          style: ElevatedButton.styleFrom(
                              backgroundColor: brownColor),
                          onPressed: _applyTransformation,
                          child: Text("Apply"),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 40),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
