import 'package:flutter/material.dart';
import 'app_settings_store.dart';

class NotificationsSettingsPage extends StatefulWidget {
  const NotificationsSettingsPage({super.key});

  @override
  State<NotificationsSettingsPage> createState() =>
      _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState extends State<NotificationsSettingsPage> {
  bool loading = true;

  // Message alerts
  bool chatNotifications = true;
  bool groupNotifications = true;
  bool muteProjects = false;
  String notificationSound = "Default";
  bool vibration = true;

  // Site alerts
  bool materialLeakageAlerts = true;
  bool lowStockAlerts = true;
  bool labourAbsenceAlerts = true;
  bool delayRiskAlerts = true;
  bool paymentApprovalAlerts = true;

  // Call alerts
  bool incomingCallNotifications = true;
  bool videoCallNotifications = true;
  bool silentDuringMeetings = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await AppSettingsStore.loadNotificationSettings();
    setState(() {
      chatNotifications = s.chatNotifications;
      groupNotifications = s.groupNotifications;
      muteProjects = s.muteProjects;
      notificationSound = s.notificationSound;
      vibration = s.vibration;

      materialLeakageAlerts = s.materialLeakageAlerts;
      lowStockAlerts = s.lowStockAlerts;
      labourAbsenceAlerts = s.labourAbsenceAlerts;
      delayRiskAlerts = s.delayRiskAlerts;
      paymentApprovalAlerts = s.paymentApprovalAlerts;

      incomingCallNotifications = s.incomingCallNotifications;
      videoCallNotifications = s.videoCallNotifications;
      silentDuringMeetings = s.silentDuringMeetings;

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
          "Notifications",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle("Message Alerts"),
          _card(
            children: [
              SwitchListTile(
                value: chatNotifications,
                onChanged: (v) async {
                  setState(() => chatNotifications = v);
                  await AppSettingsStore.setChatNotifications(v);
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                title: const Text("Chat Message Notifications",
                    style: TextStyle(fontWeight: FontWeight.w900)),
                subtitle: const Text("Get notified for direct messages",
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              const _Divider(),
              SwitchListTile(
                value: groupNotifications,
                onChanged: (v) async {
                  setState(() => groupNotifications = v);
                  await AppSettingsStore.setGroupNotifications(v);
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                title: const Text("Group Message Notifications",
                    style: TextStyle(fontWeight: FontWeight.w900)),
                subtitle: const Text("Get notified for group updates",
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              const _Divider(),
              SwitchListTile(
                value: muteProjects,
                onChanged: (v) async {
                  setState(() => muteProjects = v);
                  await AppSettingsStore.setMuteProjects(v);
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                title: const Text("Mute Specific Projects",
                    style: TextStyle(fontWeight: FontWeight.w900)),
                subtitle: const Text("Silence chat alerts from selected projects",
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              const _Divider(),
              _selectTile(
                context: context,
                icon: Icons.music_note_outlined,
                title: "Notification Sound",
                subtitle: notificationSound,
                options: const ["Default", "Beep", "Bell", "Silent"],
                onSelected: (val) async {
                  setState(() => notificationSound = val);
                  await AppSettingsStore.setNotificationSound(val);
                },
              ),
              const _Divider(),
              SwitchListTile(
                value: vibration,
                onChanged: (v) async {
                  setState(() => vibration = v);
                  await AppSettingsStore.setVibration(v);
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                title: const Text("Vibration",
                    style: TextStyle(fontWeight: FontWeight.w900)),
                subtitle: const Text("Vibrate on notifications",
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),

          const SizedBox(height: 18),

          _sectionTitle("Site Alerts"),
          _card(
            children: [
              _toggle(
                title: "Material Leakage Alerts",
                subtitle: "Detect material loss / misuse",
                value: materialLeakageAlerts,
                onChanged: (v) async {
                  setState(() => materialLeakageAlerts = v);
                  await AppSettingsStore.setMaterialLeakageAlerts(v);
                },
              ),
              const _Divider(),
              _toggle(
                title: "Low Stock Alerts",
                subtitle: "Get notified when stock is low",
                value: lowStockAlerts,
                onChanged: (v) async {
                  setState(() => lowStockAlerts = v);
                  await AppSettingsStore.setLowStockAlerts(v);
                },
              ),
              const _Divider(),
              _toggle(
                title: "Labour Absence Alerts",
                subtitle: "Missing labour / attendance issues",
                value: labourAbsenceAlerts,
                onChanged: (v) async {
                  setState(() => labourAbsenceAlerts = v);
                  await AppSettingsStore.setLabourAbsenceAlerts(v);
                },
              ),
              const _Divider(),
              _toggle(
                title: "Delay Risk Alerts",
                subtitle: "High delay risk in schedule",
                value: delayRiskAlerts,
                onChanged: (v) async {
                  setState(() => delayRiskAlerts = v);
                  await AppSettingsStore.setDelayRiskAlerts(v);
                },
              ),
              const _Divider(),
              _toggle(
                title: "Payment Approval Alerts",
                subtitle: "Owner approval reminders",
                value: paymentApprovalAlerts,
                onChanged: (v) async {
                  setState(() => paymentApprovalAlerts = v);
                  await AppSettingsStore.setPaymentApprovalAlerts(v);
                },
              ),
            ],
          ),

          const SizedBox(height: 18),

          _sectionTitle("Call Alerts"),
          _card(
            children: [
              _toggle(
                title: "Incoming Call Notifications",
                subtitle: "Show alerts for voice calls",
                value: incomingCallNotifications,
                onChanged: (v) async {
                  setState(() => incomingCallNotifications = v);
                  await AppSettingsStore.setIncomingCallNotifications(v);
                },
              ),
              const _Divider(),
              _toggle(
                title: "Video Call Notifications",
                subtitle: "Show alerts for video calls",
                value: videoCallNotifications,
                onChanged: (v) async {
                  setState(() => videoCallNotifications = v);
                  await AppSettingsStore.setVideoCallNotifications(v);
                },
              ),
              const _Divider(),
              _toggle(
                title: "Silent During Meetings",
                subtitle: "Auto-silence calls while in meetings",
                value: silentDuringMeetings,
                onChanged: (v) async {
                  setState(() => silentDuringMeetings = v);
                  await AppSettingsStore.setSilentDuringMeetings(v);
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

  static Widget _toggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(subtitle, style: const TextStyle(fontWeight: FontWeight.w600)),
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
