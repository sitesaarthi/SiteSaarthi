import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'pdf_preview_page.dart'; 

class QuotationPage extends StatefulWidget {
  const QuotationPage({super.key});

  @override
  State<QuotationPage> createState() => _QuotationPageState();
}

class _QuotationPageState extends State<QuotationPage> {
  static const String baseUrl = "http://10.0.2.2:5000/api";

  bool uploading = false;

  // ✅ doc from backend
  Map<String, dynamic>? doc;
  bool loadingDoc = true;
  String docErr = "";

  // ✅ editable fields
  final TextEditingController companyCtrl =
      TextEditingController(text: "ConstructPro Private Limited");
  final TextEditingController projectCtrl =
      TextEditingController(text: "Residential Complex A");
  final TextEditingController clientCtrl =
      TextEditingController(text: "Abhilasa Tower");

  Map<String, dynamic> quotationData = {
    "items": [
      {
        "id": 1,
        "description": "PATCH WORK EXTERNAL CEMENT PLASTER",
        "fullDescription": "Cement plaster work with Dr. Fixit Pidiproof",
        "unit": "Sft",
        "area": 100.0,
        "rate": 90.0,
        "amount": 9000.0,
      }
    ],
    "gst": 18.0,
  };

  double get subtotal => (quotationData["items"] as List)
      .fold(0.0, (s, i) => s + ((i["amount"] ?? 0) as num).toDouble());

  double get total =>
      subtotal + (subtotal * ((quotationData["gst"] ?? 0) as num).toDouble() / 100);

