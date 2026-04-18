import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../routes.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String appVersion = "-";
  String buildNumber = "-";

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      appVersion = info.version;
      buildNumber = info.buildNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: const Text(
          "About",
          style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _headerCard(appVersion, buildNumber),

          const SizedBox(height: 18),

          _sectionTitle("Legal"),
          _card(
            children: [
              _tile(
                icon: Icons.description_outlined,
                title: "Terms & Conditions",
                subtitle: "Read SiteSaarthi Terms of Use",
                onTap: () => Navigator.pushNamed(context, AppRoutes.terms),
              ),
              const _Divider(),
              _tile(
                icon: Icons.privacy_tip_outlined,
                title: "Privacy Policy",
                subtitle: "How we handle your data (mock for now)",
                onTap: () => _toast(context, "Privacy policy page will be added ✅"),
              ),
              const _Divider(),
              _tile(
                icon: Icons.shield_outlined,
                title: "Data Usage Policy",
                subtitle: "What data we store and why",
                onTap: () => _toast(context, "Data usage policy page will be added ✅"),
              ),
            ],
          ),

          const SizedBox(height: 18),

          _sectionTitle("Company"),
          _card(
            children: [
              _tile(
                icon: Icons.business_outlined,
                title: "Company Info",
                subtitle: "SiteSaarthi Construction Tech Platform",
                onTap: () => _toast(context, "Company info will be added ✅"),
              ),
              const _Divider(),
              _tile(
                icon: Icons.workspace_premium_outlined,
                title: "Licenses",
                subtitle: "Open-source & platform licenses",
                onTap: () => _toast(context, "Licenses screen will be added ✅"),
              ),
              const _Divider(),
              _tile(
                icon: Icons.favorite_border_rounded,
                title: "Acknowledgements",
                subtitle: "Thanks to tools and contributors",
                onTap: () => _toast(context, "Acknowledgements will be added ✅"),
              ),
            ],
          ),

          const SizedBox(height: 18),

          _sectionTitle("Tech Stack"),
          _card(
            children: const [
              _TechRow(title: "Frontend", value: "Flutter (Dart)"),
              _Divider(),
              _TechRow(title: "Backend (planned)", value: "Node.js / Express"),
              _Divider(),
              _TechRow(title: "Database (planned)", value: "MongoDB"),
              _Divider(),
              _TechRow(title: "OTP + SMS (planned)", value: "Twilio"),
              _Divider(),
              _TechRow(title: "Realtime Chat (planned)", value: "Socket.IO"),
              _Divider(),
              _TechRow(title: "Notifications (planned)", value: "Kafka"),
              _Divider(),
              _TechRow(title: "AI Assistant (planned)", value: "LLM + RAG on verified site data"),
              _Divider(),
              _TechRow(title: "Visualizations (planned)", value: "2D/3D + AutoCAD integration"),
            ],
          ),

          const SizedBox(height: 20),
          Center(
            child: Text(
              "© ${DateTime.now().year} SiteSaarthi • All Rights Reserved",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  // ---------------- UI ----------------

  static Widget _headerCard(String version, String build) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 22,
            offset: Offset(0, 10),
            color: Color(0x0A000000),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFF0B3C5D).withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.construction, color: Color(0xFF0B3C5D), size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "SiteSaarthi",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                Text(
                  "Construction Field Management Platform",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  "Version $version (Build $build)",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF334155)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }

  static Widget _card({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 22,
            offset: Offset(0, 10),
            color: Color(0x0A000000),
          )
        ],
      ),
      child: Column(children: children),
    );
  }

  static Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: _iconBox(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(subtitle, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }

  static Widget _iconBox(IconData icon) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFF0B3C5D).withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: const Color(0xFF0B3C5D), size: 20),
    );
  }

  static void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _TechRow extends StatelessWidget {
  final String title;
  final String value;
  const _TechRow({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF475569)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 64, right: 10),
      child: Divider(height: 0, thickness: 1, color: Color(0xFFF1F5F9)),
    );
  }
}
