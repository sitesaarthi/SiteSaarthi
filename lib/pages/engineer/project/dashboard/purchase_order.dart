import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../owner/docs/pdf_preview_page.dart'; // update path if needed

class EngineerCreatePoPage extends StatefulWidget {
  const EngineerCreatePoPage({super.key});

  @override
  State<EngineerCreatePoPage> createState() => _EngineerCreatePoPageState();
}

class _EngineerCreatePoPageState extends State<EngineerCreatePoPage>
    with SingleTickerProviderStateMixin {
  static const String baseUrl = "http://10.0.2.2:5000/api";

  late TabController tabController;

  bool uploading = false;
  bool poReady = false;
  bool _historyLoaded = false;

  Map<String, dynamic> poData = {
    "vendor": "",
    "poNumber":
        "PO-${DateTime.now().year}-${100 + (DateTime.now().millisecond % 900)}",
    "issueDate": DateFormat("yyyy-MM-dd").format(DateTime.now()),
    "deliveryDate": "",
    "items": [],
    "totalAmount": 0,
    "status": "pending",
  };

  List<Map<String, dynamic>> history = [];
  bool loadingHistory = true;
  String historyErr = "";

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
  }

  Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("authToken") ?? "";
  }

  /// ---------------- PDF ----------------
  Future<Uint8List> _buildPoPdf() async {
    final pdf = pw.Document();
    final items = poData["items"] as List;

    pdf.addPage(
      pw.MultiPage(
        build: (_) => [
          pw.Center(
            child: pw.Text(
              "PURCHASE ORDER",
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Text("PO Number: ${poData["poNumber"]}"),
          pw.Text("Issue Date: ${poData["issueDate"]}"),
          pw.Text("Delivery Date: ${poData["deliveryDate"]}"),
          pw.SizedBox(height: 12),
          pw.Text("Vendor: ${poData["vendor"]}"),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: ["#", "Description", "Unit", "Qty", "Rate", "Amount"],
            data: List.generate(items.length, (i) {
              final it = items[i];
              return [
                i + 1,
                it["description"],
                it["unit"],
                it["qty"],
                "Rs${it["rate"]}",
                "Rs${NumberFormat.decimalPattern('en_IN').format(it["amount"])}",
              ];
            }),
          ),
          pw.SizedBox(height: 16),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              "Total: Rs${NumberFormat.decimalPattern('en_IN').format(poData["totalAmount"])}",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text("Status: PENDING OWNER APPROVAL"),
        ],
      ),
    );

    return pdf.save();
  }

  /// ---------------- CREATE ----------------
  void generatePO() {
    if (poData["vendor"].toString().trim().isEmpty ||
        poData["deliveryDate"].toString().trim().isEmpty ||
        (poData["items"] as List).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all required fields")),
      );
      return;
    }

    setState(() {
      poReady = true;
      poData["status"] = "pending";
    });
  }

  /// ---------------- UPLOAD ----------------
  Future<void> uploadPo(String projectId) async {
    final token = await _token();
    if (token.isEmpty || !poReady) return;

    setState(() => uploading = true);

    try {
      final pdfBytes = await _buildPoPdf();

      final req = http.MultipartRequest(
  "POST",
  Uri.parse("$baseUrl/doc-history/$projectId/purchase-orders"),
);


      req.headers["Authorization"] = "Bearer $token";
      req.fields["poNumber"] = poData["poNumber"];
      req.fields["vendor"] = poData["vendor"];
      req.fields["issueDate"] = poData["issueDate"];
      req.fields["deliveryDate"] = poData["deliveryDate"];
      req.fields["totalAmount"] = poData["totalAmount"].toString();

      req.files.add(
        http.MultipartFile.fromBytes(
          "pdf",
          pdfBytes,
          filename: "po_${DateTime.now().millisecondsSinceEpoch}.pdf",
          contentType: MediaType("application", "pdf"),
        ),
      );

      final res = await req.send();
      final body = await res.stream.bytesToString();
      if (res.statusCode >= 400) throw body;

      final data = jsonDecode(body);


      final poId = data["po"]["_id"];

// 🔥 SUBMIT PO FOR OWNER APPROVAL
final submitRes = await http.patch(
  Uri.parse("$baseUrl/doc-history/purchase-orders/$poId/submit"),
  headers: {
    "Authorization": "Bearer $token",
    "Content-Type": "application/json",
  },
);


if (submitRes.statusCode >= 400) {
  throw "Failed to submit PO for approval";
}

      await fetchHistory(projectId);

      await openPreview(data["po"]["_id"], token);
      _reset();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => uploading = false);
    }
  }

  void _reset() {
    setState(() {
      poReady = false;
      poData["vendor"] = "";
      poData["deliveryDate"] = "";
      poData["items"] = [];
      poData["totalAmount"] = 0;
    });
  }

  /// ---------------- HISTORY ----------------
  Future<void> fetchHistory(String projectId) async {
    final token = await _token();
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/doc-history/$projectId/purchase-orders"),
        headers: {"Authorization": "Bearer $token"},
      );

      final data = jsonDecode(res.body);
      if (res.statusCode >= 400) throw data["message"];

      setState(() {
        history = (data["purchaseOrders"] as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        loadingHistory = false;
      });
    } catch (e) {
      setState(() {
        historyErr = e.toString();
        loadingHistory = false;
      });
    }
  }

  Future<void> openPreview(String poId, String token) async {
    final res = await http.get(
      Uri.parse("$baseUrl/doc-history/purchase-orders/$poId/url"),
      headers: {"Authorization": "Bearer $token"},
    );

    final data = jsonDecode(res.body);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfPreviewPage(
          title: "Purchase Order",
          pdfUrl: data["url"],
        ),
      ),
    );
  }

  /// ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final projectId = args?["projectId"] ?? "";

    if (!_historyLoaded && projectId.isNotEmpty) {
      _historyLoaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        fetchHistory(projectId);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Purchase Orders"),
        bottom: TabBar(
          controller: tabController,
          tabs: const [
            Tab(text: "Create PO"),
            Tab(text: "History"),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          _createTab(projectId),
          _historyTab(),
        ],
      ),
    );
  }

  Widget _createTab(String projectId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        _field("PO Number", poData["poNumber"], readOnly: true),
        _field("Vendor *", poData["vendor"],
            onChanged: (v) => poData["vendor"] = v),
        _field("Issue Date", poData["issueDate"], readOnly: true),
        _field("Delivery Date *", poData["deliveryDate"],
            onChanged: (v) => poData["deliveryDate"] = v),
        const Divider(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Items",
                style: TextStyle(fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.green),
              onPressed: _addItemSheet,
            )
          ],
        ),
        ...((poData["items"] as List).map(_itemTile)),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            "Total: Rs${NumberFormat.decimalPattern('en_IN').format(poData["totalAmount"])}",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: generatePO,
                child: const Text("Generate PO"),
              ),
            ),
            const SizedBox(width: 12),
            if (poReady)
              Expanded(
                child: OutlinedButton(
                  onPressed: uploading ? null : () => uploadPo(projectId),
                  child: const Text("Upload + Preview"),
                ),
              ),
          ],
        ),
      ]),
    );
  }

  Widget _historyTab() {
    if (loadingHistory) return const Center(child: CircularProgressIndicator());
    if (history.isEmpty) return const Center(child: Text("No POs yet"));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (_, i) {
        final po = history[i];
        return Card(
          child: ListTile(
            title: Text(po["poNumber"]),
            subtitle: Text(po["vendor"]),
            trailing: Chip(
              label: Text(po["status"].toUpperCase()),
            ),
            onTap: () async {
              final t = await _token();
              openPreview(po["_id"], t);
            },
          ),
        );
      },
    );
  }

  Widget _field(String label, dynamic value,
      {bool readOnly = false, Function(String)? onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: value?.toString(),
        readOnly: readOnly,
        decoration: InputDecoration(labelText: label),
        onChanged: onChanged,
      ),
    );
  }

  Widget _itemTile(dynamic it) {
    return ListTile(
      title: Text(it["description"]),
      subtitle: Text("${it["qty"]} ${it["unit"]} × Rs${it["rate"]}"),
      trailing: Text("Rs${it["amount"]}"),
    );
  }

  void _addItemSheet() {
    final d = TextEditingController();
    final q = TextEditingController();
    final r = TextEditingController();

    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: d, decoration: const InputDecoration(labelText: "Description")),
          TextField(controller: q, decoration: const InputDecoration(labelText: "Qty")),
          TextField(controller: r, decoration: const InputDecoration(labelText: "Rate")),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              final qty = double.tryParse(q.text) ?? 0;
              final rate = double.tryParse(r.text) ?? 0;
              final amt = qty * rate;

              setState(() {
                (poData["items"] as List).add({
                  "description": d.text,
                  "unit": "Nos",
                  "qty": qty,
                  "rate": rate,
                  "amount": amt,
                });
                poData["totalAmount"] += amt;
              });

              Navigator.pop(context);
            },
            child: const Text("Add Item"),
          )
        ]),
      ),
    );
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }
}
