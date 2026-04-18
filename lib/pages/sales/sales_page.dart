import 'package:flutter/material.dart';
import '../../layout/app_layout.dart';
import '../../../routes.dart';

class SalesPage extends StatelessWidget {
  const SalesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /// 🔥 TITLE
          const Text(
            "Sales Dashboard",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),

          const SizedBox(height: 20),

          /// 🖼️ IMAGE BANNER
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                "assets/sales.png",
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(height: 16),

          /// 🔵 SALES CARD
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("TOTAL SALES",
                    style: TextStyle(color: Colors.white70)),
                SizedBox(height: 8),
                Text(
                  "₹1.2 Cr",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  "32 Flats Sold • 12 Available",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          /// 🏢 BUILDINGS GRID (B1–B4)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.1,
            children: [
              _buildingCard(context, "B1"),
              _buildingCard(context, "B2"),
              _buildingCard(context, "B3"),
              _buildingCard(context, "B4"),
            ],
          ),
        ],
      ),
    );
  }

  /// 🏢 BUILDING CARD (GRADIENT VERSION)
  Widget _buildingCard(BuildContext context, String title) {
    final gradient = _getGradient(title);

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.salesDashboard);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.last.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ICON
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.apartment, color: Colors.white),
            ),

            const Spacer(),

            /// TITLE
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 4),

            const Text(
              "View Flats",
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  /// 🎨 GRADIENT COLORS
  List<Color> _getGradient(String title) {
    switch (title) {
      case "B1":
        return [Color(0xFF10B981), Color(0xFF047857)]; // GREEN
      case "B2":
        return [Color(0xFFF59E0B), Color(0xFFD97706)]; // ORANGE
      case "B3":
        return [Color(0xFF8B5CF6), Color(0xFF6D28D9)]; // PURPLE
      case "B4":
        return [Color(0xFFEF4444), Color(0xFFB91C1C)]; // RED
      default:
        return [Colors.grey, Colors.black];
    }
  }
}