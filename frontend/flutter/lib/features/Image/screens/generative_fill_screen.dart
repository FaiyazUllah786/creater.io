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

class GenerativeFillScreen extends StatefulWidget {
  final String imageUrl;
  const GenerativeFillScreen({super.key, required this.imageUrl});

  @override
  State<GenerativeFillScreen> createState() => _GenerativeFillScreenState();
}

class _GenerativeFillScreenState extends State<GenerativeFillScreen> {
  Direction? _selectedDirection;
  final _selectedColor = blueColor.withOpacity(0.2);
  String _isSelected = "Potrait";
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
                  print(aspectRatio);
                } else if (_isSelected == "Landscape") {
                  aspectRatio = "16:9";
                  print(aspectRatio);
                } else {
                  aspectRatio = "1:1";
                  print(aspectRatio);
                }
                print(widget.imageUrl);
                print(_selectedDirection?.name);
                Provider.of<ImageController>(context, listen: false)
                    .generativeFill(
                        imageUrl: widget.imageUrl,
                        aspectRatio: aspectRatio,
                        gravity: _selectedDirection?.name ?? "center");
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
          color: _isSelected == aspectRatio ? _selectedColor : whiteColor,
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
