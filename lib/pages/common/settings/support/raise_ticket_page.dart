import 'dart:math';
import 'package:flutter/material.dart';

class RaiseTicketPage extends StatefulWidget {
  const RaiseTicketPage({super.key});

  @override
  State<RaiseTicketPage> createState() => _RaiseTicketPageState();
}

class _RaiseTicketPageState extends State<RaiseTicketPage> {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  String category = "Bug / Crash";

  @override
  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    super.dispose();
  }

  String _ticketId() {
    final n = 100000 + Random().nextInt(900000);
    return "SS-$n";
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
        title: const Text("Raise a Ticket",
            style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _card(
            child: Column(
              children: [
                _select(
                  context,
                  icon: Icons.category_outlined,
                  title: "Category",
                  subtitle: category,
                  options: const [
                    "Bug / Crash",
                    "Login / OTP",
                    "Chat Issue",
                    "Attendance / GPS",
                    "Material / Leakage",
                    "Other"
                  ],
                  onSelected: (v) => setState(() => category = v),
                ),
                const Divider(height: 0, thickness: 1, color: Color(0xFFF1F5F9)),
                _field(
                  label: "Title",
                  hint: "Example: OTP not working",
                  controller: titleCtrl,
                ),
                const Divider(height: 0, thickness: 1, color: Color(0xFFF1F5F9)),
                _field(
                  label: "Describe the issue",
                  hint: "Write details so support team can solve quickly",
                  controller: descCtrl,
                  maxLines: 5,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.trim().isEmpty || descCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please fill all fields")),
                );
                return;
              }
              final id = _ticketId();
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Ticket Created ✅"),
                  content: Text("Your Ticket ID is: $id\n\nWe will respond soon."),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))
                  ],
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B3C5D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text("Submit Ticket", style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  static Widget _card({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(blurRadius: 22, offset: Offset(0, 10), color: Color(0x0A000000)),
        ],
      ),
      child: child,
    );
  }

  static Widget _field({
    required String label,
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _select(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required List<String> options,
    required ValueChanged<String> onSelected,
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
          builder: (_) => SafeArea(
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
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                ...options.map(
                  (opt) => ListTile(
                    title: Text(opt, style: const TextStyle(fontWeight: FontWeight.w800)),
                    trailing: opt == subtitle
                        ? const Icon(Icons.check_rounded, color: Color(0xFF16A34A))
                        : null,
                    onTap: () => Navigator.pop(context, opt),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );

        if (selected != null) onSelected(selected);
      },
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
