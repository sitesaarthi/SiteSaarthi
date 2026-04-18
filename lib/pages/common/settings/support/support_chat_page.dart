import 'package:flutter/material.dart';

class SupportChatPage extends StatelessWidget {
  const SupportChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: const Text("Chat Support",
            style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.support_agent_rounded, size: 48, color: Color(0xFF0B3C5D)),
              SizedBox(height: 12),
              Text(
                "Support Chat Coming Soon",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              SizedBox(height: 6),
              Text(
                "We will connect live chat support with Kafka notifications and backend service.",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF475569)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
