import 'package:flutter/material.dart';
import 'app_settings_store.dart';

class AccessibilitySettingsPage extends StatefulWidget {
  const AccessibilitySettingsPage({super.key});

  @override
  State<AccessibilitySettingsPage> createState() =>
      _AccessibilitySettingsPageState();
}

class _AccessibilitySettingsPageState extends State<AccessibilitySettingsPage> {
  bool loading = true;

  double fontScale = 1.0;
  bool highContrast = false;
  bool boldText = false;
  String colorBlindMode = "Off";

  bool readAloudEnabled = false;
  double readSpeed = 1.0;

  double textSpacing = 0.0;
  double buttonScale = 1.0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await AppSettingsStore.loadAccessibilitySettings();
    setState(() {
      fontScale = s.fontScale;
      highContrast = s.highContrast;
      boldText = s.boldText;
      colorBlindMode = s.colorBlindMode;
      readAloudEnabled = s.readAloudEnabled;
      readSpeed = s.readSpeed;
      textSpacing = s.textSpacing;
      buttonScale = s.buttonScale;
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
          "Fonts, Contrast, etc",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle("Text"),
          _card(
            children: [
              ListTile(
                leading: _iconBox(Icons.format_size_rounded),
                title: const Text("Font Size",
                    style: TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text(
                  _fontLabel(fontScale),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 14, right: 14, bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _preview(fontScale: fontScale, bold: boldText, spacing: textSpacing),
                    const SizedBox(height: 10),
                    Slider(
                      min: 0.90,
                      max: 1.25,
                      divisions: 7,
                      value: fontScale,
                      onChanged: (v) async {
                        setState(() => fontScale = v);
                        await AppSettingsStore.setAccessibilityFontScale(v);
                      },
                    ),
                  ],
                ),
              ),
              const _Divider(),

              SwitchListTile(
                value: boldText,
                onChanged: (v) async {
                  setState(() => boldText = v);
                  await AppSettingsStore.setBoldText(v);
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                title: const Text("Bold Text",
                    style: TextStyle(fontWeight: FontWeight.w900)),
                subtitle: const Text("Improve readability for small text",
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              const _Divider(),

              ListTile(
                leading: _iconBox(Icons.space_bar_rounded),
                title: const Text("Text Spacing",
                    style: TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text(
                  "Spacing: ${textSpacing.toStringAsFixed(1)}",
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 14, right: 14, bottom: 14),
                child: Slider(
                  min: 0.0,
                  max: 2.0,
                  divisions: 8,
                  value: textSpacing,
                  onChanged: (v) async {
                    setState(() => textSpacing = v);
                    await AppSettingsStore.setTextSpacing(v);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          _sectionTitle("Contrast & Color"),
          _card(
            children: [
              SwitchListTile(
                value: highContrast,
                onChanged: (v) async {
                  setState(() => highContrast = v);
                  await AppSettingsStore.setHighContrast(v);
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                title: const Text("High Contrast Mode",
                    style: TextStyle(fontWeight: FontWeight.w900)),
                subtitle: const Text("Sharper colors and clearer borders",
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              const _Divider(),

              _selectTile(
                context: context,
                icon: Icons.visibility_outlined,
                title: "Color Blind Mode",
                subtitle: colorBlindMode,
                options: const ["Off", "Protanopia", "Deuteranopia", "Tritanopia"],
                onSelected: (val) async {
                  setState(() => colorBlindMode = val);
                  await AppSettingsStore.setColorBlindMode(val);

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        val == "Off"
                            ? "Color blind mode disabled"
                            : "Color blind mode set to $val (mock)",
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 18),

          _sectionTitle("Read Aloud"),
          _card(
            children: [
              SwitchListTile(
                value: readAloudEnabled,
                onChanged: (v) async {
                  setState(() => readAloudEnabled = v);
                  await AppSettingsStore.setReadAloudEnabled(v);
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                title: const Text("Read Aloud Mode",
                    style: TextStyle(fontWeight: FontWeight.w900)),
                subtitle: const Text("Voice reads screens aloud",
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              const _Divider(),

              ListTile(
                leading: _iconBox(Icons.speed_rounded),
                title: const Text("Read Speed Control",
                    style: TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text(
                  "Speed: ${readSpeed.toStringAsFixed(1)}x",
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 14, right: 14, bottom: 14),
                child: Slider(
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  value: readSpeed,
                  onChanged: (v) async {
                    setState(() => readSpeed = v);
                    await AppSettingsStore.setReadSpeed(v);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          _sectionTitle("Controls"),
          _card(
            children: [
              ListTile(
                leading: _iconBox(Icons.touch_app_outlined),
                title: const Text("Button Size",
                    style: TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text(
                  "Scale: ${buttonScale.toStringAsFixed(2)}",
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 14, right: 14, bottom: 14),
                child: Slider(
                  min: 0.9,
                  max: 1.2,
                  divisions: 6,
                  value: buttonScale,
                  onChanged: (v) async {
                    setState(() => buttonScale = v);
                    await AppSettingsStore.setButtonScale(v);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- UI helpers ----------------

  static String _fontLabel(double v) {
    if (v <= 0.95) return "Small";
    if (v <= 1.05) return "Default";
    if (v <= 1.15) return "Large";
    return "Extra Large";
  }

  static Widget _preview({
    required double fontScale,
    required bool bold,
    required double spacing,
  }) {
    final base = TextStyle(
      fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
      height: 1.2 + (spacing * 0.15),
      letterSpacing: spacing * 0.1,
      color: const Color(0xFF0F172A),
    );

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
            "Material Delivered ✅",
            textScaler: TextScaler.linear(fontScale),
            style: base.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            "Owner: Update stock entry and attach site photos.",
            textScaler: TextScaler.linear(fontScale),
            style: base,
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
