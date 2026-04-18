import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OwnerApprovalsPage extends StatefulWidget {
  const OwnerApprovalsPage({super.key});

  @override
  State<OwnerApprovalsPage> createState() => _OwnerApprovalsPageState();
}

class _OwnerApprovalsPageState extends State<OwnerApprovalsPage> {
  static const String baseUrl = "http://10.0.2.2:5000/api";

  bool loading = true;
  String errorMsg = "";

  String statusFilter = "all";

  List<Map<String, dynamic>> approvals = [];

  @override
  void initState() {
    super.initState();
    _fetchApprovals();
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("authToken") ?? "";
  }

  Future<void> _fetchApprovals() async {
    final token = await _getToken();
    if (token.isEmpty) {
      setState(() {
        loading = false;
        errorMsg = "Token missing. Login again.";
      });
      return;
    }

    try {
      setState(() {
        loading = true;
        errorMsg = "";
      });

      final url = Uri.parse("$baseUrl/approvals");
      final res = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );
      debugPrint("STATUS: ${res.statusCode}");
      debugPrint("BODY: ${res.body}");

      if (res.body.isEmpty) throw "Empty response from server";

      dynamic data;
      try {
        data = jsonDecode(res.body);
      } catch (_) {
        throw "Server returned non-JSON: ${res.body.substring(0, min(200, res.body.length))}";
      }

      if (res.statusCode >= 400) {
        throw data["message"] ?? "Failed to load approvals";
      }

      final List list = (data["approvals"] ?? []) as List;
      final mapped = list.map((e) => Map<String, dynamic>.from(e)).toList();

      setState(() {
        approvals = mapped;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        errorMsg = "Network error: $e";
      });
    }
  }

  List<Map<String, dynamic>> get filteredApprovals {
    final list = approvals.where((a) {
      if (statusFilter == "all") return true;
      return (a["status"] ?? "").toString().toLowerCase() == statusFilter;
    }).toList();

    // pending first
    list.sort((a, b) {
      final sa = (a["status"] ?? "").toString();
      final sb = (b["status"] ?? "").toString();
      if (sa == "pending" && sb != "pending") return -1;
      if (sa != "pending" && sb == "pending") return 1;
      return 0;
    });

    return list;
  }

  Future<void> _approveRequest(Map<String, dynamic> approval) async {
    final type = (approval["type"] ?? "").toString();
    final id = (approval["_id"] ?? "").toString();
    if (id.isEmpty) return;

    // open modal to enter approved qty/amount
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ApproveBottomSheet(
        approval: approval,
        type: type,
      ),
    );

    if (result == null) return;

    final token = await _getToken();
    if (token.isEmpty) return;

    try {
      final url = Uri.parse("$baseUrl/approvals/$id/approve");
      final res = await http.patch(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(result),
      );

      if (res.body.isEmpty) throw "Empty response";
      final data = jsonDecode(res.body);

      if (res.statusCode >= 400) {
        throw data["message"] ?? "Approve failed";
      }

      // refresh list
      await _fetchApprovals();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Approved successfully ✅",
            style: GoogleFonts.inter(fontWeight: FontWeight.w800),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Approve error: $e")),
      );
    }
  }

  Future<void> _rejectRequest(Map<String, dynamic> approval) async {
    final id = (approval["_id"] ?? "").toString();
    if (id.isEmpty) return;

    final token = await _getToken();
    if (token.isEmpty) return;

    try {
      final url = Uri.parse("$baseUrl/approvals/$id/reject");
      final res = await http.patch(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.body.isEmpty) throw "Empty response";
      final data = jsonDecode(res.body);

      if (res.statusCode >= 400) {
        throw data["message"] ?? "Reject failed";
      }

      await _fetchApprovals();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Rejected ❌",
            style: GoogleFonts.inter(fontWeight: FontWeight.w800),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Reject error: $e")),
      );
    }
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Approvals",
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Approve material requisitions and fund requests.",
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 🏬 Warehouse Inventory Button
                  IconButton(
  tooltip: "Warehouse Inventory",
  iconSize: 32, // 🔥 BIG ICON
  icon: Icon(LucideIcons.warehouse),
  onPressed: () {
    Navigator.pushNamed(context, '/owner/inventory');
  },
),


                  // 🔄 Refresh Button
                  IconButton(
                    onPressed: _fetchApprovals,
                    icon: const Icon(LucideIcons.refreshCcw, size: 18),
                    tooltip: "Refresh",
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ["all", "pending", "approved", "rejected"].map((s) {
                    final active = statusFilter == s;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          s.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                        selected: active,
                        onSelected: (_) => setState(() => statusFilter = s),
                        selectedColor: const Color(0xFF0B3C5D),
                        labelStyle: TextStyle(
                          color:
                              active ? Colors.white : const Color(0xFF64748B),
                        ),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 14),

              Expanded(
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : errorMsg.isNotEmpty
                        ? _ErrorBox(error: errorMsg, onRetry: _fetchApprovals)
                        : filteredApprovals.isEmpty
                            ? Center(
                                child: Text(
                                  "No approvals found.",
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: filteredApprovals.length,
                                itemBuilder: (context, index) {
                                  final a = filteredApprovals[index];
                                  return _ApprovalCard(
                                    approval: a,
                                    onApprove: () => _approveRequest(a),
                                    onReject: () => _rejectRequest(a),
                                  );
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// Widgets
// ------------------------------------------------------------

class _ErrorBox extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorBox({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.triangleAlert,
                size: 40, color: Color(0xFFF59E0B)),
            const SizedBox(height: 10),
            Text(
              "Failed to load approvals",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refreshCcw, size: 18),
              label: Text(
                "Retry",
                style: GoogleFonts.inter(fontWeight: FontWeight.w900),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B3C5D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  final Map<String, dynamic> approval;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ApprovalCard({
    required this.approval,
    required this.onApprove,
    required this.onReject,
  });

  Color _statusColor(String status) {
    switch (status) {
      case "approved":
        return const Color(0xFF16A34A);
      case "rejected":
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFFD97706); // pending
    }
  }

  Color _typeColor(String type) {
    return type == "FUNDS" ? const Color(0xFF2563EB) : const Color(0xFF7C3AED);
  }

  String _projectLocation() {
    final project = approval["projectId"];
    if (project is! Map) return "-";

    final loc = project["location"] ?? {};
    final taluka = (loc["taluka"] ?? "").toString();
    final district = (loc["district"] ?? "").toString();
    final state = (loc["state"] ?? "").toString();

    final parts =
        [taluka, district, state].where((e) => e.trim().isNotEmpty).toList();

    return parts.isEmpty ? "-" : parts.join(", ");
  }

  @override
  Widget build(BuildContext context) {
    final type = (approval["type"] ?? "MATERIAL").toString();
    final status = (approval["status"] ?? "pending").toString();
    final project = approval["projectId"];
    final projectName = (project is Map && project["projectName"] != null)
        ? project["projectName"].toString()
        : "-";

    final requestedBy = approval["requestedBy"] ?? {};
    final requesterName = (requestedBy["name"] ?? "-").toString();
    final requesterRole = (requestedBy["role"] ?? "").toString();

    final requestedAmount = (approval["requestedAmount"] ?? 0).toString();
    final approvedAmount = (approval["approvedAmount"] ?? 0).toString();

    final isPending = status == "pending";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 16,
            offset: Offset(0, 10),
            color: Color(0x0A000000),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // top row
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _typeColor(type).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  type,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: _typeColor(type),
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: _statusColor(status),
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(LucideIcons.chevronRight,
                  size: 18, color: Color(0xFF94A3B8))
            ],
          ),

          const SizedBox(height: 10),

          // title
          Text(
            type == "FUNDS"
                ? (approval["title"] ?? "Funds Request").toString()
                : type == "TASK"
                    ? (approval["taskTitle"] ?? "Task").toString()
                    : (approval["materialName"] ?? "Material Request")
                        .toString(),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),

          // project & location
          Text(
            "$projectName • ${_projectLocation()}",
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 10),

          // requester
          Row(
            children: [
              const Icon(LucideIcons.user, size: 14, color: Color(0xFF94A3B8)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  "$requesterName (${requesterRole.isEmpty ? "MEMBER" : requesterRole})",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF475569),
                  ),
                ),
              )
            ],
          ),

          const SizedBox(height: 12),

          // details row
          if (type == "MATERIAL")
            Row(
              children: [
                Expanded(
                  child: _mini(
                    "Requested",
                    "${approval["requestedQty"] ?? 0} ${approval["unit"] ?? ""}",
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _mini(
                    "Approved",
                    "${approval["approvedQty"] ?? 0}",
                  ),
                ),
              ],
            ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(child: _mini("Funds Requested", "₹$requestedAmount")),
              const SizedBox(width: 10),
              Expanded(child: _mini("Funds Approved", "₹$approvedAmount")),
            ],
          ),

          if (type == "FUNDS" &&
              (approval["purpose"] ?? "").toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              (approval["purpose"] ?? "").toString(),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF475569),
              ),
            ),
          ],

          const SizedBox(height: 12),

          if (isPending)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      "Approve",
                      style: GoogleFonts.inter(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      "Reject",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ),
              ],
            )
        ],
      ),
    );
  }

  Widget _mini(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF94A3B8),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// Approve bottom sheet
