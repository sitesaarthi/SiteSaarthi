import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';

// ✅ Your in-app PDF preview page (same used in quotation/proposal)
import 'pdf_preview_page.dart'; // <-- update path

class GstInvoicePage extends StatefulWidget {
  const GstInvoicePage({super.key});

  @override
  State<GstInvoicePage> createState() => _GstInvoicePageState();
}

class _GstInvoicePageState extends State<GstInvoicePage> {
  static const String baseUrl = "http://10.0.2.2:5000/api";

  bool uploading = false;
  bool invoiceGenerated = false;

  // ✅ GST invoice form
  Map<String, dynamic> gstInvoiceData = {
    "companyName": "ConstructPro Private Limited",
    "companyGSTIN": "29ABCDE1234F1Z5",
    "companyAddress": "123, MG Road, Bengaluru, Karnataka - 560001",
    "clientName": "",
    "clientGSTIN": "",
    "clientAddress": "",
    "invoiceNumber":
        "GST-${DateTime.now().year}-${100 + (DateTime.now().millisecond % 900)}",
    "invoiceDate": DateFormat('yyyy-MM-dd').format(DateTime.now()),
    "hsnCode": "9954",
    "placeOfSupply": "Karnataka",
  };

  // ✅ invoice items
  final List<Map<String, dynamic>> items = [
    {
      "description": "PATCH WORK EXTERNAL CEMENT PLASTER",
      "unit": "Sft",
      "area": 100,
      "rate": 90,
      "amount": 9000,
    }
  ];

