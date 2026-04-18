import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:image_picker/image_picker.dart';
import 'pdf_preview_page.dart'; 
class ProposalPage extends StatefulWidget {
  const ProposalPage({super.key});

  @override
  State<ProposalPage> createState() => _ProposalPageState();
}

class _ProposalPageState extends State<ProposalPage> {
  static const String baseUrl = "http://10.0.2.2:5000/api";

  bool uploading = false;

  // ✅ doc status (from backend project.docs)
  Map<String, dynamic>? doc;
  bool loadingDoc = true;
  String docErr = "";

  // ✅ Metadata controllers
  final TextEditingController companyCtrl =
      TextEditingController(text: "ConstructPro Private Limited");
  final TextEditingController projectCtrl =
      TextEditingController(text: "Primary Health Medical Center");
  final TextEditingController clientCtrl =
      TextEditingController(text: "Sharon Development Group");

  final TextEditingController locationCtrl =
      TextEditingController(text: "Sharon, PA");
  final TextEditingController areaCtrl = TextEditingController(text: "78000");
  final TextEditingController costCtrl =
      TextEditingController(text: "10000000");
  final TextEditingController durationCtrl = TextEditingController(text: "22");
  final TextEditingController typeCtrl =
      TextEditingController(text: "Medical Facility");

