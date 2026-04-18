import 'package:flutter/material.dart';
import 'app_settings_store.dart';

class ChatsSettingsPage extends StatefulWidget {
  const ChatsSettingsPage({super.key});

  @override
  State<ChatsSettingsPage> createState() => _ChatsSettingsPageState();
}

class _ChatsSettingsPageState extends State<ChatsSettingsPage> {
  bool loading = true;

  String chatTheme = "System";
  String wallpaper = "Default";
  double chatFontScale = 1.0;

  bool lockPreview = true;
  bool lastSeen = true;
  bool typingIndicator = true;

  bool autoDownloadMedia = true;
  bool voiceAutoPlay = true;
  bool cloudBackup = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await AppSettingsStore.loadChatSettings();
    setState(() {
      chatTheme = data.chatTheme;
      wallpaper = data.wallpaper;
      chatFontScale = data.chatFontScale;

      lockPreview = data.lockScreenPreview;
      lastSeen = data.showLastSeen;
      typingIndicator = data.typingIndicator;

      autoDownloadMedia = data.autoDownloadMedia;
      voiceAutoPlay = data.voiceAutoPlay;
      cloudBackup = data.cloudBackup;

      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: const Text(
          "Chats",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle("Theme & Appearance"),
          _card(
            children: [
              _selectTile(
                context: context,
                icon: Icons.brightness_6_outlined,
                title: "Chat Theme",
                subtitle: chatTheme,
                options: const ["Light", "Dark", "System"],
                onSelected: (val) async {
                  setState(() => chatTheme = val);
                  await AppSettingsStore.setChatTheme(val);

                  // Optional: if you want to sync app theme with chat theme
                  if (val == "Light") {
                    await AppSettingsStore.setThemeMode(ThemeMode.light);
                  } else if (val == "Dark") {
                    await AppSettingsStore.setThemeMode(ThemeMode.dark);
                  } else {
                    await AppSettingsStore.setThemeMode(ThemeMode.system);
                  }
                },
              ),
              const _Divider(),

              _selectTile(
                context: context,
                icon: Icons.wallpaper_outlined,
                title: "Chat Wallpaper",
                subtitle: wallpaper,
                options: const ["Default", "Solid Color", "Site Photos"],
                onSelected: (val) async {
                  setState(() => wallpaper = val);
                  await AppSettingsStore.setChatWallpaper(val);
                },
              ),
              const _Divider(),

              ListTile(
                leading: _iconBox(Icons.format_size_rounded),
                title: const Text("Font Size in Chat",
                    style: TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text(
                  "Scale: ${chatFontScale.toStringAsFixed(2)}",
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(left: 14, right: 14, bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _chatPreview(scale: chatFontScale),
                    const SizedBox(height: 10),
                    Slider(
                      min: 0.9,
                      max: 1.2,
                      divisions: 6,
                      value: chatFontScale,
                      onChanged: (v) async {
                        setState(() => chatFontScale = v);
                        await AppSettingsStore.setChatFontScale(v);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          _sectionTitle("Privacy"),
          _card(
            children: [
              SwitchListTile(
                value: lockPreview,
                onChanged: (v) async {
                  setState(() => lockPreview = v);
                  await AppSettingsStore.setLockPreview(v);
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                title: const Text("Message Preview on Lock Screen",
                    style: TextStyle(fontWeight: FontWeight.w900)),
                subtitle: const Text("Show message content on notifications",
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              const _Divider(),

              SwitchListTile(
                value: lastSeen,
                onChanged: (v) async {
                  setState(() => lastSeen = v);
                  await AppSettingsStore.setLastSeen(v);
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                title: const Text("Show Last Seen",
                    style: TextStyle(fontWeight: FontWeight.w900)),
                subtitle: const Text("Allow others to see last active status",
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              const _Divider(),

              SwitchListTile(
                value: typingIndicator,
                onChanged: (v) async {
                  setState(() => typingIndicator = v);
                  await AppSettingsStore.setTypingIndicator(v);
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                title: const Text("Typing Indicator",
                    style: TextStyle(fontWeight: FontWeight.w900)),
                subtitle: const Text("Show when you're typing",
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),

          const SizedBox(height: 18),

          _sectionTitle("Media & Backup"),
          _card(
            children: [
              SwitchListTile(
                value: autoDownloadMedia,
                onChanged: (v) async {
                  setState(() => autoDownloadMedia = v);
                  await AppSettingsStore.setAutoDownloadMedia(v);
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                title: const Text("Auto-download Images & Videos",
                    style: TextStyle(fontWeight: FontWeight.w900)),
                subtitle: const Text("Download media automatically in chat",
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              const _Divider(),

              SwitchListTile(
                value: voiceAutoPlay,
                onChanged: (v) async {
                  setState(() => voiceAutoPlay = v);
                  await AppSettingsStore.setVoiceAutoPlay(v);
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                title: const Text("Voice Message Auto-Play",
                    style: TextStyle(fontWeight: FontWeight.w900)),
                subtitle: const Text("Plays voice notes automatically",
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              const _Divider(),

              SwitchListTile(
                value: cloudBackup,
                onChanged: (v) async {
                  setState(() => cloudBackup = v);
                  await AppSettingsStore.setChatBackup(v);
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                title: const Text("Chat Backup to Cloud",
                    style: TextStyle(fontWeight: FontWeight.w900)),
                subtitle: const Text("Keeps your messages safe",
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- UI helpers ----------------

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

  static Widget _selectTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<String> options,
    required Future<void> Function(String) onSelected,
  }) {
    return ListTile(
      leading: _iconBox(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(subtitle, style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () async {
        final selected = await showModalBottomSheet<String>(
          context: context,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          builder: (_) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  ...options.map(
                    (opt) => ListTile(
                      title: Text(opt, style: const TextStyle(fontWeight: FontWeight.w800)),
                      trailing: (opt == subtitle)
                          ? const Icon(Icons.check_rounded, color: Color(0xFF16A34A))
                          : null,
                      onTap: () => Navigator.pop(context, opt),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );

        if (selected != null) await onSelected(selected);
      },
    );
  }

  static Widget _chatPreview({required double scale}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Site Engineer: Cement arrived ✅",
            textScaler: TextScaler.linear(scale),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            "Owner: Great. Update stock entry and share photos.",
            textScaler: TextScaler.linear(scale),
            style: const TextStyle(fontWeight: FontWeight.w700),
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