// ------------------------------------------------------------
class _ApproveBottomSheet extends StatefulWidget {
  final Map<String, dynamic> approval;
  final String type;

  const _ApproveBottomSheet({
    required this.approval,
    required this.type,
  });

  @override
  State<_ApproveBottomSheet> createState() => _ApproveBottomSheetState();
}

class _ApproveBottomSheetState extends State<_ApproveBottomSheet> {
  late final TextEditingController qtyCtrl;
  late final TextEditingController amtCtrl;

  @override
  void initState() {
    super.initState();
    qtyCtrl = TextEditingController(
      text: (widget.approval["requestedQty"] ?? 0).toString(),
    );
    amtCtrl = TextEditingController(
      text: (widget.approval["requestedAmount"] ?? 0).toString(),
    );
  }

  @override
  void dispose() {
    qtyCtrl.dispose();
    amtCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.type;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Text(
                  "Approve Request",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                )
              ],
            ),

            const SizedBox(height: 16),

            // ================= TASK =================
            if (type == "TASK") ...[
              Text(
                "Approve this task?",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
            ],

            // ================= MATERIAL =================
            if (type == "MATERIAL") ...[
              _label("Approved Quantity"),
              const SizedBox(height: 6),
              _field(qtyCtrl, "Quantity", isNumber: true),
              const SizedBox(height: 12),
            ],

            // ================= MATERIAL / FUNDS =================
            if (type != "TASK") ...[
              _label("Approved Amount"),
              const SizedBox(height: 6),
              _field(amtCtrl, "Amount", isNumber: true),
              const SizedBox(height: 14),
            ],

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // ✅ TASK → send empty body
                      if (type == "TASK") {
                        Navigator.pop<Map<String, dynamic>>(context, {});
                        return;
                      }

                      // MATERIAL / FUNDS
                      Navigator.pop<Map<String, dynamic>>(
                        context,
                        {
                          "approvedAmount": double.tryParse(amtCtrl.text) ?? 0,
                          if (type == "MATERIAL")
                            "approvedQty": double.tryParse(qtyCtrl.text) ?? 0,
                        },
                      );
                    },
                    child: const Text("Confirm"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Align(
        alignment: Alignment.centerLeft,
        child: Text(
          t.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF64748B),
            letterSpacing: 0.8,
          ),
        ),
      );

  Widget _field(TextEditingController c, String hint, {bool isNumber = false}) {
    return TextField(
      controller: c,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
    );
  }
}
