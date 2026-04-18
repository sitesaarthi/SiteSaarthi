import 'package:flutter/material.dart';

class TutorialsPage extends StatelessWidget {
  const TutorialsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      ("How to mark attendance", Icons.pin_drop_outlined),
      ("How to upload daily photos (DPR)", Icons.photo_camera_outlined),
      ("How to approve materials", Icons.fact_check_outlined),
      ("How to view progress reports", Icons.analytics_outlined),
      ("How to use Chat & Calls", Icons.forum_outlined),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: const Text("App Tutorials",
            style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: items.map((i) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF0B3C5D).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(i.$2, color: const Color(0xFF0B3C5D)),
              ),
              title: Text(i.$1, style: const TextStyle(fontWeight: FontWeight.w900)),
              subtitle: const Text("Guided Journey coming soon",
                  style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF475569))),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Guided Journey system will be added ✅")),
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
