import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../layout/app_layout.dart';
import '../../../components/logout.dart';
import '../../../routes.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String role = "OWNER";
  bool loading = true;
  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString("authUser");

    if (raw != null) {
      final decoded = jsonDecode(raw);
      role = decoded["role"] ?? "OWNER";
    }

    setState(() => loading = false);
  }

  AppRole _roleToEnum(String roleStr) {
    switch (roleStr) {
      case "OWNER":
        return AppRole.owner;
      case "ENGINEER":
        return AppRole.engineer;
      case "MANAGER":
        return AppRole.manager;
      case "CLIENT":
        return AppRole.client;
      default:
        return AppRole.owner;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return AppLayout(
      role: _roleToEnum(role),
      child: SizedBox.expand(
        // 👈 forces full available space
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Settings",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 14),

            // 👇 makes it use the remaining height properly
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 22,
                            offset: Offset(0, 10),
                            color: Color(0x0B000000),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          _SettingsTile(
                            icon: Icons.desktop_windows_outlined,
                            title: "General",
                            subtitle: "Startup and app preferences",
                            onTap: () => Navigator.pushNamed(
                                context, AppRoutes.settingsGeneral),
                          ),
                          const _Divider(),
                          _SettingsTile(
                            icon: Icons.chat_bubble_outline_rounded,
                            title: "Chats",
                            subtitle: "Theme, wallpaper, chat settings",
                            onTap: () => Navigator.pushNamed(
                                context, AppRoutes.settingsChats),
                          ),
                          const _Divider(),
                          _SettingsTile(
                            icon: Icons.notifications_none_rounded,
                            title: "Notifications",
                            subtitle: "Message notification settings",
                            onTap: () => Navigator.pushNamed(
                                context, AppRoutes.settingsNotifications),
                          ),
                          const _Divider(),
                          _SettingsTile(
                            icon: Icons.text_fields_rounded,
                            title: "Fonts & Contrast",
                            subtitle: "Font size, readability options",
                            onTap: () => Navigator.pushNamed(
                                context, AppRoutes.settingsAccessibility),
                          ),
                          const _Divider(),
                          _SettingsTile(
                            icon: Icons.video_call_outlined,
                            title: "Voice & Video Call",
                            subtitle: "Camera, mic & speakers",
                            onTap: () => Navigator.pushNamed(
                                context, AppRoutes.settingsCalls),
                          ),
                          const _Divider(),
                          _SettingsTile(
                            icon: Icons.info_outline_rounded,
                            title: "About",
                            subtitle: "Version, terms, privacy policy",
                            onTap: () => Navigator.pushNamed(
                                context, AppRoutes.settingsAbout),
                          ),
                          const _Divider(),
                          _SettingsTile(
                            icon: Icons.help_outline_rounded,
                            title: "Help & Support",
                            subtitle: "Help centre, contact support",
                            onTap: () => Navigator.pushNamed(
                                context, AppRoutes.settingsHelp),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24), // nice bottom padding
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ✅ Single tile row
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  final Color? iconColor;
  final Color? titleColor;
  final bool hideArrow;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.titleColor,
    this.hideArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color iconClr = iconColor ?? const Color(0xFF334155);
    final Color titleClr = titleColor ?? const Color(0xFF0F172A);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconClr.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconClr, size: 24),
            ),
            const SizedBox(width: 12),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w900,
                      color: titleClr,
                    ),
                  ),
                  if (subtitle.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            if (!hideArrow)
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}

/// ✅ Clean divider like WhatsApp
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
