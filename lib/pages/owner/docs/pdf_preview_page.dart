import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdfx/pdfx.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class PdfPreviewPage extends StatefulWidget {
  final String title;
  final String pdfUrl;

  const PdfPreviewPage({
    super.key,
    required this.title,
    required this.pdfUrl,
  });

  @override
  State<PdfPreviewPage> createState() => _PdfPreviewPageState();
}

class _PdfPreviewPageState extends State<PdfPreviewPage> {
  PdfControllerPinch? controller;
  bool loading = true;
  String error = "";

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      setState(() {
        loading = true;
        error = "";
      });

      final res = await http.get(Uri.parse(widget.pdfUrl));

      if (res.statusCode != 200) {
        throw Exception("Failed to download PDF (${res.statusCode})");
      }

      final dir = await getTemporaryDirectory();
      final file = File("${dir.path}/temp_preview.pdf");
      await file.writeAsBytes(res.bodyBytes, flush: true);

      controller = PdfControllerPinch(
        document: PdfDocument.openFile(file.path),
      );

      setState(() => loading = false);
    } catch (e) {
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          widget.title,
          style: GoogleFonts.inter(fontWeight: FontWeight.w900),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      error,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : PdfViewPinch(controller: controller!),
    );
  }
}