  // ✅ token
  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("authToken") ?? "";
  }

  // ✅ fetch doc status
  Future<void> fetchDoc(String projectId) async {
    final token = await _getToken();
    if (token.isEmpty) return;

    try {
      setState(() {
        loadingDoc = true;
        docErr = "";
      });

      final res = await http.get(
        Uri.parse("$baseUrl/docs/$projectId/single?key=quotation"),
        headers: {"Authorization": "Bearer $token"},
      );

      final data = jsonDecode(res.body);
      if (res.statusCode >= 400) throw (data["message"] ?? "Failed to load doc");

      setState(() {
        doc = (data["doc"] is Map) ? Map<String, dynamic>.from(data["doc"]) : null;
        loadingDoc = false;
      });
    } catch (e) {
      setState(() {
        loadingDoc = false;
        docErr = e.toString();
      });
    }
  }

  // ✅ add item
  void addItem() {
    setState(() {
      quotationData["items"].add({
        "id": DateTime.now().millisecondsSinceEpoch,
        "description": "",
        "fullDescription": "",
        "unit": "Sft",
        "area": 0.0,
        "rate": 0.0,
        "amount": 0.0,
      });
    });
  }

  // ✅ update item
  void updateItem(Map<String, dynamic> item, String key, dynamic value) {
    setState(() {
      item[key] = value;

      final area = (item["area"] ?? 0) as num;
      final rate = (item["rate"] ?? 0) as num;
      item["amount"] = area.toDouble() * rate.toDouble();
    });
  }

  void deleteItem(int id) {
    setState(() {
      quotationData["items"].removeWhere((e) => e["id"] == id);
    });
  }

  // ✅ PDF builder
  Future<Uint8List> _buildQuotationPdf(Map<String, dynamic> q) async {
    final pdf = pw.Document();

    final items = (q["items"] as List?) ?? [];
    final gst = (q["gst"] as num?)?.toDouble() ?? 0;

    final sub = items.fold<double>(0.0, (sum, item) {
      final amt = (item["amount"] as num?) ?? 0;
      return sum + amt.toDouble();
    });

    final tot = sub + (sub * gst / 100);

    pdf.addPage(
      pw.MultiPage(
        build: (_) => [
          pw.Center(
            child: pw.Text(
              "QUOTATION",
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 12),

          pw.Text("Company: ${q["companyName"]}", style: const pw.TextStyle(fontSize: 11)),
          pw.Text("Quotation No: ${q["quotationNumber"]}", style: const pw.TextStyle(fontSize: 11)),
          pw.Text("Date: ${q["date"]}", style: const pw.TextStyle(fontSize: 11)),

          pw.SizedBox(height: 10),
          pw.Text("Project: ${q["projectName"]}", style: const pw.TextStyle(fontSize: 11)),
          pw.Text("Client: ${q["clientName"]}", style: const pw.TextStyle(fontSize: 11)),

          pw.SizedBox(height: 14),

          pw.Table.fromTextArray(
            headers: ["S.No", "Description", "Unit", "Qty", "Rate", "Amount"],
            data: List.generate(items.length, (i) {
              final item = items[i];
              return [
                i + 1,
                item["description"],
                item["unit"],
                item["area"],
                "₹${item["rate"]}",
                "₹${NumberFormat("#,##0.##").format(item["amount"])}",
              ];
            }),
          ),

          pw.SizedBox(height: 16),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text("Subtotal: ₹${sub.toStringAsFixed(0)}"),
                pw.Text("GST ($gst%): ₹${(sub * gst / 100).toStringAsFixed(0)}"),
                pw.Text(
                  "Total: ₹${tot.toStringAsFixed(0)}",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // ✅ Preview quotation via signed url (AUTO)
  Future<void> _openQuotation(String projectId, String token) async {
  final res = await http.get(
    Uri.parse("$baseUrl/docs/$projectId/auto-url?key=quotation"),
    headers: {"Authorization": "Bearer $token"},
  );

  final data = jsonDecode(res.body);
  if (res.statusCode >= 400) throw (data["message"] ?? "Failed to open");

  final signedUrl = data["url"];
  if (signedUrl == null || signedUrl.toString().isEmpty) {
    throw "Signed URL missing";
  }

  // ✅ OPEN INSIDE APP (not chrome)
  if (!mounted) return;
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PdfPreviewPage(
        title: "Quotation",
        pdfUrl: signedUrl.toString(),
      ),
    ),
  );
}


  // ✅ Upload quotation
  Future<void> uploadQuotation(String projectId) async {
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

    // ✅ no intl locale crash here
    final now = DateTime.now();
    final formattedDate =
        "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";

    final generated = {
      ...quotationData,
      "companyName": companyName,
      "projectName": projectName,
      "clientName": clientName,
      "quotationNumber": "QT-${now.year}-${100 + (now.millisecond % 900)}",
      "date": formattedDate,
    };

    setState(() => uploading = true);

    try {
      final pdfBytes = await _buildQuotationPdf(generated);

      final req = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/docs/$projectId/generate"),
      );

      req.headers["Authorization"] = "Bearer $token";
      req.fields["key"] = "quotation";

      req.files.add(
        http.MultipartFile.fromBytes(
          "pdf",
          pdfBytes,
          filename: "quotation_${DateTime.now().millisecondsSinceEpoch}.pdf",
          contentType: MediaType("application", "pdf"),
        ),
      );

      final streamed = await req.send();
      final body = await streamed.stream.bytesToString();

      if (streamed.statusCode >= 400) {
        throw body;
      }

      // ✅ VERY IMPORTANT: update doc instantly so preview appears (like RERA)
      final decoded = jsonDecode(body);
      setState(() {
        doc = (decoded["doc"] is Map) ? Map<String, dynamic>.from(decoded["doc"]) : doc;
        loadingDoc = false;
        docErr = "";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Quotation uploaded to S3")),
      );

      // ✅ open preview
      await _openQuotation(projectId, token);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
    } finally {
      setState(() => uploading = false);
    }
  }

  // UI
  Widget _card({required String title, required Widget child}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
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

  Widget _numberField(String label, dynamic value, Function(String) onChange) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: label),
          onChanged: onChange,
        ),
      ),
    );
  }

  Widget _totalRow(String label, double value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : null)),
        Text("₹${NumberFormat("#,##0.##").format(value)}",
            style: TextStyle(fontWeight: bold ? FontWeight.bold : null)),
      ],
    );
  }

  Widget _itemCard(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(labelText: "Item Description"),
              onChanged: (v) => updateItem(item, "description", v),
            ),
            const SizedBox(height: 6),
            TextField(
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Full Description"),
              onChanged: (v) => updateItem(item, "fullDescription", v),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _numberField("Unit", item["unit"],
                    (v) => updateItem(item, "unit", v)),
                _numberField("Qty", item["area"],
                    (v) => updateItem(item, "area", double.tryParse(v) ?? 0)),
                _numberField("Rate", item["rate"],
                    (v) => updateItem(item, "rate", double.tryParse(v) ?? 0)),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: () => deleteItem(item["id"]),
                icon: const Icon(Icons.delete, color: Colors.red),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    companyCtrl.dispose();
    projectCtrl.dispose();
    clientCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final projectId = (args?["projectId"] ?? "").toString();

    if (projectId.isNotEmpty && loadingDoc) {
      WidgetsBinding.instance.addPostFrameCallback((_) => fetchDoc(projectId));
    }

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text("Quotation"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _card(
              title: "Quotation Details",
              child: Column(
                children: [
                  _inputCtrl("Company Name", companyCtrl),
                  _inputCtrl("Project Name", projectCtrl),
                  _inputCtrl("Client Name", clientCtrl),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _card(
              title: "Items",
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Line Items",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      ElevatedButton.icon(
                        onPressed: addItem,
                        icon: const Icon(Icons.add),
                        label: const Text("Add Item"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...quotationData["items"].map<Widget>((item) {
                    return _itemCard(item);
                  }).toList(),
                  const Divider(height: 32),
                  _totalRow("Subtotal", subtotal),
                  _totalRow(
                    "GST (${quotationData["gst"]}%)",
                    subtotal * ((quotationData["gst"] ?? 0) as num).toDouble() / 100,
                  ),
                  _totalRow("Total", total, bold: true),
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
                                await _openQuotation(projectId, token);
                              },
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text("Preview"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: uploading ? null : () => uploadQuotation(projectId),
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
                    onPressed: uploading ? null : () => uploadQuotation(projectId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(uploading
                        ? "Uploading..."
                        : "Generate + Upload Quotation"),
                  ),
                )
              ],
            ],
          ],
        ),
      ),
    );
  }
}
