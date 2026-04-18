import 'package:flutter/material.dart';
import '../../../routes.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

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
          "Help & Support",
          style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _topCard(),

          const SizedBox(height: 18),

          _sectionTitle("Quick Actions"),
          _card(
            children: [
              _tile(
                context,
                icon: Icons.question_answer_outlined,
                title: "FAQs",
                subtitle: "Find answers quickly",
                onTap: () => Navigator.pushNamed(context, AppRoutes.supportFaq),
              ),
              const _Divider(),
              _tile(
                context,
                icon: Icons.support_agent_rounded,
                title: "Chat with Support",
                subtitle: "Talk to SiteSaarthi support team",
                onTap: () => Navigator.pushNamed(context, AppRoutes.supportChat),
              ),
              const _Divider(),
              _tile(
                context,
                icon: Icons.call_outlined,
                title: "Call Support",
                subtitle: "Mon–Sat • 10 AM – 7 PM (mock)",
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Support call feature will be connected soon 📞")),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 18),

          _sectionTitle("Tickets"),
          _card(
            children: [
              _tile(
                context,
                icon: Icons.add_task_outlined,
                title: "Raise a Ticket",
                subtitle: "Report an issue to our team",
                onTap: () => Navigator.pushNamed(context, AppRoutes.supportRaiseTicket),
              ),
              const _Divider(),
              _tile(
                context,
                icon: Icons.track_changes_outlined,
                title: "Track Ticket Status",
                subtitle: "View your open/closed tickets",
                onTap: () => Navigator.pushNamed(context, AppRoutes.supportTrackTicket),
              ),
            ],
          ),

          const SizedBox(height: 18),

          _sectionTitle("Learning"),
          _card(
            children: [
              _tile(
                context,
                icon: Icons.school_outlined,
                title: "App Tutorials (Guided Journey)",
                subtitle: "Learn attendance, photos, DPR, approvals",
                onTap: () => Navigator.pushNamed(context, AppRoutes.supportTutorials),
              ),
            ],
          ),

          const SizedBox(height: 18),

          _sectionTitle("Feedback"),
          _card(
            children: [
              _tile(
                context,
                icon: Icons.bug_report_outlined,
                title: "Report a Problem",
                subtitle: "App bug, crash, lag, sync issue",
                onTap: () => Navigator.pushNamed(context, AppRoutes.supportReportProblem),
              ),
              const _Divider(),
              _tile(
                context,
                icon: Icons.feedback_outlined,
                title: "Feedback & Suggestions",
                subtitle: "Request features or improvements",
                onTap: () => Navigator.pushNamed(context, AppRoutes.supportFeedback),
              ),
            ],
          ),

          const SizedBox(height: 18),
        ],
      ),
    );
  }

  static Widget _topCard() {
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
            child: const Icon(Icons.headset_mic_rounded, color: Color(0xFF0B3C5D), size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Need help?",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                SizedBox(height: 4),
                Text(
                  "We’re here to support your project — faster onboarding, fewer mistakes, smoother site operations.",
                  style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF475569), height: 1.25),
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

  static Widget _tile(
    BuildContext context, {
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
