import 'package:flutter/material.dart';
import 'app_settings_store.dart';

class CallsSettingsPage extends StatefulWidget {
  const CallsSettingsPage({super.key});

  @override
  State<CallsSettingsPage> createState() => _CallsSettingsPageState();
}

class _CallsSettingsPageState extends State<CallsSettingsPage> {
  bool loading = true;

  String defaultCallType = "Voice";
  String cameraSelection = "Front";
  double micSensitivity = 0.6;

  bool noiseCancellation = true;
  bool lowBandwidthMode = false;
  bool callRecording = false;

  bool speakerAutoOn = true;
  String callQuality = "HD";

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await AppSettingsStore.loadCallSettings();
    setState(() {
      defaultCallType = s.defaultCallType;
      cameraSelection = s.cameraSelection;
      micSensitivity = s.micSensitivity;
      noiseCancellation = s.noiseCancellation;
      lowBandwidthMode = s.lowBandwidthMode;
      callRecording = s.callRecording;
      speakerAutoOn = s.speakerAutoOn;
      callQuality = s.callQuality;
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
          "Voice & Video Call",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle("Call Preferences"),
          _card(
            children: [
              _selectTile(
                context: context,
                icon: Icons.call_outlined,
                title: "Default Call Type",
                subtitle: defaultCallType,
                options: const ["Voice", "Video"],
                onSelected: (v) async {
                  setState(() => defaultCallType = v);
                  await AppSettingsStore.setDefaultCallType(v);
                },
              ),
              const _Divider(),
              _selectTile(
                context: context,
                icon: Icons.cameraswitch_outlined,
                title: "Camera Selection",
                subtitle: cameraSelection,
                options: const ["Front", "Rear"],
                onSelected: (v) async {
                  setState(() => cameraSelection = v);
                  await AppSettingsStore.setCameraSelection(v);
                },
              ),
            ],
          ),

          const SizedBox(height: 18),

          _sectionTitle("Audio"),
          _card(
            children: [
              ListTile(
                leading: _iconBox(Icons.mic_none_rounded),
                title: const Text("Mic Sensitivity",
                    style: TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text(
                  "Level: ${(micSensitivity * 100).round()}%",
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 14, right: 14, bottom: 14),
                child: Slider(
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  value: micSensitivity,
                  onChanged: (v) async {
                    setState(() => micSensitivity = v);
                    await AppSettingsStore.setMicSensitivity(v);
                  },
                ),
              ),
              const _Divider(),
              SwitchListTile(
                value: noiseCancellation,
                onChanged: (v) async {
                  setState(() => noiseCancellation = v);
                  await AppSettingsStore.setNoiseCancellation(v);
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                title: const Text("Noise Cancellation",
                    style: TextStyle(fontWeight: FontWeight.w900)),
                subtitle: const Text("Reduce background construction noise",
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              const _Divider(),
              SwitchListTile(
                value: speakerAutoOn,
                onChanged: (v) async {
                  setState(() => speakerAutoOn = v);
                  await AppSettingsStore.setSpeakerAutoOn(v);
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                title: const Text("Speaker Auto-On",
                    style: TextStyle(fontWeight: FontWeight.w900)),
                subtitle: const Text("Automatically enable speaker on calls",
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),

          const SizedBox(height: 18),

          _sectionTitle("Network & Quality"),
          _card(
            children: [
              SwitchListTile(
                value: lowBandwidthMode,
                onChanged: (v) async {
                  setState(() => lowBandwidthMode = v);
                  await AppSettingsStore.setLowBandwidthMode(v);
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                title: const Text("Low Bandwidth Mode",
                    style: TextStyle(fontWeight: FontWeight.w900)),
                subtitle: const Text("Better calling in weak network sites",
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              const _Divider(),
              _selectTile(
                context: context,
                icon: Icons.high_quality_rounded,
                title: "Call Quality",
                subtitle: callQuality,
                options: const ["Low", "Medium", "HD"],
                onSelected: (v) async {
                  setState(() => callQuality = v);
                  await AppSettingsStore.setCallQuality(v);
                },
              ),
            ],
          ),

          const SizedBox(height: 18),

          _sectionTitle("Advanced"),
          _card(
            children: [
              SwitchListTile(
                value: callRecording,
                onChanged: (v) async {
                  setState(() => callRecording = v);
                  await AppSettingsStore.setCallRecording(v);

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Call recording is mock for now ✅"),
                    ),
                  );
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                title: const Text("Call Recording",
                    style: TextStyle(fontWeight: FontWeight.w900)),
                subtitle: const Text("Only if allowed by policy/law",
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
