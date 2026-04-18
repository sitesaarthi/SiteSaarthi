import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class ClientProposalPage extends StatefulWidget {
  const ClientProposalPage({super.key});

  @override
  State<ClientProposalPage> createState() => _ClientProposalPageState();
}

class _ClientProposalPageState extends State<ClientProposalPage> {
  static const String baseUrl = "http://10.0.2.2:5000/api";

  bool loading = true;
  String err = "";
  String? signedUrl;

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("authToken") ?? "";
  }

  Future<void> fetchUrl(String projectId) async {
    try {
      setState(() {
        loading = true;
        err = "";
      });

      final token = await _getToken();
      final res = await http.get(
        Uri.parse("$baseUrl/docs/$projectId/auto-url?key=proposal_report"),
        headers: {"Authorization": "Bearer $token"},
      );

      final data = jsonDecode(res.body);
      if (res.statusCode >= 400) throw (data["message"] ?? "Failed");

      setState(() {
        signedUrl = data["url"];
        loading = false;
      });
    } catch (e) {
      setState(() {
        err = e.toString();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final projectId = (args?["projectId"] ?? "").toString();

    if (projectId.isNotEmpty && loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        fetchUrl(projectId);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("RERA Certificate"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : err.isNotEmpty
              ? _errorUI(projectId)
              : (signedUrl == null || signedUrl!.isEmpty)
                  ? _emptyUI()
                  : SfPdfViewer.network(signedUrl!),
    );
  }

  Widget _emptyUI() {
    return Center(
      child: Text(
        "RERA Document not uploaded yet",
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _errorUI(String projectId) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded,
                size: 48, color: Color(0xFFF59E0B)),
            const SizedBox(height: 10),
            Text(
              "Failed to load PDF",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              err,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () => fetchUrl(projectId),
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
            )
          ],
        ),
      ),
    );
  }
}
