import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

/// ============================================================
/// PROJECT (LOCAL) MATERIAL + FUND REQUESTS PAGE
/// ✅ Engineer/Manager can REQUEST (for this project only)
/// ✅ Owner can APPROVE/REJECT
/// ✅ Everyone can VIEW (project specific)
///
/// Backend needed:
/// GET    /api/approvals/project/:projectId
/// POST   /api/approvals/material
/// POST   /api/approvals/funds
/// PATCH  /api/approvals/:id/approve   (OWNER only)
/// PATCH  /api/approvals/:id/reject    (OWNER only)
/// ============================================================

class ProjectMaterialsPage extends StatefulWidget {
  final String projectId;
  final String projectName;

  const ProjectMaterialsPage({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<ProjectMaterialsPage> createState() => _ProjectMaterialsPageState();
}

class _ProjectMaterialsPageState extends State<ProjectMaterialsPage> {
  static const String baseUrl = "http://10.0.2.2:5000/api";

  bool loading = true;
  String errorMsg = "";

  String statusFilter = "all"; // all, pending, approved, rejected
  String searchQuery = "";

  String token = "";
  Map<String, dynamic>? authUser;

  List<Map<String, dynamic>> requests = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadAuth();
    await _fetchRequests();
  }

  Future<void> _loadAuth() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("authToken") ?? "";
    final raw = prefs.getString("authUser");
    if (raw != null) authUser = jsonDecode(raw);
  }

  bool get isOwner {
    final r = (authUser?["role"] ?? "").toString().toUpperCase();
    return r == "OWNER";
  }

  bool get canRequest {
    final r = (authUser?["role"] ?? "").toString().toUpperCase();
    return r == "ENGINEER" || r == "MANAGER";
  }

