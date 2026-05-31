import 'package:creatorio/common/theme/colors.dart';
import 'package:creatorio/common/utils.dart';
import 'package:creatorio/features/Image/controller/image_controller.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GenRecolor extends StatefulWidget {
  final String imageId;
  final List<String>? prompts;
  final String? color;
  final String? tranformationId;
  const GenRecolor(
      {super.key,
      required this.imageId,
      this.prompts,
      this.color,
      this.tranformationId});

  @override
  State<GenRecolor> createState() => _GenRecolorState();
}

class _GenRecolorState extends State<GenRecolor> {
  late Color screenPickerColor;
  final _textController = TextEditingController();
  late List<String> _itemsToRecolorList;

  @override
  void initState() {
    super.initState();
    _itemsToRecolorList = widget.prompts ?? [];
    screenPickerColor =
        widget.color != null ? hexToColor(widget.color!) : Colors.blue;
  }

  Color hexToColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');

    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }

    return Color(int.parse(
      hexColor,
      radix: 16,
    ));
  }

  void _addItemsToRecolorList() {
    final item = _textController.text.trim();
    if (item.isNotEmpty) {
      setState(() {
        _itemsToRecolorList.add(item);
        _textController.clear();
      });
    }
  }

  void _applyTransformation() {
    final imageController = context.read<ImageController>();
    if (widget.tranformationId != null) {
      imageController.updateTransformation(
          widget.imageId,
          {
            'id': widget.tranformationId as String,
            'prompts': _itemsToRecolorList,
            'color': '#${screenPickerColor.hex}',
            'effectType': 'gen_recolor'
          },
          widget.tranformationId as String);
    } else {
      imageController.addTransformation(
        widget.imageId,
        {
          'prompts': _itemsToRecolorList,
          'color': '#${screenPickerColor.hex}',
          'effectType': 'gen_recolor'
        },
      );
    }

    Navigator.pop(context);
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: EdgeInsets.symmetric(vertical: 20),
                child: Text('Objects to recolor: '),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _itemsToRecolorList.map((item) {
                  return Chip(
                    backgroundColor: greyColor,
                    label: Text(
                      item,
                      style: TextStyle(fontSize: 14),
                    ),
                    deleteIcon:
                        const Icon(color: blackColor, Icons.close, size: 18),
                    onDeleted: () {
                      setState(() {
                        _itemsToRecolorList.remove(item);
                      });
                    },
                  );
                }).toList(),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _textController,
                decoration: InputDecoration(
                  label: Text("Enter object here"),
                  suffixIcon: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: blackColor,
                        foregroundColor: whiteColor,
                        padding: EdgeInsets.all(10),
                      ),
                      onPressed: _addItemsToRecolorList,
                      icon: Icon(Icons.add),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              ListTile(
                title: const Text('Select color to replace'),
                subtitle: Text(ColorTools.nameThatColor(screenPickerColor)),
                trailing: InkWell(
                  onTap: () => colorPickerDialog(
                    context: context,
                    dialogPickerColor: screenPickerColor,
                    onColorChanged: (color) {
                      setState(() {
                        screenPickerColor = color;
                      });
                    },
                  ),
                  child: ColorIndicator(
                    width: 44,
                    height: 44,
                    borderRadius: 22,
                    color: screenPickerColor,
                  ),
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
                      onPressed: _itemsToRecolorList.isEmpty
                          ? null
                          : _applyTransformation,
                      child: Text("Apply"),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
