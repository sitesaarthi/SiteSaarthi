import 'package:flutter/material.dart';
import 'app_settings_store.dart';

class GeneralSettingsPage extends StatefulWidget {
  const GeneralSettingsPage({super.key});

  @override
  State<GeneralSettingsPage> createState() => _GeneralSettingsPageState();
}

class _GeneralSettingsPageState extends State<GeneralSettingsPage> {
  String language = "English";
  String startupScreen = "Dashboard";
  String syncMode = "Wi-Fi only";

  bool lowDataMode = false;
  bool autoUpdateProjectData = true;

  TimeOfDay workStart = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay workEnd = const TimeOfDay(hour: 18, minute: 0);

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await AppSettingsStore.loadGeneralSettings();
    setState(() {
      language = data.language;
      startupScreen = data.startupScreen;
      syncMode = data.syncMode;
      lowDataMode = data.lowDataMode;
      autoUpdateProjectData = data.autoUpdateProjectData;
      workStart = data.workStart;
      workEnd = data.workEnd;
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
          "General",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle("Startup & Preferences"),
          _card(
            children: [
              _selectTile(
                context: context,
                icon: Icons.language_rounded,
                title: "Default Language",
                subtitle: language,
                options: const ["English", "Hindi", "Marathi"],
                onSelected: (val) async {
                  setState(() => language = val);
                  await AppSettingsStore.setLanguage(val);
                },
              ),
              const _Divider(),

              _selectTile(
                context: context,
                icon: Icons.rocket_launch_outlined,
                title: "App Startup Screen",
                subtitle: startupScreen,
                options: const ["Dashboard", "Projects", "Chat"],
                onSelected: (val) async {
                  setState(() => startupScreen = val);
                  await AppSettingsStore.setStartupScreen(val);
                },
              ),
              const _Divider(),

              _selectTile(
                context: context,
                icon: Icons.sync_rounded,
                title: "Auto-Sync Data",
                subtitle: syncMode,
                options: const ["Wi-Fi only", "Always"],
                onSelected: (val) async {
                  setState(() => syncMode = val);
                  await AppSettingsStore.setSyncMode(val);
                },
              ),
              const _Divider(),

              SwitchListTile(
                value: lowDataMode,
                onChanged: (v) async {
                  setState(() => lowDataMode = v);
                  await AppSettingsStore.setLowDataMode(v);
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                title: const Text(
                  "Low Data Mode",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: const Text(
                  "Useful for weak network construction sites",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const _Divider(),

              SwitchListTile(
                value: autoUpdateProjectData,
                onChanged: (v) async {
                  setState(() => autoUpdateProjectData = v);
                  await AppSettingsStore.setAutoUpdateProjectData(v);
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                title: const Text(
                  "Auto-Update Project Data",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: const Text(
                  "Keeps your site data up to date automatically",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          _sectionTitle("Storage"),
          _card(
            children: [
              ListTile(
                leading: _iconBox(Icons.cleaning_services_outlined),
                title: const Text(
                  "Clear Cache",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: const Text(
                  "Remove temporary files to free up space",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Cache cleared ✅")),
                  );
                },
              ),
              const _Divider(),
              ListTile(
                leading: _iconBox(Icons.storage_rounded),
                title: const Text(
                  "Storage Usage",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: const Text(
                  "Used: 124 MB • Free: 3.1 GB (mock)",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          _sectionTitle("Working Hours"),
          _card(
            children: [
              ListTile(
                leading: _iconBox(Icons.access_time_rounded),
                title: const Text(
                  "Set Working Hours",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(
                  "${_formatTime(workStart)} to ${_formatTime(workEnd)}",
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () async {
                  final start = await showTimePicker(
                    context: context,
                    initialTime: workStart,
                  );
                  if (start == null) return;

                  final end = await showTimePicker(
                    context: context,
                    initialTime: workEnd,
                  );
                  if (end == null) return;

                  setState(() {
                    workStart = start;
                    workEnd = end;
                  });

                  await AppSettingsStore.setWorkingHours(start, end);

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Working hours updated ✅")),
                  );
                },
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

  static String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, "0");
    final period = t.period == DayPeriod.am ? "AM" : "PM";
    return "$hour:$minute $period";
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
