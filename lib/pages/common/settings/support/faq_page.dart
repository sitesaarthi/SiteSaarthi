import 'package:flutter/material.dart';

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      ("How does OTP login work?",
          "OTP is generated for verification. In future production, OTP will be sent via SMS (Twilio)."),
      ("How does attendance verification work?",
          "Attendance uses GPS + timestamp and will require photo verification in future updates."),
      ("Why do I see offline/online mode?",
          "Offline mode helps when construction sites have weak network. Data syncs when online."),
      ("How does slab-based pricing work?",
          "Projects are categorized based on project value. Slabs unlock features like secretary, support, dashboards."),
      ("Is my data verified?",
          "Yes. Photos, GPS, timestamps, attendance & material logs are treated as verified operational data."),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: const Text("FAQs",
            style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...faqs.map(
            (f) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                collapsedIconColor: const Color(0xFF64748B),
                iconColor: const Color(0xFF0B3C5D),
                title: Text(f.$1, style: const TextStyle(fontWeight: FontWeight.w900)),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Text(
                      f.$2,
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF475569), height: 1.25),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