  /// ✅ Only THIS project approvals list
  Future<void> _fetchRequests() async {
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

      // ✅ now from approvals
      final url = Uri.parse("$baseUrl/approvals/project/${widget.projectId}");
      final res = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (res.body.isEmpty) throw "Empty response from server";
      final data = jsonDecode(res.body);

      if (res.statusCode >= 400) {
        throw data["message"] ?? "Failed to load requests";
      }

      final List list = (data["approvals"] ?? []) as List;
      requests = list.map((e) => Map<String, dynamic>.from(e)).toList();

      setState(() => loading = false);
    } catch (e) {
      setState(() {
        loading = false;
        errorMsg = "Network error: $e";
      });
    }
  }

  /// ========= helpers =========
  String _id(Map<String, dynamic> r) => (r["_id"] ?? "").toString();

  String _type(Map<String, dynamic> r) =>
      (r["type"] ?? "").toString().toUpperCase(); // MATERIAL / FUNDS

  String _status(Map<String, dynamic> r) =>
      (r["status"] ?? "pending").toString().toLowerCase(); // pending/approved/rejected

  String _requestedBy(Map<String, dynamic> r) {
    final u = r["requestedBy"];
    if (u is Map && u["name"] != null) return u["name"].toString();
    return "-";
  }

  String _title(Map<String, dynamic> r) {
    if (_type(r) == "MATERIAL") {
      final m = (r["materialName"] ?? "").toString();
      return m.isEmpty ? "Material Request" : m;
    } else {
      final t = (r["title"] ?? "").toString();
      return t.isEmpty ? "Funds Request" : t;
    }
  }

  String _subtitle(Map<String, dynamic> r) {
    if (_type(r) == "MATERIAL") {
      final qty = (r["requestedQty"] ?? 0).toString();
      final unit = (r["unit"] ?? "").toString();
      return "$qty $unit";
    } else {
      final amt = (r["requestedAmount"] ?? 0).toString();
      return "₹$amt";
    }
  }

  DateTime _createdAt(Map<String, dynamic> r) {
    try {
      return DateTime.parse(r["createdAt"].toString());
    } catch (_) {
      return DateTime.now();
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case "approved":
        return Colors.green;
      case "rejected":
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _typeIcon(String t) {
    if (t == "MATERIAL") return Icons.inventory_2;
    return Icons.payments;
  }

  List<Map<String, dynamic>> get filteredList {
    var list = requests.toList();

    // filter status
    if (statusFilter != "all") {
      list = list.where((r) => _status(r) == statusFilter).toList();
    }

    // search
    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where((r) {
        return _title(r).toLowerCase().contains(q) ||
            _requestedBy(r).toLowerCase().contains(q) ||
            _id(r).toLowerCase().contains(q);
      }).toList();
    }

    // pending first then latest
    list.sort((a, b) {
      final sa = _status(a);
      final sb = _status(b);

      if (sa == "pending" && sb != "pending") return -1;
      if (sa != "pending" && sb == "pending") return 1;

      return _createdAt(b).compareTo(_createdAt(a));
    });

    return list;
  }

  /// ============================================================
  /// OWNER DECISION
  /// ============================================================
  Future<void> _ownerDecision(Map<String, dynamic> req, String decision) async {
    if (!isOwner) return;

    final requestId = _id(req);
    if (requestId.isEmpty) return;

    try {
      // ✅ approvals endpoints
      final bool isApprove = decision.toUpperCase() == "APPROVED";
      final url = Uri.parse(
        isApprove
            ? "$baseUrl/approvals/$requestId/approve"
            : "$baseUrl/approvals/$requestId/reject",
      );

      final res = await http.patch(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "approvedAmount": req["requestedAmount"] ?? 0,
          "approvedQty": req["requestedQty"] ?? 0,
          "decisionNote": "",
        }),
      );

      if (res.body.isEmpty) throw "Empty response";
      final data = jsonDecode(res.body);

      if (res.statusCode >= 400) {
        throw data["message"] ?? "Failed to update";
      }

      final updated = Map<String, dynamic>.from(data["request"]);

      setState(() {
        requests = requests.map((x) {
          if (_id(x) == requestId) return updated;
          return x;
        }).toList();
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Request $decision ✅")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed: $e")));
    }
  }

  /// ============================================================
  /// CREATE MODAL (LOCAL)
  /// ============================================================
  void _openCreateModal(String type) {
    if (!canRequest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Only Engineer/Manager can request")),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _CreateLocalRequestModal(
        token: token,
        type: type, // MATERIAL / FUNDS
        projectId: widget.projectId,
        onCreated: (created) {
          setState(() {
            requests.insert(0, created);
          });
        },
      ),
    );
  }

  /// ============================================================
  /// UI
  /// ============================================================
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMsg.isNotEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 48, color: Color(0xFFF59E0B)),
                const SizedBox(height: 10),
                const Text(
                  "Failed to load requests",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(errorMsg, textAlign: TextAlign.center),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: _fetchRequests,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Retry"),
                )
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _fetchRequests,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Requests • ${widget.projectName}",
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Material & Funds requests for this project",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (canRequest)
                    Row(
                      children: [
                        Expanded(
                          child: _PrimaryButton(
                            text: "+ Material",
                            icon: Icons.add_box_rounded,
                            onTap: () => _openCreateModal("MATERIAL"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PrimaryButton(
                            text: "+ Funds",
                            icon: Icons.add_card_rounded,
                            onTap: () => _openCreateModal("FUNDS"),
                          ),
                        ),
                      ],
                    ),

                  if (canRequest) const SizedBox(height: 12),

                  TextField(
                    onChanged: (v) => setState(() => searchQuery = v),
                    decoration: InputDecoration(
                      hintText: "Search request...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children:
                          ["all", "pending", "approved", "rejected"].map((s) {
                        final active = statusFilter == s;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () => setState(() => statusFilter = s),
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: active ? Colors.black : Colors.white,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: Colors.black12),
                              ),
                              child: Text(
                                s.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  color: active
                                      ? Colors.white
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  )
                ],
              ),
            ),

            Expanded(
              child: filteredList.isEmpty
                  ? const Center(
                      child: Text(
                        "No requests found",
                        style: TextStyle(
                            fontWeight: FontWeight.w900, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final r = filteredList[index];
                        final type = _type(r);
                        final status = _status(r);

                        return Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(_typeIcon(type),
                                    color: Colors.orange),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _title(r),
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w900),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: _statusColor(status)
                                                .withOpacity(0.12),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            status.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                              color: _statusColor(status),
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      type,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _subtitle(r),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 13),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "Requested By: ${_requestedBy(r)} • ${_id(r)}",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    if (isOwner && status == "pending")
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                ),
                                              ),
                                              onPressed: () =>
                                                  _ownerDecision(r, "APPROVED"),
                                              child: const Text("Approve",
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w900)),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                ),
                                              ),
                                              onPressed: () =>
                                                  _ownerDecision(r, "REJECTED"),
                                              child: const Text("Reject",
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w900)),
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        );
                      },
                    ),
            )
          ],
        ),
      ),
    );
  }
}

/// ============================================================
/// CREATE LOCAL REQUEST MODAL
/// ============================================================
class _CreateLocalRequestModal extends StatefulWidget {
  final String token;
  final String type; // MATERIAL / FUNDS
  final String projectId;
  final Function(Map<String, dynamic>) onCreated;

  const _CreateLocalRequestModal({
    required this.token,
    required this.type,
    required this.projectId,
    required this.onCreated,
  });

  @override
  State<_CreateLocalRequestModal> createState() =>
      _CreateLocalRequestModalState();
}