  // ✅ backend history list
  List<Map<String, dynamic>> gstInvoices = [];
  bool loadingHistory = true;
  String historyErr = "";

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("authToken") ?? "";
  }

  double get subtotal =>
      items.fold(0.0, (sum, i) => sum + ((i["amount"] ?? 0) as num).toDouble());

  double get gstAmount => gstInvoiceData["placeOfSupply"] == "Karnataka"
      ? subtotal * 0.18
      : subtotal * 0.18;

  double get total => subtotal + gstAmount;

  // ✅ validate invoice fields
  void generateInvoice() {
    if ((gstInvoiceData["clientName"] ?? "").toString().trim().isEmpty ||
        (gstInvoiceData["clientGSTIN"] ?? "").toString().trim().isEmpty ||
        (gstInvoiceData["clientAddress"] ?? "").toString().trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required client details")),
      );
      return;
    }

    setState(() {
      invoiceGenerated = true;
    });
  }

  // ✅ Build GST PDF
  Future<Uint8List> _buildGstPdf() async {
    final pdf = pw.Document();

    final isKarnataka = gstInvoiceData["placeOfSupply"] == "Karnataka";
    final invNo = gstInvoiceData["invoiceNumber"];
    final invDate = gstInvoiceData["invoiceDate"];
    final hsn = gstInvoiceData["hsnCode"];

    pdf.addPage(
      pw.MultiPage(
        build: (_) => [
          pw.Center(
            child: pw.Text(
              "TAX INVOICE",
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 20),

          // ✅ COMPANY
          pw.Text(gstInvoiceData["companyName"],
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text("GSTIN: ${gstInvoiceData["companyGSTIN"]}"),
          pw.Text(gstInvoiceData["companyAddress"]),
          pw.SizedBox(height: 10),

          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("Invoice No: $invNo"),
              pw.Text("Date: $invDate"),
            ],
          ),

          pw.SizedBox(height: 20),

          // ✅ CLIENT
          pw.Text("Bill To:",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(gstInvoiceData["clientName"]),
          pw.Text("GSTIN: ${gstInvoiceData["clientGSTIN"]}"),
          pw.Text(gstInvoiceData["clientAddress"]),

          pw.SizedBox(height: 20),

          // ✅ TABLE
          pw.Table.fromTextArray(
            headers: ["S.No", "Description", "HSN", "Unit", "Qty", "Rate", "Amount"],
            data: List.generate(items.length, (i) {
              final item = items[i];
              return [
                i + 1,
                item["description"],
                hsn,
                item["unit"],
                item["area"],
                "₹${item["rate"]}",
                "₹${NumberFormat.decimalPattern('en_IN').format(item["amount"])}",
              ];
            }),
          ),

          pw.SizedBox(height: 20),

          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                    "Subtotal: ₹${NumberFormat.decimalPattern('en_IN').format(subtotal)}"),
                if (isKarnataka) ...[
                  pw.Text(
                      "CGST (9%): ₹${NumberFormat.decimalPattern('en_IN').format(subtotal * 0.09)}"),
                  pw.Text(
                      "SGST (9%): ₹${NumberFormat.decimalPattern('en_IN').format(subtotal * 0.09)}"),
                ] else
                  pw.Text(
                      "IGST (18%): ₹${NumberFormat.decimalPattern('en_IN').format(subtotal * 0.18)}"),
                pw.Text(
                  "Total: ₹${NumberFormat.decimalPattern('en_IN').format(total)}",
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

  // ✅ Upload GST to backend
  Future<void> uploadGstInvoice(String projectId) async {
    final token = await _getToken();
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Token missing. Login again.")),
      );
      return;
    }

    if (!invoiceGenerated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("First Generate GST Invoice")),
      );
      return;
    }

    setState(() => uploading = true);

    try {
      final pdfBytes = await _buildGstPdf();

      final req = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/doc-history/$projectId/gst-invoices"),
      );

      req.headers["Authorization"] = "Bearer $token";

      req.fields["invoiceNumber"] = gstInvoiceData["invoiceNumber"].toString();
      req.fields["clientName"] = gstInvoiceData["clientName"].toString();
      req.fields["clientGSTIN"] = gstInvoiceData["clientGSTIN"].toString();
      req.fields["placeOfSupply"] = (gstInvoiceData["placeOfSupply"] == "Karnataka")
          ? "Karnataka"
          : "Other";
      req.fields["totalAmount"] = total.toStringAsFixed(2);

      req.files.add(
        http.MultipartFile.fromBytes(
          "pdf",
          pdfBytes,
          filename: "gst_${DateTime.now().millisecondsSinceEpoch}.pdf",
          contentType: MediaType("application", "pdf"),
        ),
      );

      final streamed = await req.send();
      final body = await streamed.stream.bytesToString();

      if (streamed.statusCode >= 400) {
        throw body;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ GST Invoice uploaded to S3")),
      );

      await fetchGstInvoices(projectId);

      // ✅ open preview of newly created GST
      final decoded = jsonDecode(body);
      final gst = decoded["gst"];
      if (gst != null && gst["_id"] != null) {
        await openGstPreview(gst["_id"].toString(), token);
      }

      _resetForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
    } finally {
      setState(() => uploading = false);
    }
  }

  void _resetForm() {
    setState(() {
      invoiceGenerated = false;
      gstInvoiceData["clientName"] = "";
      gstInvoiceData["clientGSTIN"] = "";
      gstInvoiceData["clientAddress"] = "";
      gstInvoiceData["invoiceNumber"] =
          "GST-${DateTime.now().year}-${100 + (DateTime.now().millisecond % 900)}";
      gstInvoiceData["invoiceDate"] = DateFormat('yyyy-MM-dd').format(DateTime.now());
      gstInvoiceData["placeOfSupply"] = "Karnataka";
    });
  }

  // ✅ fetch GST invoice history
  Future<void> fetchGstInvoices(String projectId) async {
    final token = await _getToken();
    if (token.isEmpty) return;

    try {
      setState(() {
        loadingHistory = true;
        historyErr = "";
      });

      final res = await http.get(
        Uri.parse("$baseUrl/doc-history/$projectId/gst-invoices"),
        headers: {"Authorization": "Bearer $token"},
      );

      final data = jsonDecode(res.body);

      if (res.statusCode >= 400) {
        throw data["message"] ?? "Failed to load GST history";
      }

      setState(() {
        gstInvoices = (data["gstInvoices"] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        loadingHistory = false;
      });
    } catch (e) {
      setState(() {
        loadingHistory = false;
        historyErr = e.toString();
      });
    }
  }

  // ✅ open GST preview in app
  Future<void> openGstPreview(String gstId, String token) async {
    final res = await http.get(
      Uri.parse("$baseUrl/doc-history/gst-invoices/$gstId/url"),
      headers: {"Authorization": "Bearer $token"},
    );

    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) throw (data["message"] ?? "Failed to open GST");

    final signedUrl = data["url"];
    if (signedUrl == null || signedUrl.toString().isEmpty) {
      throw "Signed URL missing";
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfPreviewPage(
          title: "GST Invoice",
          pdfUrl: signedUrl.toString(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final projectId = (args?["projectId"] ?? "").toString();

    // load history once
    if (projectId.isNotEmpty && loadingHistory) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        fetchGstInvoices(projectId);
      });
    }

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text("GST Invoice"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _card(
              title: "Create GST Invoice",
              child: Column(
                children: [
                  _readonly("Invoice Number", gstInvoiceData["invoiceNumber"]),
                  _readonly("Invoice Date", gstInvoiceData["invoiceDate"]),
                  const Divider(),

                  _infoBlock("Company Details", [
                    gstInvoiceData["companyName"],
                    gstInvoiceData["companyGSTIN"],
                    gstInvoiceData["companyAddress"],
                  ]),

                  _input("Client Name *", (v) => gstInvoiceData["clientName"] = v),
                  _input("Client GSTIN *", (v) => gstInvoiceData["clientGSTIN"] = v),
                  _input("Client Address *", (v) => gstInvoiceData["clientAddress"] = v),

                  DropdownButtonFormField<String>(
                    value: gstInvoiceData["placeOfSupply"],
                    decoration: const InputDecoration(labelText: "Place of Supply"),
                    items: const [
                      DropdownMenuItem(
                        value: "Karnataka",
                        child: Text("Karnataka (CGST + SGST)"),
                      ),
                      DropdownMenuItem(
                        value: "Other",
                        child: Text("Other State (IGST)"),
                      ),
                    ],
                    onChanged: (v) => setState(() => gstInvoiceData["placeOfSupply"] = v),
                  ),

                  const Divider(height: 30),

                  ...items.map((item) => ListTile(
                        title: Text("${item["description"] ?? ""}"),
                        subtitle: Text(
                          "HSN ${gstInvoiceData["hsnCode"]} | ${item["area"] ?? 0} ${item["unit"] ?? ""} × ₹${item["rate"] ?? 0}",
                        ),
                        trailing: Text(
                          "₹${NumberFormat.decimalPattern('en_IN').format((item["amount"] as num).toDouble())}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      )),

                  const Divider(),

                  _totalRow("Subtotal", subtotal),
                  if (gstInvoiceData["placeOfSupply"] == "Karnataka") ...[
                    _totalRow("CGST (9%)", subtotal * 0.09),
                    _totalRow("SGST (9%)", subtotal * 0.09),
                  ] else
                    _totalRow("IGST (18%)", subtotal * 0.18),
                  _totalRow("Total", total, bold: true),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: uploading ? null : generateInvoice,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    child: Text(uploading ? "Working..." : "Generate GST Invoice"),
                  ),
                ),
                const SizedBox(width: 12),
                if (invoiceGenerated)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: uploading || projectId.isEmpty
                          ? null
                          : () => uploadGstInvoice(projectId),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: Text(uploading ? "Uploading..." : "Upload + Preview"),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // ✅ HISTORY
            _card(
              title: "GST Invoice History",
              child: Column(
                children: [
                  if (loadingHistory) const CircularProgressIndicator(),
                  if (!loadingHistory && historyErr.isNotEmpty)
                    Text("Error: $historyErr"),
                  if (!loadingHistory && historyErr.isEmpty && gstInvoices.isEmpty)
                    const Text("No GST invoices yet."),
                  if (!loadingHistory && gstInvoices.isNotEmpty)
                    ListView.builder(
                      itemCount: gstInvoices.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (_, i) {
                        final gst = gstInvoices[i];

                        final gstId = (gst["_id"] ?? "").toString();
                        final invNo = (gst["invoiceNumber"] ?? "").toString();
                        final client = (gst["clientName"] ?? "").toString();
                        final amount = gst["totalAmount"] ?? 0;

                        final createdAt = gst["createdAt"]?.toString();
                        String date = "";
                        try {
                          if (createdAt != null) {
                            date =
                                DateFormat("dd MMM yyyy").format(DateTime.parse(createdAt));
                          }
                        } catch (_) {}

                        return Card(
                          child: ListTile(
                            title: Text(invNo.isEmpty ? "GST Invoice" : invNo),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(client),
                                if (date.isNotEmpty)
                                  Text(date, style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                            trailing: Text(
                              "₹${NumberFormat.decimalPattern('en_IN').format(amount)}",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onTap: () async {
                              final token = await _getToken();
                              await openGstPreview(gstId, token);
                            },
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ---------------- HELPERS ----------------

  Widget _card({required String title, required Widget child}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          child,
        ]),
      ),
    );
  }

  Widget _readonly(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        readOnly: true,
        decoration: InputDecoration(labelText: label),
        controller: TextEditingController(text: value),
      ),
    );
  }

  Widget _input(String label, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        decoration: InputDecoration(labelText: label),
        onChanged: onChanged,
      ),
    );
  }

  Widget _infoBlock(String title, List<String> lines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        ...lines.map((l) => Text(l)).toList(),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _totalRow(String label, double value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : null)),
        Text(
          "₹${NumberFormat.decimalPattern('en_IN').format(value)}",
          style: TextStyle(fontWeight: bold ? FontWeight.bold : null),
        ),
      ],
    );
  }
}
