import 'package:creatorio/common/theme/theme_provider.dart';
import 'package:creatorio/features/image/controller/image_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/theme/colors.dart';

enum Direction {
  northWest,
  north,
  northEast,
  west,
  center,
  east,
  southWest,
  south,
  southEast,
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
      case "northWest":
        return Direction.northWest;
      case "north":
        return Direction.north;
      case "northEast":
        return Direction.northEast;
      case "west":
        return Direction.west;
      case "center":
        return Direction.center;
      case "east":
        return Direction.east;
      case "southWest":
        return Direction.southWest;
      case "south":
        return Direction.south;
      case "southEast":
        return Direction.southEast;
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Focus On"),
              Tooltip(
                triggerMode: TooltipTriggerMode.tap,
                showDuration: Duration(seconds: 5),
                enableTapToDismiss: true,
                constraints: BoxConstraints(maxWidth: 200),
                message:
                    "The compass direction represents a location in the image, for example, northEast represents the top right corner.",
                child: Icon(
                  Icons.info_outlined,
                  size: 20,
                ),
              )
            ],
          ),
          const SizedBox(height: 10),
          Container(
            alignment: Alignment.center,
            height: 200,
            width: 200,
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 95,
                  child: Text("N"),
                ),
                Positioned(
                  bottom: 0,
                  left: 95,
                  child: Text("S"),
                ),
                Positioned(
                  bottom: 85,
                  left: 0,
                  child: Text("W"),
                ),
                Positioned(
                  bottom: 85,
                  right: 8,
                  child: Text("E"),
                ),
                Container(
                  margin: EdgeInsets.all(30),
                  decoration: BoxDecoration(
                      border: Border.all(
                        width: 1,
                        color: greyColor,
                      ),
                      borderRadius: BorderRadius.circular(30)),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                    ),
                    itemCount: 9,
                    itemBuilder: (context, index) {
                      final direction = Direction.values[index];
                      return Radio(
                        value: direction,
                        // ignore: deprecated_member_use
                        groupValue: _selectedDirection,
                        // ignore: deprecated_member_use
                        onChanged: (direction) {
                          setState(
                            () {
                              _selectedDirection = direction;
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
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
                  style: ElevatedButton.styleFrom(backgroundColor: brownColor),
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
                  child: const Text("Apply"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget chooseAspectRatio(String aspectRatio, IconData icon) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        setState(() {
          _isSelected = aspectRatio;
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 500),
        margin: const EdgeInsets.all(5),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _isSelected == aspectRatio
              ? (isDark ? whiteColor : greyColor)
              : transparentColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDark
                  ? (_isSelected == aspectRatio ? blackColor : whiteColor)
                  : blackColor,
            ),
            const SizedBox(width: 10),
            Text(
              aspectRatio,
              style: TextStyle(
                  color: (isDark
                      ? (_isSelected == aspectRatio ? blackColor : whiteColor)
                      : blackColor)),
            ),
          ],
        ),
      ),
    );
  }
}