class _CreateLocalRequestModalState extends State<_CreateLocalRequestModal> {
  static const String baseUrl = "http://10.0.2.2:5000/api";

  final materialNameCtrl = TextEditingController();
  final qtyCtrl = TextEditingController();
  final unitCtrl = TextEditingController();

  final titleCtrl = TextEditingController();
  final purposeCtrl = TextEditingController();
  final amountCtrl = TextEditingController();

  final noteCtrl = TextEditingController();
  String priority = "MED";

  bool submitting = false;
  String error = "";

  Future<void> _create() async {
    final isMaterial = widget.type.toUpperCase() == "MATERIAL";
    final isFunds = widget.type.toUpperCase() == "FUNDS";

    if (isMaterial) {
      if (materialNameCtrl.text.trim().isEmpty) {
        setState(() => error = "Enter material name");
        return;
      }
      if (qtyCtrl.text.trim().isEmpty) {
        setState(() => error = "Enter quantity");
        return;
      }
      if (unitCtrl.text.trim().isEmpty) {
        setState(() => error = "Enter unit");
        return;
      }
    }

    if (isFunds) {
      if (amountCtrl.text.trim().isEmpty) {
        setState(() => error = "Enter amount");
        return;
      }
      if (purposeCtrl.text.trim().isEmpty) {
        setState(() => error = "Enter purpose");
        return;
      }
    }

    setState(() {
      submitting = true;
      error = "";
    });

    try {
      // ✅ approvals endpoints
      final url = Uri.parse(
        isMaterial ? "$baseUrl/approvals/material" : "$baseUrl/approvals/funds",
      );

      final body = <String, dynamic>{
        "projectId": widget.projectId,
        "priority": priority,
        "note": noteCtrl.text.trim(),
      };

      if (isMaterial) {
        body["materialName"] = materialNameCtrl.text.trim();
        body["requestedQty"] = int.tryParse(qtyCtrl.text.trim()) ?? 0;
        body["unit"] = unitCtrl.text.trim();
        body["requestedAmount"] = 0;
      }

      if (isFunds) {
        body["title"] = titleCtrl.text.trim().isEmpty ? "Funds Request" : titleCtrl.text.trim();
        body["purpose"] = purposeCtrl.text.trim();
        body["requestedAmount"] = int.tryParse(amountCtrl.text.trim()) ?? 0;
      }

      final res = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
        body: jsonEncode(body),
      );

      if (res.body.isEmpty) throw "Empty response";
      final data = jsonDecode(res.body);

      if (res.statusCode >= 400) {
        setState(() {
          submitting = false;
          error = data["message"] ?? "Failed to create request";
        });
        return;
      }

      final created = Map<String, dynamic>.from(data["request"]);
      widget.onCreated(created);

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Request created ✅")),
      );
    } catch (e) {
      setState(() {
        submitting = false;
        error = "Network error: $e";
      });
    }
  }

  @override
  void dispose() {
    materialNameCtrl.dispose();
    qtyCtrl.dispose();
    unitCtrl.dispose();
    titleCtrl.dispose();
    purposeCtrl.dispose();
    amountCtrl.dispose();
    noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMaterial = widget.type.toUpperCase() == "MATERIAL";

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        14,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 5,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Text(
            isMaterial ? "New Material Request" : "New Funds Request",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),

          if (isMaterial) ...[
            TextField(
              controller: materialNameCtrl,
              decoration: const InputDecoration(hintText: "Material name"),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: "Qty"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: unitCtrl,
                    decoration: const InputDecoration(hintText: "Unit"),
                  ),
                ),
              ],
            ),
          ] else ...[
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(hintText: "Title (optional)"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: purposeCtrl,
              decoration: const InputDecoration(hintText: "Purpose"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: "Amount"),
            ),
          ],

          const SizedBox(height: 12),
          TextField(
            controller: noteCtrl,
            maxLines: 2,
            decoration: const InputDecoration(hintText: "Note (optional)"),
          ),

          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: priority,
            items: const [
              DropdownMenuItem(value: "LOW", child: Text("LOW")),
              DropdownMenuItem(value: "MED", child: Text("MEDIUM")),
              DropdownMenuItem(value: "HIGH", child: Text("HIGH")),
            ],
            onChanged: (v) => setState(() => priority = v ?? "MED"),
          ),

          if (error.isNotEmpty) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                error,
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w800),
              ),
            ),
          ],

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: submitting ? null : _create,
              child: submitting
                  ? const CircularProgressIndicator()
                  : const Text("CREATE REQUEST"),
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================================
/// Primary Button
/// ============================================================
class _PrimaryButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.text,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0B3C5D),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
