// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:path_provider/path_provider.dart';

// class DownloadedImagesScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Downloaded Images'),
//       ),
//       body: FutureBuilder<List<FileSystemEntity>>(
//         future: _getDownloadedImages(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Center(child: CircularProgressIndicator());
//           } else if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//             return Center(child: Text('No images found.'));
//           }

//           final images = snapshot.data!;

//           return GridView.builder(
//             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 3,
//               childAspectRatio: 1,
//             ),
//             itemCount: images.length,
//             itemBuilder: (context, index) {
//               final file = images[index] as File;
//               return Padding(
//                 padding: const EdgeInsets.all(4.0),
//                 child: Image.file(
//                   file,
//                   fit: BoxFit.cover,
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }

//   Future<List<FileSystemEntity>> _getDownloadedImages() async {
//     // Get the directory where the images are saved
//     final directory = await getExternalStorageDirectory();
//     // Replace 'your_images' with the folder where you save images
//     print('${directory!.path.substring(0, 19)}/Download/');
//     final imagesDirectory =
//         Directory('${directory!.path.substring(0, 19)}/Download/');

//     // List all files in that directory and convert to File type
//     return imagesDirectory.list().toList();
//   }
// }