  // ✅ Assets store (as bytes)
  final List<Uint8List> siteImages = [];
  final List<Uint8List> planImages = [];
  final List<Uint8List> structuralImages = [];
  final List<Uint8List> renderImages = [];

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("authToken") ?? "";
  }

  // ✅ fetch proposal doc status (uploaded or not)
  Future<void> fetchDoc(String projectId) async {
    final token = await _getToken();
    if (token.isEmpty) return;

    try {
      setState(() {
        loadingDoc = true;
        docErr = "";
      });

      final res = await http.get(
        Uri.parse("$baseUrl/docs/$projectId/single?key=proposal_report"),
        headers: {"Authorization": "Bearer $token"},
      );

      final data = jsonDecode(res.body);
      if (res.statusCode >= 400) {
        throw data["message"] ?? "Failed to load proposal doc";
      }

      setState(() {
        doc = data["doc"];
        loadingDoc = false;
      });
    } catch (e) {
      setState(() {
        loadingDoc = false;
        docErr = e.toString();
      });
    }
  }

  // ✅ pick images
  final ImagePicker _picker = ImagePicker();

  Future<void> pickImages(String type) async {
    try {
      final List<XFile> files = await _picker.pickMultiImage(
        imageQuality: 80, // compress (optional)
      );

      if (files.isEmpty) return;

      // Convert to bytes
      final bytesList = <Uint8List>[];
      for (final f in files) {
        final bytes = await f.readAsBytes();
        bytesList.add(bytes);
      }

      setState(() {
        if (type == "site") siteImages.addAll(bytesList);
        if (type == "plans") planImages.addAll(bytesList);
        if (type == "structural") structuralImages.addAll(bytesList);
        if (type == "renders") renderImages.addAll(bytesList);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Image pick failed: $e")),
      );
    }
  }

  void clearImages(String type) {
    setState(() {
      if (type == "site") siteImages.clear();
      if (type == "plans") planImages.clear();
      if (type == "structural") structuralImages.clear();
      if (type == "renders") renderImages.clear();
    });
  }

  // ✅ PDF generator (8 pages)
  Future<Uint8List> _buildProposalPdf(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    final company = data["companyName"];
    final projectName = data["projectName"];
    final clientName = data["clientName"];
    final location = data["location"];
    final area = data["area"];
    final cost = data["cost"];
    final duration = data["duration"];
    final type = data["type"];
    final proposalNo = data["proposalNumber"];
    final date = data["date"];

    // helper to render image
    pw.Widget imgBox(Uint8List? bytes, {double? height}) {
      if (bytes == null) {
        return pw.Container(
          height: height ?? 200,
          width: double.infinity,
          decoration: pw.BoxDecoration(
            border:
                pw.Border.all(width: 1, color: PdfColor.fromInt(0xFFE5E7EB)),
            borderRadius: pw.BorderRadius.circular(10),
            color: PdfColor.fromInt(0xFFF8FAFC),
          ),
          child: pw.Center(
            child: pw.Text("No Image",
                style: pw.TextStyle(
                    fontSize: 12, color: PdfColor.fromInt(0xFF94A3B8))),
          ),
        );
      }

      return pw.Container(
        height: height ?? 200,
        width: double.infinity,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(width: 1, color: PdfColor.fromInt(0xFFE5E7EB)),
          borderRadius: pw.BorderRadius.circular(10),
        ),
        child: pw.ClipRRect(
          horizontalRadius: 10,
          verticalRadius: 10,
          child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.cover),
        ),
      );
    }

    // ---------- PAGE 1 ----------
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (_) => pw.Padding(
          padding: const pw.EdgeInsets.all(36),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("PROPOSAL DOCUMENT",
                  style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF0EA5E9))),
              pw.SizedBox(height: 10),
              pw.Text(projectName,
                  style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF0F172A))),
              pw.Text(type,
                  style: pw.TextStyle(
                      fontSize: 12, color: PdfColor.fromInt(0xFF64748B))),
              pw.SizedBox(height: 18),

              // hero render
              imgBox(renderImages.isNotEmpty ? renderImages.first : null,
                  height: 320),

              pw.Spacer(),
              pw.Divider(color: PdfColor.fromInt(0xFFE2E8F0)),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("Prepared For",
                            style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromInt(0xFF94A3B8))),
                        pw.Text(clientName,
                            style: pw.TextStyle(
                                fontSize: 14, fontWeight: pw.FontWeight.bold)),
                        pw.Text(company,
                            style: pw.TextStyle(
                                fontSize: 10,
                                color: PdfColor.fromInt(0xFF64748B))),
                      ]),
                  pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text("Reference",
                            style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromInt(0xFF94A3B8))),
                        pw.Text(proposalNo,
                            style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromInt(0xFF0EA5E9))),
                        pw.Text(date,
                            style: pw.TextStyle(
                                fontSize: 10,
                                color: PdfColor.fromInt(0xFF64748B))),
                      ]),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    // ---------- PAGE 2 ----------
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (_) => pw.Padding(
          padding: const pw.EdgeInsets.all(36),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Executive Summary",
                  style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF0F172A))),
              pw.SizedBox(height: 12),
              pw.Container(
                height: 4,
                width: 90,
                decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFF0EA5E9),
                    borderRadius: pw.BorderRadius.circular(2)),
              ),
              pw.SizedBox(height: 18),
              pw.Text(
                "The proposed $projectName represents a state-of-the-art structural and construction solution designed to maximize performance, safety, and long-term durability.\n\n"
                "This facility encompasses approximately $area sq ft of built-up area and is engineered using modern concrete and steel systems. The overall estimated value of the project is \$${NumberFormat.decimalPattern().format(int.tryParse(cost) ?? 0)}.\n\n"
                "This proposal outlines methodology, planning, schedule, and certification processes to deliver the project within $duration months.",
                style: pw.TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: PdfColor.fromInt(0xFF334155)),
              ),
              pw.SizedBox(height: 18),
              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFF1F5F9),
                  borderRadius: pw.BorderRadius.circular(10),
                  border: pw.Border.all(
                      width: 1, color: PdfColor.fromInt(0xFFE2E8F0)),
                ),
                child: pw.Text(
                  "“This proposal integrates robust construction practices with verified design methodologies, ensuring compliance with applicable standards and building codes.”",
                  style: pw.TextStyle(
                      fontSize: 12,
                      fontStyle: pw.FontStyle.italic,
                      height: 1.5,
                      color: PdfColor.fromInt(0xFF475569)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // ---------- PAGE 3 ----------
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (_) => pw.Padding(
          padding: const pw.EdgeInsets.all(36),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Project Overview",
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 12),
              pw.Container(
                height: 4,
                width: 90,
                decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFF0EA5E9),
                    borderRadius: pw.BorderRadius.circular(2)),
              ),
              pw.SizedBox(height: 14),

              // grid 2x2 cards
              pw.Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _miniInfoCard("Built-Up Area", "$area SQ FT"),
                  _miniInfoCard("Budget",
                      "\$${NumberFormat.decimalPattern().format(int.tryParse(cost) ?? 0)}"),
                  _miniInfoCard("Timeline", "$duration Months"),
                  _miniInfoCard("Location", location),
                ],
              ),
              pw.SizedBox(height: 14),

              imgBox(siteImages.isNotEmpty ? siteImages.first : null,
                  height: 320),

              pw.Spacer(),
              _footer(3),
            ],
          ),
        ),
      ),
    );

    // ---------- PAGE 4 ----------
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (_) => pw.Padding(
          padding: const pw.EdgeInsets.all(36),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Architectural Planning",
                  style: pw.TextStyle(
                      fontSize: 22, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text(
                  "Plans & structural drawings illustrate the integrated design approach.",
                  style: pw.TextStyle(
                      fontSize: 11, color: PdfColor.fromInt(0xFF64748B))),
              pw.SizedBox(height: 14),
              pw.Expanded(
                child: pw.GridView(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  children: [
                    imgBox(planImages.isNotEmpty ? planImages[0] : null),
                    imgBox(planImages.length > 1 ? planImages[1] : null),
                    imgBox(structuralImages.isNotEmpty
                        ? structuralImages[0]
                        : null),
                    imgBox(structuralImages.length > 1
                        ? structuralImages[1]
                        : null),
                  ],
                ),
              ),
              _footer(4),
            ],
          ),
        ),
      ),
    );

    // ---------- PAGE 5 ----------
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (_) => pw.Padding(
          padding: const pw.EdgeInsets.all(36),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Construction Methodology",
                  style: pw.TextStyle(
                      fontSize: 22, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              _bullet(
                "Substructure Phase",
                "Site excavation, soil stabilization and foundation systems with reinforced grid structures.",
              ),
              _bullet(
                "Superstructure Phase",
                "Concrete and steel framing with vertical circulation cores and optimized load distribution.",
              ),
              _bullet(
                "Quality Assurance",
                "Continuous monitoring, third-party inspection, testing and certification protocols.",
              ),
              pw.Spacer(),
              _footer(5),
            ],
          ),
        ),
      ),
    );

    // ---------- PAGE 6 ----------
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (_) => pw.Padding(
          padding: const pw.EdgeInsets.all(36),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Materials & Specifications",
                  style: pw.TextStyle(
                      fontSize: 22, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 12),
              pw.Text(
                "All materials comply with applicable standards and building codes.",
                style: pw.TextStyle(
                    fontSize: 11, color: PdfColor.fromInt(0xFF64748B)),
              ),
              pw.SizedBox(height: 16),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColor.fromInt(0xFFE2E8F0)),
                children: [
                  _row(["Material Component", "Grade / Strength"],
                      header: true),
                  _row(["Foundation Concrete", "4,000 PSI (28-day)"]),
                  _row(["Structural Steel", "ASTM A992 / 50 ksi"]),
                  _row(["Reinforcing Steel", "Grade 60 / 60 ksi"]),
                  _row(["Structural Concrete", "3,500 PSI (28-day)"]),
                ],
              ),
              pw.SizedBox(height: 18),
              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFF1F5F9),
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Text(
                  "Environmental Compliance: All sourced materials meet sustainability and regulatory requirements.",
                  style: pw.TextStyle(
                      fontSize: 11, color: PdfColor.fromInt(0xFF334155)),
                ),
              ),
              pw.Spacer(),
              _footer(6),
            ],
          ),
        ),
      ),
    );

    // ---------- PAGE 7 ----------
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (_) => pw.Padding(
          padding: const pw.EdgeInsets.all(36),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Execution Schedule",
                  style: pw.TextStyle(
                      fontSize: 22, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 14),
              _phaseCard(
                "Phase 1: Site Preparation",
                "Months 1-3",
                "Mobilization, site clearing, excavation, dewatering and foundation initiation.",
              ),
              _phaseCard(
                "Phase 2: Structural Construction",
                "Months 4-16",
                "Concrete & steel framing, floor systems, vertical cores and MEP coordination.",
              ),
              _phaseCard(
                "Phase 3: Closeout & Certification",
                "Months 17-22",
                "Final inspections, QA testing, remediation work, and certification documentation.",
              ),
              pw.Spacer(),
              _footer(7),
            ],
          ),
        ),
      ),
    );

    // ---------- PAGE 8 ----------
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (_) => pw.Padding(
          padding: const pw.EdgeInsets.all(36),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Professional Certification",
                  style: pw.TextStyle(
                      fontSize: 22, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 14),
              pw.Text(
                "This proposal and all technical specifications are prepared and certified by licensed professionals in accordance with applicable standards and regulatory requirements.",
                style: pw.TextStyle(
                    fontSize: 11,
                    height: 1.5,
                    color: PdfColor.fromInt(0x334155)),
              ),
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  borderRadius: pw.BorderRadius.circular(10),
                  color: PdfColor.fromInt(0xFFF1F5F9),
                ),
                child: pw.Text(
                  "The undersigned certifies the adequacy of this proposal as per relevant building codes.",
                  style: pw.TextStyle(fontSize: 11),
                ),
              ),
              pw.Spacer(),
              pw.Center(
                child: pw.Column(children: [
                  pw.SizedBox(height: 24),
                  pw.Container(
                    width: 220,
                    height: 1,
                    color: PdfColor.fromInt(0xFFCBD5E1),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text("Daniel Goff, P.E.",
                      style: pw.TextStyle(
                          fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.Text("Principal Structural Engineer",
                      style: pw.TextStyle(
                          fontSize: 10, color: PdfColor.fromInt(0x64748B))),
                  pw.Text("License #PE-2024-45891",
                      style: pw.TextStyle(
                          fontSize: 9, color: PdfColor.fromInt(0x94A3B8))),
                ]),
              ),
              pw.SizedBox(height: 22),
              _footer(8, last: true),
            ],
          ),
        ),
      ),
    );

    return pdf.save();
  }

  // ✅ open proposal via signed url
  Future<void> _openProposal(String projectId, String token) async {
  final res = await http.get(
    Uri.parse("$baseUrl/docs/$projectId/auto-url?key=proposal_report"),
    headers: {"Authorization": "Bearer $token"},
  );

  final data = jsonDecode(res.body);
  if (res.statusCode >= 400) {
    throw data["message"] ?? "Failed to open proposal";
  }

  final signedUrl = data["url"];
  if (signedUrl == null || signedUrl.toString().isEmpty) {
    throw "Signed URL missing";
  }

  // ✅ OPEN INSIDE APP (NO DOWNLOAD)
  if (!mounted) return;
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PdfPreviewPage(
        title: "Proposal Report",
        pdfUrl: signedUrl.toString(),
      ),
    ),
  );
}


  // ✅ upload proposal → backend -> S3
  Future<void> uploadProposal(String projectId) async {
    final token = await _getToken();

    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Token missing. Login again.")),
      );
      return;
    }

    final companyName = companyCtrl.text.trim();
    final projectName = projectCtrl.text.trim();
    final clientName = clientCtrl.text.trim();

    if (companyName.isEmpty || projectName.isEmpty || clientName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Company, Project, Client required")),
      );
      return;
    }

    final generated = {
      "companyName": companyName,
      "projectName": projectName,
      "clientName": clientName,
      "location": locationCtrl.text.trim(),
      "area": areaCtrl.text.trim(),
      "cost": costCtrl.text.trim(),
      "duration": durationCtrl.text.trim(),
      "type": typeCtrl.text.trim(),
      "proposalNumber":
          "CP-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch % 1000}",
      "date": DateFormat("dd/MM/yyyy").format(DateTime.now()),
    };

    setState(() => uploading = true);

    try {
      final pdfBytes = await _buildProposalPdf(generated);

      final req = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/docs/$projectId/generate"),
      );

      req.headers["Authorization"] = "Bearer $token";
      req.fields["key"] = "proposal_report";

      req.files.add(
        http.MultipartFile.fromBytes(
          "pdf",
          pdfBytes,
          filename: "proposal_${DateTime.now().millisecondsSinceEpoch}.pdf",
          contentType: MediaType("application", "pdf"),
        ),
      );

      final streamed = await req.send();
      final body = await streamed.stream.bytesToString();

      if (streamed.statusCode >= 400) {
        throw body;
      }

      // ✅ refresh doc state
      await fetchDoc(projectId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Proposal uploaded to S3")),
      );

      await _openProposal(projectId, token);

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
    } finally {
      setState(() => uploading = false);
    }
  }

  // ----------------- UI -----------------
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final projectId = (args?["projectId"] ?? "").toString();

    if (projectId.isNotEmpty && loadingDoc) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        fetchDoc(projectId);
      });
    }

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text("Proposal Report"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _card(
              title: "Proposal Metadata",
              child: Column(
                children: [
                  _inputCtrl("Company Name", companyCtrl),
                  _inputCtrl("Project Name", projectCtrl),
                  _inputCtrl("Client Name", clientCtrl),
                  _inputCtrl("Location", locationCtrl),
                  Row(
                    children: [
                      Expanded(
                          child: _inputCtrl("Built-up Area (sq ft)", areaCtrl)),
                      const SizedBox(width: 10),
                      Expanded(child: _inputCtrl("Budget", costCtrl)),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                          child: _inputCtrl("Duration (months)", durationCtrl)),
                      const SizedBox(width: 10),
                      Expanded(child: _inputCtrl("Type", typeCtrl)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _card(
              title: "Media Vault",
              child: Column(
                children: [
                  _uploadRow(
                    title: "Site Photos",
                    count: siteImages.length,
                    images: siteImages,
                    onPick: () => pickImages("site"),
                    onClear: () => clearImages("site"),
                  ),
                  const Divider(height: 22),
                  _uploadRow(
                    title: "2D Plans",
                    count: planImages.length,
                    images: planImages,
                    onPick: () => pickImages("plans"),
                    onClear: () => clearImages("plans"),
                  ),
                  const Divider(height: 22),
                  _uploadRow(
                    title: "Structural",
                    count: structuralImages.length,
                    images: structuralImages,
                    onPick: () => pickImages("structural"),
                    onClear: () => clearImages("structural"),
                  ),
                  const Divider(height: 22),
                  _uploadRow(
                    title: "3D Renders",
                    count: renderImages.length,
                    images: renderImages,
                    onPick: () => pickImages("renders"),
                    onClear: () => clearImages("renders"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (loadingDoc) ...[
              const SizedBox(height: 18),
              const CircularProgressIndicator(),
            ] else if (docErr.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text("Error: $docErr"),
            ] else ...[
              if ((doc?["uploaded"] ?? false) == true) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: uploading
                            ? null
                            : () async {
                                final token = await _getToken();
                                await _openProposal(projectId, token);
                              },
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text("Preview"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            uploading ? null : () => uploadProposal(projectId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(uploading ? "Uploading..." : "Regenerate"),
                      ),
                    ),
                  ],
                )
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        uploading ? null : () => uploadProposal(projectId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      uploading ? "Uploading..." : "Generate + Upload Proposal",
                    ),
                  ),
                )
              ],
            ],
          ],
        ),
      ),
    );
  }

  // ---------------- helpers ----------------
  Widget _card({required String title, required Widget child}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          child,
        ]),
      ),
    );
  }

  Widget _inputCtrl(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _uploadRow({
    required String title,
    required int count,
    required VoidCallback onPick,
    required VoidCallback onClear,
    required List<Uint8List> images,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                "$title ($count)",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            OutlinedButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.photo_library),
              label: const Text("Gallery"),
            ),
            const SizedBox(width: 10),
            IconButton(
              onPressed: count == 0 ? null : onClear,
              icon: const Icon(Icons.delete, color: Colors.red),
            ),
          ],
        ),
        if (images.isNotEmpty) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 70,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length > 6 ? 6 : images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) => ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(
                  images[i],
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // PDF helper widgets
  static pw.Widget _miniInfoCard(String label, String value) {
    return pw.Container(
      width: 240,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColor.fromInt(0xFFE2E8F0)),
        color: PdfColor.fromInt(0xFFF8FAFC),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF64748B))),
          pw.SizedBox(height: 6),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF0F172A))),
        ],
      ),
    );
  }

  static pw.Widget _bullet(String title, String body) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(10),
        color: PdfColor.fromInt(0xFFF1F5F9),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title,
              style:
                  pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(body,
              style: pw.TextStyle(
                  fontSize: 10,
                  height: 1.4,
                  color: PdfColor.fromInt(0xFF334155))),
        ],
      ),
    );
  }

  static pw.Widget _phaseCard(String title, String time, String desc) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColor.fromInt(0xFFE2E8F0)),
        color: PdfColor.fromInt(0xFFFFFFFF),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title,
              style:
                  pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 2),
          pw.Text(time,
              style: pw.TextStyle(
                  fontSize: 10, color: PdfColor.fromInt(0xFF0EA5E9))),
          pw.SizedBox(height: 6),
          pw.Text(desc,
              style: pw.TextStyle(
                  fontSize: 10,
                  height: 1.4,
                  color: PdfColor.fromInt(0xFF334155))),
        ],
      ),
    );
  }

  static pw.TableRow _row(List<String> cells, {bool header = false}) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(
        color: header ? PdfColor.fromInt(0xFFF1F5F9) : null,
      ),
      children: cells
          .map(
            (t) => pw.Padding(
              padding: const pw.EdgeInsets.all(10),
              child: pw.Text(
                t,
                style: pw.TextStyle(
                  fontSize: header ? 10 : 10,
                  fontWeight:
                      header ? pw.FontWeight.bold : pw.FontWeight.normal,
                  color: PdfColor.fromInt(0xFF0F172A),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  static pw.Widget _footer(int page, {bool last = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text("CONSTRUCTPRO © 2026",
              style: pw.TextStyle(
                  fontSize: 9, color: PdfColor.fromInt(0xFF94A3B8))),
          pw.Text(last ? "Page 8 of 8 (End)" : "Page $page of 8",
              style: pw.TextStyle(
                  fontSize: 9, color: PdfColor.fromInt(0xFF94A3B8))),
        ],
      ),
    );
  }

  @override
  void dispose() {
    companyCtrl.dispose();
    projectCtrl.dispose();
    clientCtrl.dispose();
    locationCtrl.dispose();
    areaCtrl.dispose();
    costCtrl.dispose();
    durationCtrl.dispose();
    typeCtrl.dispose();
    super.dispose();
  }
}
