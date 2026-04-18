import 'package:flutter/material.dart';

class TrackTicketPage extends StatelessWidget {
  const TrackTicketPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tickets = [
      ("SS-102341", "OTP not received", "OPEN"),
      ("SS-221445", "Material entry mismatch", "IN PROGRESS"),
      ("SS-998120", "App lag in chat screen", "CLOSED"),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: const Text("Track Ticket Status",
            style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: tickets.map((t) {
          final status = t.$3;
          final badge = _badge(status);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B3C5D).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.confirmation_number_outlined, color: Color(0xFF0B3C5D)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.$1, style: const TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(t.$2,
                          style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                    ],
                  ),
                ),
                badge,
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  static Widget _badge(String status) {
    Color bg;
    Color fg;
    if (status == "OPEN") {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFB45309);
    } else if (status == "IN PROGRESS") {
      bg = const Color(0xFFDBEAFE);
      fg = const Color(0xFF1D4ED8);
    } else {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF15803D);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(status, style: TextStyle(fontWeight: FontWeight.w900, color: fg, fontSize: 11)),
    );
  }
}
