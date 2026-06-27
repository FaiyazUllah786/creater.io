import 'package:creatorio/common/theme/colors.dart';
import 'package:creatorio/features/image/controller/image_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GenRemove extends StatefulWidget {
  final String imageId;
  final List<String>? prompts;
  final String? tranformationId;

  const GenRemove(
      {super.key, required this.imageId, this.prompts, this.tranformationId});

  @override
  State<GenRemove> createState() => _GenRemoveState();
}

class _GenRemoveState extends State<GenRemove> {
  final _textController = TextEditingController();
  late List<String> _itemsToRemoveList;

  @override
  void initState() {
    super.initState();
    _itemsToRemoveList = widget.prompts ?? [];
  }

  void _addItemsToRemoveList() {
    final item = _textController.text.trim();
    if (item.isNotEmpty) {
      setState(() {
        _itemsToRemoveList.add(item);
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
            'prompts': _itemsToRemoveList,
            'effectType': 'gen_remove'
          },
          widget.tranformationId as String);
    } else {
      imageController.addTransformation(
        widget.imageId,
        {'prompts': _itemsToRemoveList, 'effectType': 'gen_remove'},
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.symmetric(vertical: 20),
              child: Text('Objects to remove: '),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _itemsToRemoveList.map((item) {
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
                      _itemsToRemoveList.remove(item);
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
                    onPressed: _addItemsToRemoveList,
                    icon: Icon(Icons.add),
                  ),
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
                    onPressed: _itemsToRemoveList.isEmpty
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
    );
  }
}
