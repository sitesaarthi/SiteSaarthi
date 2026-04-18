import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class EngineerToolsPage extends StatefulWidget {
  const EngineerToolsPage({super.key});

  @override
  State<EngineerToolsPage> createState() => _EngineerToolsPageState();
}

class _EngineerToolsPageState extends State<EngineerToolsPage> {
  final toolNameCtrl = TextEditingController();

  File? issuePhoto;
  File? qrPhoto;
  String? scannedQr;

  final picker = ImagePicker();

  /// 📸 CAMERA PHOTO
  Future<void> _takePhoto(bool isIssue) async {
    final img = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    if (img == null) return;

    setState(() {
      if (isIssue) {
        issuePhoto = File(img.path);
      } else {
        qrPhoto = File(img.path);
      }
    });
  }

  /// 📷 QR SCANNER
  void _openQrScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text("Scan Tool QR")),
          body: MobileScanner(
            onDetect: (capture) {
              final barcode = capture.barcodes.first;
              if (barcode.rawValue == null) return;

              setState(() {
                scannedQr = barcode.rawValue;
              });

              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }

  bool get canSubmit =>
      toolNameCtrl.text.trim().isNotEmpty &&
      issuePhoto != null &&
      (qrPhoto != null || scannedQr != null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text("Tools IN / OUT")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// TOOL NAME
            _field(toolNameCtrl, "Tool / Machinery Name"),

            const SizedBox(height: 16),

            /// ISSUE PHOTO
            _photoCard(
              title: "Tool Issue Photo",
              subtitle: "Photo while taking the tool",
              file: issuePhoto,
              onTap: () => _takePhoto(true),
              icon: Icons.camera_alt_rounded,
            ),

            const SizedBox(height: 14),

            /// QR SECTION
            Container(
              padding: const EdgeInsets.all(14),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Tool Return (QR)",
                    style: TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Scan QR or take QR photo while returning",
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),

                  if (scannedQr != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.qr_code, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              scannedQr!,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (qrPhoto != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(qrPhoto!, height: 120),
                      ),
                    ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text("Scan QR"),
                          onPressed: _openQrScanner,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.camera_alt),
                          label: const Text("Take Photo"),
                          onPressed: () => _takePhoto(false),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// SUBMIT
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canSubmit
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Tool entry recorded (local) ✅")),
                        );
                      }
                    : null,
                child: const Text(
                  "SUBMIT",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔧 HELPERS
  Widget _field(TextEditingController c, String hint) {
    return TextField(
      controller: c,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }

  Widget _photoCard({
    required String title,
    required String subtitle,
    required File? file,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.orange),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600)),
                ],
              ),
            ),
            if (file != null)
              const Icon(Icons.check_circle, color: Colors.green),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.grey.shade200),
    );
  }

  @override
  void dispose() {
    toolNameCtrl.dispose();
    super.dispose();
  }
}
