import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../owner/docs/pdf_preview_page.dart'; // ✅ update path

class ClientDocPreviewPage extends StatefulWidget {
  final String title;
  final String keyName; // rera / iod / cc / quotation / proposal_report
  final bool isManual; // manual-url OR auto-url

  const ClientDocPreviewPage({
    super.key,
    required this.title,
    required this.keyName,
    required this.isManual,
  });

  @override
  State<ClientDocPreviewPage> createState() => _ClientDocPreviewPageState();
}

class _ClientDocPreviewPageState extends State<ClientDocPreviewPage> {
  static const String baseUrl = "http://10.0.2.2:5000/api";

  bool loading = true;
  String err = "";
  Map<String, dynamic>? doc;

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("authToken") ?? "";
  }

  Future<void> _fetchDocStatus(String projectId) async {
    final token = await _getToken();
    if (token.isEmpty) return;

    try {
      setState(() {
        loading = true;
        err = "";
      });

      final res = await http.get(
        Uri.parse("$baseUrl/docs/$projectId/single?key=${widget.keyName}"),
        headers: {"Authorization": "Bearer $token"},
      );

      final data = jsonDecode(res.body);
      if (res.statusCode >= 400) throw data["message"] ?? "Failed to load doc";

      setState(() {
        doc = (data["doc"] is Map) ? Map<String, dynamic>.from(data["doc"]) : null;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        err = e.toString();
      });
    }
  }

  Future<void> _openSignedUrl(String projectId) async {
    final token = await _getToken();
    if (token.isEmpty) throw "Token missing";

    final endpoint = widget.isManual ? "manual-url" : "auto-url";

    final res = await http.get(
      Uri.parse("$baseUrl/docs/$projectId/$endpoint?key=${widget.keyName}"),
      headers: {"Authorization": "Bearer $token"},
    );

    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) throw data["message"] ?? "Failed to open";

    final signedUrl = data["url"];
    if (signedUrl == null || signedUrl.toString().isEmpty) {
      throw "Signed URL missing";
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfPreviewPage(
          title: widget.title,
          pdfUrl: signedUrl.toString(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final projectId = (args?["projectId"] ?? "").toString();

    if (projectId.isNotEmpty && loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchDocStatus(projectId);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: const BackButton(),
        title: Text(widget.title,
            style: GoogleFonts.inter(fontWeight: FontWeight.w900)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: loading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF0B3C5D)),
              )
            : err.isNotEmpty
                ? _errorBox(projectId)
                : _docBox(projectId),
      ),
    );
  }

  Widget _errorBox(String projectId) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded,
                size: 52, color: Color(0xFFF59E0B)),
            const SizedBox(height: 14),
            Text("Something went wrong",
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A))),
            const SizedBox(height: 6),
            Text(err,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF64748B))),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () => _fetchDocStatus(projectId),
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B3C5D),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _docBox(String projectId) {
    final uploaded = (doc?["uploaded"] ?? false) == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x11000000),
                blurRadius: 14,
                offset: Offset(0, 8),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                  )),
              const SizedBox(height: 6),
              Text(
                uploaded
                    ? "Document available. Tap Preview to view."
                    : "Not uploaded yet by owner.",
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 18),

              // ✅ button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: uploaded
                      ? () async {
                          try {
                            await _openSignedUrl(projectId);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("$e")),
                            );
                          }
                        }
                      : null,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text("Preview"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B3C5D),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE2E8F0),
                    disabledForegroundColor: const Color(0xFF94A3B8),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
