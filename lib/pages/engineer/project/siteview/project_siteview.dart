import 'package:flutter/material.dart';

class ProjectSiteViewPage extends StatelessWidget {
  final String projectId;
  final String projectName;

  const ProjectSiteViewPage({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          projectName,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              BigNavCard(
                title: "2D",
                icon: Icons.grid_view_rounded,
                gradient: const [Color(0xFF10B981), Color(0xFF047857)],
                onTap: () {
                  print("Open 2D for $projectId");
                },
              ),
              BigNavCard(
                title: "3D",
                icon: Icons.view_in_ar_rounded,
                gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                onTap: () {
                  print("Open 3D for $projectId");
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ================= CARD =================
class BigNavCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final List<Color> gradient;

  const BigNavCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        height: 150,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradient.last.withOpacity(0.3), // ✅ fixed shadow
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Row(
          children: [
            /// ICON
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2), // ✅ fixed
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: Colors.white),
            ),

            const SizedBox(width: 16),

            /// TEXT
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Open $title View",
                  style: const TextStyle(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),

            const Spacer(),

            /// ARROW
            const Icon(Icons.arrow_forward_ios, color: Colors.white),
          ],
        ),
      ),
    );
  }
}