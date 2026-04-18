import 'package:flutter/material.dart';

class Client2DViewPage extends StatelessWidget {
  const Client2DViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final projectId = args["projectId"] as String;

    final List<String> images = [
      'assets/2d/image1.jpeg',
      'assets/2d/image2.jpeg',
      'assets/2d/image3.jpeg',
      'assets/2d/image4.jpeg',
      'assets/2d/image5.jpeg',
      'assets/2d/image6.jpeg',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("2D View")),
      body: ListView.builder(
        physics: const ClampingScrollPhysics(), // ✅ no bounce
        itemCount: images.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: AspectRatio(
              aspectRatio: 1.2, // adjust based on your image type
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Image.asset(
                    images[index],
                    fit: BoxFit.contain, // ✅ no stretch
                    width: double.infinity,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
