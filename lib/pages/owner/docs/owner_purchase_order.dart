import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../docs/pdf_preview_page.dart'; // adjust path if needed

class OwnerPoApprovalsPage extends StatefulWidget {
  const OwnerPoApprovalsPage({super.key});

  @override
  State<OwnerPoApprovalsPage> createState() => _OwnerPoApprovalsPageState();
}

class _OwnerPoApprovalsPageState extends State<OwnerPoApprovalsPage> {
  static const String baseUrl = "http://10.0.2.2:5000/api";

  bool loading = true;
  String error = "";

  List<Map<String, dynamic>> approvals = [];

  Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("authToken") ?? "";
  }

  /* ================= FETCH OWNER APPROVALS ================= */

  Future<void> fetchApprovals() async {
    final token = await _token();
    if (token.isEmpty) return;

    try {
      setState(() {
        loading = true;
        error = "";
      });

      final res = await http.get(
        Uri.parse("$baseUrl/approvals"),
        headers: {"Authorization": "Bearer $token"},
      );

      final data = jsonDecode(res.body);
      if (res.statusCode >= 400) {
        throw data["message"] ?? "Failed to load approvals";
      }

      final list = (data["approvals"] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e))
          .where((a) => a["poId"] != null) // ✅ ONLY PO approvals
          .toList();

      setState(() {
        approvals = list;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  /* ================= PDF PREVIEW ================= */

  Future<void> openPo(String poId) async {
    final token = await _token();

    final res = await http.get(
      Uri.parse("$baseUrl/doc-history/purchase-orders/$poId/url"),
      headers: {"Authorization": "Bearer $token"},
    );

    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) {
      throw data["message"] ?? "Failed to open PO";
    }

    if (!mounted) return;
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

  /* ================= APPROVE / REJECT ================= */

  Future<void> _decision(
    String approvalId,
    bool approve,
  ) async {
    final token = await _token();

    final res = await http.patch(
      Uri.parse(
        "$baseUrl/approvals/$approvalId/${approve ? "approve" : "reject"}",
      ),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"decisionNote": ""}),
    );

    if (res.statusCode >= 400) {
      final data = jsonDecode(res.body);
      throw data["message"] ?? "Action failed";
    }

    await fetchApprovals();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(approve ? "PO Approved ✅" : "PO Rejected ❌"),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchApprovals();
  }

  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Purchase Order Approvals"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
              ? Center(child: Text(error))
              : approvals.isEmpty
                  ? const Center(child: Text("No pending purchase orders"))
                  : RefreshIndicator(
                      onRefresh: fetchApprovals,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: approvals.length,
                        itemBuilder: (_, i) {
                          final a = approvals[i];
                          final project = a["projectId"] ?? {};
                          final by = a["requestedBy"] ?? {};
                          final createdAt = a["createdAt"];

                          String date = "";
                          if (createdAt != null) {
                            date = DateFormat("dd MMM yyyy")
                                .format(DateTime.parse(createdAt));
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(a["title"] ?? "Purchase Order"),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(project["projectName"] ?? ""),
                                  Text(
                                    "Requested by: ${by["name"] ?? "Engineer"}",
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  if (date.isNotEmpty)
                                    Text(date,
                                        style:
                                            const TextStyle(fontSize: 11)),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (v) async {
                                  if (v == "view") {
                                    await openPo(a["poId"]);
                                  }
                                  if (v == "approve") {
                                    await _decision(a["_id"], true);
                                  }
                                  if (v == "reject") {
                                    await _decision(a["_id"], false);
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                      value: "view", child: Text("Preview")),
                                  PopupMenuItem(
                                      value: "approve",
                                      child: Text("Approve")),
                                  PopupMenuItem(
                                      value: "reject", child: Text("Reject")),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
