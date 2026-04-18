import 'package:flutter/material.dart';

class ClientMapViewPage extends StatelessWidget {
  const ClientMapViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Map View")),
      body: const Center(
        child: Text(
          "MAP VIEW",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
