import 'package:creatorio/features/Image/controller/image_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/theme/colors.dart';

enum Direction {
  north_west,
  north,
  north_east,
  west,
  center,
  east,
  south_west,
  south,
  south_east,
}

class GenerativeFill extends StatefulWidget {
  final String imageId;
  final String? aspectRatio;
  final String? gravity;
  final String? tranformationId;
  const GenerativeFill(
      {super.key,
      required this.imageId,
      this.aspectRatio,
      this.gravity,
      this.tranformationId});

  @override
  State<GenerativeFill> createState() => _GenerativeFillState();
}

class _GenerativeFillState extends State<GenerativeFill> {
  Direction? _selectedDirection;
  String? _isSelected;
  @override
  void initState() {
    super.initState();
    var aspectRatio = widget.aspectRatio;
    if (aspectRatio == "9:16") {
      _isSelected = "Potrait";
    } else if (aspectRatio == "16:9") {
      _isSelected = "Landscape";
    } else if (aspectRatio == "1:1") {
      _isSelected = "Square";
    } else {
      _isSelected = "Landscape";
    }
    _selectedDirection = fetchGravity(widget.gravity ?? "");
  }

  Direction fetchGravity(String gravity) {
    switch (gravity) {
      case "north_west":
        return Direction.north_west;
      case "north":
        return Direction.north;
      case "north_east":
        return Direction.north_east;
      case "west":
        return Direction.west;
      case "center":
        return Direction.center;
      case "east":
        return Direction.east;
      case "south_west":
        return Direction.south_west;
      case "south":
        return Direction.south;
      case "south_east":
        return Direction.south_east;
      default:
        return Direction.center;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Aspect Ratio"),
          const SizedBox(height: 5),
          chooseAspectRatio("Potrait", Icons.crop_portrait_outlined),
          chooseAspectRatio("Landscape", Icons.crop_landscape_outlined),
          chooseAspectRatio("Square", Icons.crop_square_outlined),
          Container(
              height: 1,
              color: Colors.grey,
              margin: const EdgeInsets.symmetric(vertical: 10)),
          const Text("Focus On"),
          const SizedBox(height: 5),
          SizedBox(
            height: 150,
            width: 150,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
              ),
              itemCount: 9,
              itemBuilder: (context, index) {
                final direction = Direction.values[index];
                return Radio(
                    value: direction,
                    groupValue: _selectedDirection,
                    onChanged: (direction) {
                      setState(() {
                        _selectedDirection = direction;
                        print(direction);
                      });
                    });
              },
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
              onPressed: () async {
                var aspectRatio = "1:1";
                if (_isSelected == "Potrait") {
                  aspectRatio = "9:16";
                } else if (_isSelected == "Landscape") {
                  aspectRatio = "16:9";
                } else {
                  aspectRatio = "1:1";
                }

                if (widget.tranformationId != null) {
                  context.read<ImageController>().updateTransformation(
                      widget.imageId,
                      {
                        'id': widget.tranformationId as String,
                        'aspectRatio': aspectRatio,
                        'gravity': _selectedDirection?.name ?? "center",
                        'effectType': 'gen_fill'
                      },
                      widget.tranformationId as String);
                } else {
                  context.read<ImageController>().addTransformation(
                    widget.imageId,
                    {
                      'aspectRatio': aspectRatio,
                      'gravity': _selectedDirection?.name ?? "center",
                      'effectType': 'gen_fill'
                    },
                  );
                }

                Navigator.pop(context);
              },
              child: const Text("Apply")),
        ],
      ),
    );
  }

  Widget chooseAspectRatio(String aspectRatio, IconData icon) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        setState(() {
          _isSelected = aspectRatio;
          print(_isSelected);
        });
      },
      child: Container(
        margin: const EdgeInsets.all(5),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _isSelected == aspectRatio ? greyColor : whiteColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 10),
            Text(aspectRatio),
          ],
        ),
      ),
    );
  }
}
