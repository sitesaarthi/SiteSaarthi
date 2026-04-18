import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'pdf_preview_page.dart';

class OwnerManualDocPage extends StatefulWidget {
  final String docKey; // rera / iod / cc
  final String title;
  final String subtitle;

  const OwnerManualDocPage({
    super.key,
    required this.docKey,
    required this.title,
    required this.subtitle,
  });

  @override
  State<OwnerManualDocPage> createState() => _OwnerManualDocPageState();
}

class _OwnerManualDocPageState extends State<OwnerManualDocPage> {
  static const String baseUrl = "http://10.0.2.2:5000/api";

  bool loading = true;
  bool uploading = false;
  bool deleting = false;

  String errorMsg = "";

  String projectId = "";
  Map<String, dynamic>? doc;

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("authToken") ?? "";
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final pid = (args?["projectId"] ?? "").toString();

    if (pid.isNotEmpty && pid != projectId) {
      projectId = pid;
      _fetchDoc();
    }
  }

  bool get isUploaded {
    if (doc == null) return false;
    return (doc!["uploaded"] == true) || ((doc!["url"] ?? "").toString().isNotEmpty);
  }

  String get fileUrl {
    if (doc == null) return "";
    return (doc!["url"] ?? doc!["pdfUrl"] ?? "").toString();
  }

  String _normalizeUrl(String u) {
    if (u.trim().isEmpty) return "";
    if (u.startsWith("http")) return u;
    return "http://10.0.2.2:5000$u"; // for local stored pdf
  }

  Future<void> _fetchDoc({bool silent = false}) async {
    final token = await _getToken();
    if (token.isEmpty) return;

    try {
      if (!silent) {
        setState(() {
          loading = true;
          errorMsg = "";
        });
      }

      final res = await http.get(
        Uri.parse("$baseUrl/docs/$projectId/single?key=${widget.docKey}"),
        headers: {"Authorization": "Bearer $token"},
      );

      final body = res.body.isEmpty ? {} : jsonDecode(res.body);

      if (res.statusCode >= 400) {
        throw body["message"] ?? "Failed to load";
      }

      setState(() {
        doc = body["doc"];
        loading = false;
      });
    } catch (e) {
      setState(() {
        errorMsg = "$e";
        loading = false;
      });
    }
  }

  Future<void> _pickAndUpload() async {
    final token = await _getToken();
    if (token.isEmpty) return;

    try {
      // ✅ Works on Android/Windows
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ["pdf"],
        allowMultiple: false,
      );

      if (picked == null || picked.files.isEmpty) return;

      final path = picked.files.single.path;
      if (path == null) return;

      setState(() {
        uploading = true;
        errorMsg = "";
      });

      final req = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/docs/$projectId/upload"),
      );

      req.headers["Authorization"] = "Bearer $token";
      req.fields["key"] = widget.docKey;

      req.files.add(await http.MultipartFile.fromPath(
        "pdf",
        path,
        filename: File(path).path.split("/").last,
      ));

      final streamed = await req.send();
      final respBody = await streamed.stream.bytesToString();
      final data = respBody.isEmpty ? {} : jsonDecode(respBody);

      if (streamed.statusCode >= 400) {
        throw data["message"] ?? "Upload failed";
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${widget.title} uploaded ✅")),
      );

      await _fetchDoc(silent: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload error: $e")),
      );
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  Future<void> _deleteDoc() async {
    final token = await _getToken();
    if (token.isEmpty) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete document?"),
        content: const Text("This will remove the uploaded PDF permanently."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      setState(() {
        deleting = true;
        errorMsg = "";
      });

      final res = await http.delete(
        Uri.parse("$baseUrl/docs/$projectId/manual?key=${widget.docKey}"),
        headers: {"Authorization": "Bearer $token"},
      );

      final body = res.body.isEmpty ? {} : jsonDecode(res.body);

      if (res.statusCode >= 400) {
        throw body["message"] ?? "Delete failed";
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${widget.title} deleted ✅")),
      );

      await _fetchDoc(silent: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Delete error: $e")),
      );
    } finally {
      if (mounted) setState(() => deleting = false);
    }
  }

  Future<void> _preview() async {
  final token = await _getToken();
  if (token.isEmpty) return;

  final raw = fileUrl.trim();
  if (raw.isEmpty) return;

  try {
    String finalUrl = raw;

    // ✅ if stored url is S3 format -> get signed https url from backend
    if (raw.startsWith("s3://")) {
      final res = await http.get(
        Uri.parse(
          "$baseUrl/docs/$projectId/manual-url?key=${widget.docKey}",
        ),
        headers: {"Authorization": "Bearer $token"},
      );

      final body = res.body.isEmpty ? {} : jsonDecode(res.body);

      if (res.statusCode >= 400) {
        throw body["message"] ?? "Failed to get signed url";
      }

      finalUrl = (body["url"] ?? "").toString();
    } else {
      // ✅ local server pdf path
      finalUrl = _normalizeUrl(raw);
    }

    if (finalUrl.isEmpty) throw "Empty PDF URL";

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfPreviewPage(
          title: widget.title,
          pdfUrl: finalUrl,
        ),
      ),
    );
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Preview error: $e")),
    );
  }
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
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text(widget.title, style: GoogleFonts.inter(fontWeight: FontWeight.w900)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.subtitle,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 18),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x11000000), blurRadius: 14, offset: Offset(0, 8)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: isUploaded ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            isUploaded ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                            color: isUploaded ? const Color(0xFF059669) : const Color(0xFFD97706),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isUploaded ? "Document Uploaded" : "No Document Uploaded",
                            style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    if (isUploaded) ...[
                      Text(
                        "Only ONE file is allowed. Preview or delete if uploaded wrong document.",
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _preview(),
                              icon: const Icon(Icons.picture_as_pdf_rounded),
                              label: const Text("Preview PDF"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0B3C5D),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: deleting ? null : _deleteDoc,
                              icon: deleting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.delete_rounded),
                              label: Text(deleting ? "Deleting..." : "Delete"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFDC2626),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Text(
                        "Upload the official PDF. It will be stored in S3.",
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: uploading ? null : _pickAndUpload,
                          icon: uploading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.upload_rounded),
                          label: Text(uploading ? "Uploading..." : "Upload PDF"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              if (errorMsg.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  errorMsg,
                  style: GoogleFonts.inter(
                    color: const Color(0xFFDC2626),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
