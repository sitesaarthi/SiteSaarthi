import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:sitesaarthi/routes.dart';


class EngineerMaterialsFundsPage extends StatefulWidget {
  final String role; // ENGINEER / MANAGER / OWNER
  const EngineerMaterialsFundsPage({super.key, this.role = "ENGINEER"});

  @override
  State<EngineerMaterialsFundsPage> createState() =>
      _EngineerMaterialsFundsPageState();
}

class _EngineerMaterialsFundsPageState
    extends State<EngineerMaterialsFundsPage> {
  static const String baseUrl = "http://10.0.2.2:5000/api";

  String token = "";
  Map<String, dynamic>? authUser;

  bool loading = true;
  String errorMsg = "";

  String statusFilter = "all"; // all | pending | approved | rejected
  String searchQuery = "";

  List<Map<String, dynamic>> approvals = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadAuth();
    await _fetchApprovals();
  }

  Future<void> _loadAuth() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("authToken") ?? "";
    final raw = prefs.getString("authUser");
    if (raw != null) authUser = jsonDecode(raw);
  }

  bool get isOwner {
    final r = (authUser?["role"] ?? widget.role).toString().toUpperCase();
    return r == "OWNER";
  }

  bool get canRequest {
    final r = (authUser?["role"] ?? widget.role).toString().toUpperCase();
    return r == "ENGINEER" || r == "MANAGER";
  }

  /// ============================================================
  /// FETCH APPROVALS
  /// OWNER:      GET /api/approvals
  /// ENG/MAN:    GET /api/approvals/global
  /// ============================================================
  Future<void> _fetchApprovals() async {
    if (token.isEmpty) {
      setState(() {
        loading = false;
        errorMsg = "Token missing. Please login again.";
      });
      return;
    }

    try {
      setState(() {
        loading = true;
        errorMsg = "";
      });

      final endpoint = isOwner ? "/approvals" : "/approvals/global";
      final url = Uri.parse("$baseUrl$endpoint");

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

  /// ============================================================
  /// HELPERS
  /// ============================================================
  String _id(Map<String, dynamic> r) => (r["_id"] ?? "").toString();

  String _type(Map<String, dynamic> r) =>
      (r["type"] ?? "").toString().toUpperCase(); // MATERIAL / FUNDS

  String _status(Map<String, dynamic> r) =>
      (r["status"] ?? "pending").toString().toLowerCase();

  String _projectName(Map<String, dynamic> r) {
    final p = r["projectId"];
    if (p is Map && p["projectName"] != null)
      return p["projectName"].toString();
    return "-";
  }

  String _requestedBy(Map<String, dynamic> r) {
    final u = r["requestedBy"];
    if (u is Map && u["name"] != null) return u["name"].toString();
    return "-";
  }

  String _title(Map<String, dynamic> r) {
    if (_type(r) == "MATERIAL") {
      return (r["materialName"] ?? "Material Request").toString();
    }
    if (_type(r) == "FUNDS") {
      return (r["title"] ?? "Funds Request").toString();
    }
    return (r["taskTitle"] ?? "Task").toString(); // TASK
  }

  String _subtitle(Map<String, dynamic> r) {
    if (_type(r) == "MATERIAL") {
      final qty = (r["requestedQty"] ?? 0).toString();
      final unit = (r["unit"] ?? "").toString();
      return "$qty $unit";
    }
    if (_type(r) == "FUNDS") {
      final amt = (r["requestedAmount"] ?? 0).toString();
      return "₹$amt";
    }
    return (r["taskDescription"] ?? "").toString(); // TASK
  }

  DateTime _createdAt(Map<String, dynamic> r) {
    try {
      return DateTime.parse(r["createdAt"].toString());
    } catch (_) {
      return DateTime.now();
    }
  }

  IconData _typeIcon(String type) {
    if (type == "MATERIAL") return Icons.inventory_2;
    if (type == "FUNDS") return Icons.payments;
    return Icons.task_alt; // TASK
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

  /// ============================================================
  /// FILTER + SEARCH + SORT
  /// ============================================================
  List<Map<String, dynamic>> get filteredList {
    var list = approvals.toList();

    if (statusFilter != "all") {
      list = list.where((r) => _status(r) == statusFilter).toList();
    }

    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where((r) {
        return _title(r).toLowerCase().contains(q) ||
            _projectName(r).toLowerCase().contains(q) ||
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
    final id = _id(req);
    if (id.isEmpty) return;
    if (!isOwner) return;

    try {
      final url = Uri.parse("$baseUrl/approvals/$id/${decision.toLowerCase()}");
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
        approvals = approvals.map((x) {
          if (_id(x) == id) return updated;
          return x;
        }).toList();
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Request ${decision.toUpperCase()} ✅")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed: $e")),
      );
    }
  }

  void _openCreateModal(String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _CreateApprovalModal(
        token: token,
        type: type, // MATERIAL / FUNDS
        onCreated: (created) {
          setState(() {
            approvals.insert(0, created);
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
        body: Center(child: Text(errorMsg)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _fetchApprovals,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Requests",
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(
                    "Materials + Funds approvals",
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 14),
                  if (canRequest)
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _PrimaryActionButton(
                                text: "+ Material",
                                icon: Icons.add_box_rounded,
                                onTap: () => _openCreateModal("MATERIAL"),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _PrimaryActionButton(
                                text: "+ Funds",
                                icon: Icons.add_card_rounded,
                                onTap: () => _openCreateModal("FUNDS"),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _PrimaryActionButton(
                          text: "+ Task",
                          icon: Icons.task_alt,
                          onTap: () => _openCreateModal("TASK"),
                        ),
                        const SizedBox(height: 10),
                        _PrimaryActionButton(
                          text: "Tools IN / OUT",
                          icon: Icons.qr_code_scanner_rounded,
                          onTap: () {
                            Navigator.pushNamed(
                                context, AppRoutes.engineerTools);
                          },
                        ),
                      ],
                    ),
                  
                  const SizedBox(height: 14),
                  TextField(
                    onChanged: (v) => setState(() => searchQuery = v),
                    decoration: InputDecoration(
                      hintText: "Search",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
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
                ],
              ),
            ),
            Expanded(
              child: filteredList.isEmpty
                  ? const Center(
                      child: Text("No requests found",
                          style: TextStyle(
                              fontWeight: FontWeight.w900, color: Colors.grey)),
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
                                child:
                                    Icon(_typeIcon(type), color: Colors.orange),
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
                                              fontWeight: FontWeight.w900,
                                            ),
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
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text("${_projectName(r)} • $type",
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.grey.shade600)),
                                    const SizedBox(height: 6),
                                    Text(_subtitle(r),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 13)),
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
                                                        BorderRadius.circular(
                                                            14)),
                                              ),
                                              onPressed: () =>
                                                  _ownerDecision(r, "approve"),
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
                                                        BorderRadius.circular(
                                                            14)),
                                              ),
                                              onPressed: () =>
                                                  _ownerDecision(r, "reject"),
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
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ============================================================
/// CREATE MODAL
/// ============================================================
class _CreateApprovalModal extends StatefulWidget {
  final String token;
  final String type; // MATERIAL / FUNDS
  final Function(Map<String, dynamic>) onCreated;

  const _CreateApprovalModal({
    required this.token,
    required this.type,
    required this.onCreated,
  });

  @override
  State<_CreateApprovalModal> createState() => _CreateApprovalModalState();
}

class _CreateApprovalModalState extends State<_CreateApprovalModal> {
  // 1️⃣ VARIABLES (YOU ALREADY HAVE THIS)
  static const String baseUrl = "http://10.0.2.2:5000/api";

  List<Map<String, dynamic>> myProjects = [];
  String projectId = "";

  final materialCtrl = TextEditingController();
  final qtyCtrl = TextEditingController();
  final unitCtrl = TextEditingController();

  final titleCtrl = TextEditingController();
  final purposeCtrl = TextEditingController();
  final amountCtrl = TextEditingController();

  final taskTitleCtrl = TextEditingController();
  final taskDescCtrl = TextEditingController();

  String priority = "MED";
  bool submitting = false;
  String error = "";

  // 2️⃣ initState (KEEP AS-IS)
  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  // 3️⃣ API METHODS (KEEP AS-IS)
  Future<void> _loadProjects() async {
    try {
      final url = Uri.parse("$baseUrl/projects");
      final res = await http.get(
        url,
        headers: {
          "Authorization": "Bearer ${widget.token}",
        },
      );

      if (res.body.isEmpty) return;

      final data = jsonDecode(res.body);
      final List list = (data["projects"] ?? []) as List;

      setState(() {
        myProjects = list.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    } catch (e) {
      setState(() {
        error = "Failed to load projects";
      });
    }
  }

  String _pid(Map<String, dynamic> p) => (p["_id"] ?? "").toString();

  String _pname(Map<String, dynamic> p) => (p["projectName"] ?? "-").toString();

  Future<void> _create() async {
    if (projectId.isEmpty) {
      setState(() => error = "Select project");
      return;
    }

    final isMaterial = widget.type == "MATERIAL";
    final isTask = widget.type == "TASK";

    setState(() {
      submitting = true;
      error = "";
    });

    try {
      Uri url;
      Map<String, dynamic> body = {
        "projectId": projectId,
        "priority": priority,
      };

      if (isTask) {
        if (taskTitleCtrl.text.trim().isEmpty ||
            taskDescCtrl.text.trim().isEmpty) {
          setState(() {
            submitting = false;
            error = "Enter task title and description";
          });
          return;
        }

        url = Uri.parse("$baseUrl/approvals/task");
        body.addAll({
          "type": "TASK",
          "taskTitle": taskTitleCtrl.text.trim(),
          "taskDescription": taskDescCtrl.text.trim(),
        });
      } else if (isMaterial) {
        if (materialCtrl.text.trim().isEmpty ||
            qtyCtrl.text.trim().isEmpty ||
            unitCtrl.text.trim().isEmpty) {
          setState(() {
            submitting = false;
            error = "Fill all material fields";
          });
          return;
        }

        url = Uri.parse("$baseUrl/approvals/material");
        body.addAll({
          "type": "MATERIAL",
          "materialName": materialCtrl.text.trim(),
          "requestedQty": int.tryParse(qtyCtrl.text.trim()) ?? 0,
          "unit": unitCtrl.text.trim(),
        });
      } else {
        if (amountCtrl.text.trim().isEmpty) {
          setState(() {
            submitting = false;
            error = "Enter amount";
          });
          return;
        }

        url = Uri.parse("$baseUrl/approvals/funds");
        body.addAll({
          "type": "FUNDS",
          "title": titleCtrl.text.trim(),
          "purpose": purposeCtrl.text.trim(),
          "requestedAmount": int.tryParse(amountCtrl.text.trim()) ?? 0,
        });
      }

      final res = await http.post(
        url,
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode >= 400) {
        setState(() {
          submitting = false;
          error = data["message"] ?? "Failed";
        });
        return;
      }

      widget.onCreated(Map<String, dynamic>.from(data["request"]));
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        submitting = false;
        error = "Network error";
      });
    }
  }

  // 🔥🔥🔥 5️⃣ BUILD METHOD — THIS IS THE ONLY NEW THING
  // 🔥🔥🔥 PASTE EXACTLY HERE
  @override
  Widget build(BuildContext context) {
    final isMaterial = widget.type == "MATERIAL";
    final isTask = widget.type == "TASK";

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PROJECT DROPDOWN
          DropdownButtonFormField<String>(
            value: projectId.isEmpty ? null : projectId,
            hint: const Text("Select Project"),
            items: myProjects
                .map(
                  (p) => DropdownMenuItem(
                    value: _pid(p),
                    child: Text(_pname(p)),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => projectId = v ?? ""),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ),

          const SizedBox(height: 12),

          if (isTask) ...[
            _field(taskTitleCtrl, "Task Title"),
            _field(taskDescCtrl, "Task Description"),
          ],

          if (isMaterial) ...[
            _field(materialCtrl, "Material Name"),
            _field(qtyCtrl, "Quantity"),
            _field(unitCtrl, "Unit"),
          ],

          if (!isMaterial && !isTask) ...[
            _field(titleCtrl, "Title"),
            _field(purposeCtrl, "Purpose"),
            _field(amountCtrl, "Amount"),
          ],

          if (error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                error,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: submitting ? null : _create,
              child: const Text(
                "CREATE REQUEST",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 6️⃣ FIELD HELPER — MUST BE AFTER build()
  Widget _field(TextEditingController ctrl, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
        ),
      ),
    );
  }

  // 7️⃣ DISPOSE — LAST THING
  @override
  void dispose() {
    materialCtrl.dispose();
    qtyCtrl.dispose();
    unitCtrl.dispose();
    titleCtrl.dispose();
    purposeCtrl.dispose();
    amountCtrl.dispose();
    taskTitleCtrl.dispose();
    taskDescCtrl.dispose();
    super.dispose();
  }
}

/// ============================================================
/// Button component
/// ============================================================
class _PrimaryActionButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryActionButton({
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
