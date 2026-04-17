import 'package:flutter/material.dart';
import '../routes.dart';

class AssistantFab extends StatelessWidget {
  final bool show;
  const AssistantFab({super.key, this.show = true});

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();

    return FloatingActionButton(
      heroTag: "assistantFab",
      backgroundColor: Colors.white,
      onPressed: () {
        Navigator.pushNamed(context, AppRoutes.assistantChat);
      },
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Image.asset(
          "assets/assistant.png",
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
