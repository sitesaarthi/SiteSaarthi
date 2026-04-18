import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/locale/locale_instance.dart';

import '../../../layout/app_layout.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String language = "en";

  final owner = const {
    "name": "Rajesh Sharma",
    "company": "Sharma Constructions",
    "phone": "+91 98765 43210",
    "role": "Owner",
  };

  // ✅ Email Controller
  final TextEditingController emailController = TextEditingController();
  bool savingEmail = false;
  bool emailSaved = false;

  // ✅ show confirmation only for few seconds
  bool showEmailSavedBanner = false;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    _loadEmail();
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString("lang") ?? "en";
    setState(() => language = savedLang);
    await prefs.setString("lang", savedLang);
  }

  Future<void> _loadEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString("email") ?? "";
    emailController.text = savedEmail;

    setState(() {
      emailSaved = savedEmail.isNotEmpty;
    });
  }

  Future<void> _saveEmail() async {
    final email = emailController.text.trim();

    if (email.isEmpty || !email.contains("@")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid email")),
      );
      return;
    }

    setState(() => savingEmail = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("email", email);

    setState(() {
      savingEmail = false;
      emailSaved = true;
      showEmailSavedBanner = true; // ✅ show saved confirmation
    });

    // ✅ Auto hide confirmation after 2 seconds
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    setState(() {
      showEmailSavedBanner = false; // ✅ now it disappears
    });
  }

  Future<void> _handleLanguageChange(String? lang) async {
    if (lang == null) return;

    setState(() => language = lang);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("lang", lang);

    localeController.setLocale(lang); // 🔥 THIS LINE
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return AppLayout(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: double.infinity,
            height: constraints.maxHeight,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 14,
                  offset: Offset(0, 6),
                  color: Color.fromRGBO(15, 23, 42, 0.08),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "PROFILE",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 18),

                ProfileRow(
                  icon: LucideIcons.user,
                  label: "Name",
                  value: owner["name"]!,
                ),
                const SizedBox(height: 12),

                ProfileRow(
                  icon: LucideIcons.building2,
                  label: "Company",
                  value: owner["company"]!,
                ),
                const SizedBox(height: 12),

                ProfileRow(
                  icon: LucideIcons.phone,
                  label: "Phone",
                  value: owner["phone"]!,
                ),
                const SizedBox(height: 12),

                ProfileRow(
                  icon: LucideIcons.badgeCheck,
                  label: "Role",
                  value: owner["role"]!,
                ),
                const SizedBox(height: 22),

                // ✅ EMAIL SECTION
                const Text(
                  "EMAIL",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.9,
                  ),
                ),
                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: emailController,
                    enabled: !emailSaved, // ✅ lock after saved
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF334155),
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "Enter your email",
                      hintStyle: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // ✅ Save button only before saving
                if (!emailSaved)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: savingEmail ? null : _saveEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      child: savingEmail
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text("SAVE EMAIL"),
                    ),
                  ),

                // ✅ Banner shows only for 2 seconds and disappears
                if (showEmailSavedBanner) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFFDF5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle,
                            size: 18, color: Color(0xFF16A34A)),
                        SizedBox(width: 8),
                        Text(
                          "Email Saved",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF166534),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 22),

                // ✅ LANGUAGE PREFERENCE
                const Text(
                  "LANGUAGE PREFERENCE",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.9,
                  ),
                ),
                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: language,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      onChanged: _handleLanguageChange,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF334155),
                      ),
                      items: const [
                        DropdownMenuItem(value: "en", child: Text("English")),
                        DropdownMenuItem(value: "hi", child: Text("हिंदी")),
                        DropdownMenuItem(value: "mr", child: Text("मराठी")),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 6),
                const Text(
                  "App language will update based on your preference",
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/* ===== Reusable Profile Row ===== */
class ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const ProfileRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
