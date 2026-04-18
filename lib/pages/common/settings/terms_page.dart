import 'package:flutter/material.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

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
          "Terms of Use",
          style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _title(),
          const SizedBox(height: 16),

          _card(children: const [
            _H("1. Purpose of SiteSaarthi"),
            _P(
                "SiteSaarthi is designed to improve transparency, efficiency, accountability, and decision-making in construction projects through digital verification, smart reporting, communication tools, and real-time insights."),
            _B(
              items: [
                "Site engineers",
                "Project managers",
                "Construction owners",
                "Authorized staff and partners",
              ],
            ),
          ]),

          const SizedBox(height: 14),

          _card(children: const [
            _H("2. User Accounts & Authentication"),
            _P("Each user must access SiteSaarthi through a verified account."),
            _B(items: [
              "OTP-based login verification",
              "OTP can be resent after 30 seconds",
              "Device and session validation",
              "Role-based access (Engineer, Manager, Owner, Client, etc.)",
            ]),
            _P(
                "Users are responsible for maintaining the confidentiality of their login credentials."),
          ]),

          const SizedBox(height: 14),

          _card(children: const [
            _H("3. Core Platform Features"),
            _P(
                "SiteSaarthi provides the following standard services across all plans (subject to slab eligibility):"),
            _B(items: [
              "Photo-based Daily Progress Reporting (DPR)",
              "GPS-enabled attendance and site activity tracking",
              "Material issue and usage recording",
              "Project dashboards and timelines",
              "Smart notifications and alerts",
              "Multi-language interface (English, Hindi, Marathi)",
              "Dark mode and accessibility options",
              "Read-aloud feature with adjustable speed",
              "2D, 3D and AutoCAD-based visualization",
              "In-app chat, voice call and video call",
            ]),
          ]),

          const SizedBox(height: 14),

          _card(children: const [
            _H("4. AI Assistant & Guided Journey"),
            _P(
                "SiteSaarthi includes an AI-powered assistant that allows users to ask natural-language questions like:"),
            _Quote("“What is the progress of Skyline Residency?”"),
            _P("The assistant provides insights based on verified site data."),
            _P("The platform also offers a guided journey system for onboarding, including:"),
            _B(items: [
              "How to mark attendance",
              "Upload photos",
              "Approve materials",
              "View progress and reports",
            ]),
            _P(
                "This ensures smooth onboarding and easy adoption across all site staff."),
          ]),

          const SizedBox(height: 14),

          _card(children: const [
            _H("5. Smart Monitoring & Alerts"),
            _P("SiteSaarthi continuously analyzes site data to detect:"),
            _B(items: [
              "Material leakage",
              "Missing photos",
              "Abnormal usage",
              "Attendance irregularities",
              "Delays and mismatches",
            ]),
            _P("Users receive smart alerts and notifications to take timely action."),
          ]),

          const SizedBox(height: 14),

          _card(children: const [
            _H("6. Subscription Slabs & Feature Access"),
            _P("SiteSaarthi operates on a project-value based slab system."),
            _B(items: [
              "Each project is assigned a slab based on its total project cost",
              "Different slabs unlock different levels of services, support, and features",
              "Lower value projects receive essential tools",
              "Higher value projects may receive premium features like:",
            ]),
            _B(items: [
              "Dedicated site secretary",
              "Priority support",
              "Insurance coverage",
              "Executive dashboards",
            ]),
            _P("Slab thresholds and entitlements may be updated from time to time."),
          ]),

          const SizedBox(height: 14),

          _card(children: const [
            _H("7. Commission & Maintenance Fee"),
            _P("SiteSaarthi charges a commission-based maintenance fee."),
            _B(items: [
              "Software access",
              "Data storage",
              "Platform maintenance",
              "AI services",
              "Support",
            ]),
            _P("The commission rate varies by project slab."),
          ]),

          const SizedBox(height: 14),

          _card(children: const [
            _H("8. Data & Verification"),
            _P(
                "All data collected through photos, GPS, time stamps, attendance, and material entries is treated as verified operational data."),
            _P("This data may be used for:"),
            _B(items: [
              "Reporting",
              "Analytics",
              "Audits",
              "Insurance and compliance purposes",
            ]),
            _P(
                "Manipulation or false data entry may result in suspension."),
          ]),

          const SizedBox(height: 14),

          _card(children: const [
            _H("9. Language, Accessibility & Inclusivity"),
            _P("SiteSaarthi supports:"),
            _B(items: ["English", "Hindi", "Marathi"]),
            _P("The platform also provides:"),
            _B(items: [
              "Dark mode",
              "Read-aloud mode",
              "Speed-controlled voice output",
              "Simple visual UI for low-tech users",
            ]),
          ]),

          const SizedBox(height: 14),

          _card(children: const [
            _H("10. Communication Features"),
            _P("Users may communicate using:"),
            _B(items: ["In-app chat", "Voice calls", "Video calls"]),
            _P(
                "These features are intended for project coordination and support. Abuse or misuse may lead to account restrictions."),
          ]),

          const SizedBox(height: 14),

          _card(children: const [
            _H("11. Updates & Feature Changes"),
            _P(
                "SiteSaarthi may introduce, modify, or remove features as part of product improvement. Slab entitlements and commission structures may be updated with notice."),
          ]),

          const SizedBox(height: 14),

          _card(children: const [
            _H("12. Limitation of Liability"),
            _P(
                "SiteSaarthi provides digital tools for management and verification. Final responsibility for construction execution, safety, legal compliance, and financial decisions remains with project owners and contractors."),
          ]),

          const SizedBox(height: 14),

          _card(children: const [
            _H("13. Acceptance"),
            _P(
                "By using SiteSaarthi, users acknowledge that they understand and accept these terms."),
          ]),

          const SizedBox(height: 20),

          _sectionTitle("Tech Stack (Current + Planned)"),
          _card(children: const [
            _TechLine("Flutter (Dart)", "Frontend App"),
            _TechLine("SharedPreferences", "Local settings & auth state"),
            _TechLine("Node.js / Express", "Backend (planned)"),
            _TechLine("MongoDB", "Database (planned)"),
            _TechLine("Twilio", "OTP & SMS (planned)"),
            _TechLine("Socket.IO", "Chat / Realtime (planned)"),
            _TechLine("Kafka", "Notifications / Event streaming (planned)"),
            _TechLine("AI Assistant", "LLM + verified site data (planned)"),
          ]),

          const SizedBox(height: 16),
          Center(
            child: Text(
              "SiteSaarthi - Terms of Use",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  static Widget _title() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "SiteSaarthi - Terms Of Use",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 6),
          Text(
            "These Terms govern the access and use of SiteSaarthi. By accessing or using SiteSaarthi, users agree to be bound by these Terms.",
            style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF475569)),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            offset: Offset(0, 10),
            color: Color(0x0A000000),
          )
        ],
      ),
      child: Column(children: children),
    );
  }
}

// ---------------- UI small widgets ----------------

class _H extends StatelessWidget {
  final String t;
  const _H(this.t);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      child: Text(t, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
    );
  }
}

class _P extends StatelessWidget {
  final String t;
  const _P(this.t);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Text(
        t,
        style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF475569), height: 1.35),
      ),
    );
  }
}

class _B extends StatelessWidget {
  final List<String> items;
  const _B({required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Column(
        children: items
            .map(
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("• ", style: TextStyle(fontWeight: FontWeight.w900)),
                    Expanded(
                      child: Text(i, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _Quote extends StatelessWidget {
  final String t;
  const _Quote(this.t);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class _TechLine extends StatelessWidget {
  final String left;
  final String right;
  const _TechLine(this.left, this.right);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(child: Text(left, style: const TextStyle(fontWeight: FontWeight.w900))),
          Expanded(
            child: Text(
              right,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF475569)),
            ),
          ),
        ],
      ),
    );
  }
}
