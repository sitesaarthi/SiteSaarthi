import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class WarehouseInventoryPage extends StatelessWidget {
  const WarehouseInventoryPage({super.key});

  // -----------------------------
  // Fake Inventory Data
  // -----------------------------
  List<Map<String, dynamic>> get inventory => [
        {
          "name": "Cement Bags",
          "unit": "bags",
          "remaining": 20,
          "used": 80,
        },
        {
          "name": "Steel Rods",
          "unit": "pieces",
          "remaining": 45,
          "used": 155,
        },
        {
          "name": "Sand",
          "unit": "tons",
          "remaining": 12,
          "used": 38,
        },
        {
          "name": "Bricks",
          "unit": "pieces",
          "remaining": 1500,
          "used": 8500,
        },
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Warehouse Inventory",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w900,
            color: const Color(0xFF0F172A),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: inventory.length,
        itemBuilder: (context, index) {
          final item = inventory[index];
          return _InventoryCard(item: item);
        },
      ),
    );
  }
}

// ------------------------------------------------------------
// Inventory Card
// ------------------------------------------------------------
class _InventoryCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const _InventoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final remaining = item["remaining"];
    final used = item["used"];
    final unit = item["unit"];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            offset: Offset(0, 8),
            color: Color(0x0A000000),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row
          Row(
            children: [
              const Icon(LucideIcons.package,
                  size: 20, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Text(
                item["name"],
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _statBox(
                  label: "REMAINING",
                  value: "$remaining $unit",
                  color: const Color(0xFF16A34A),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statBox(
                  label: "USED TILL NOW",
                  value: "$used $unit",
                  color: const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBox({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}
