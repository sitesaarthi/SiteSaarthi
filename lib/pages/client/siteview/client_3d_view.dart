import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class Client3DViewPage extends StatefulWidget {
  const Client3DViewPage({super.key});

  @override
  State<Client3DViewPage> createState() => _Client3DViewPageState();
}

class _Client3DViewPageState extends State<Client3DViewPage> {
  bool autoRotate = false;
  bool isReady = false;

  @override
  void initState() {
    super.initState();

    // 🔥 Delay rendering to avoid 0 width crash
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            isReady = true;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    const modelPath = 'assets/3d/model2.glb';

    return Scaffold(
      appBar: AppBar(
        title: const Text("3D View"),
        actions: [
          IconButton(
            icon: Icon(autoRotate ? Icons.rotate_right : Icons.pause),
            onPressed: () {
              setState(() {
                autoRotate = !autoRotate;
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: isReady
            ? SizedBox.expand(
                child: ModelViewer(
                  key: const ValueKey("model-viewer"),
                  src: modelPath,
                  alt: "3D Model",

                  autoRotate: autoRotate,
                  cameraControls: true,
                  disableZoom: false,

                  // 🔥 stability configs
                  ar: false,
                  shadowIntensity: 0.5,
                  exposure: 1.0,
                  backgroundColor: Colors.white,

                  interactionPrompt: InteractionPrompt.none,
                ),
              )
            : const Center(
                child: CircularProgressIndicator(),
              ),
      ),
    );
  }
}
