import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../../../nav/engineer_project_nav.dart';

class EngineerProjectsPage extends StatefulWidget {
  const EngineerProjectsPage({super.key});

  @override
  State<EngineerProjectsPage> createState() => _EngineerProjectsPageState();
}

class _EngineerProjectsPageState extends State<EngineerProjectsPage> {
  static const String baseUrl = "http://10.0.2.2:5000/api";

  final TextEditingController searchCtrl = TextEditingController();

  bool loading = true;
  String errorMsg = "";

  String token = "";
  Map<String, dynamic>? authUser;

  List<Map<String, dynamic>> projects = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await _loadAuth();
    await _fetchProjects();
  }

  Future<void> _loadAuth() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("authToken") ?? "";
    final raw = prefs.getString("authUser");
    if (raw != null) authUser = jsonDecode(raw);
  }

  /// ✅ Extract project id safely
  String _projectId(Map<String, dynamic> p) {
    if (p["_id"] != null) return p["_id"].toString();
    if (p["id"] != null) return p["id"].toString();
    return "";
  }

  String _projectName(Map<String, dynamic> p) {
    return (p["projectName"] ?? p["name"] ?? "-").toString();
  }

  String _projectLocation(Map<String, dynamic> p) {
    final loc = p["location"] ?? {};
    final taluka = (loc["taluka"] ?? "").toString();
    final district = (loc["district"] ?? "").toString();
    final state = (loc["state"] ?? "").toString();
    final parts =
        [taluka, district, state].where((e) => e.trim().isNotEmpty).toList();
    return parts.isEmpty ? "-" : parts.join(", ");
  }

  /// ✅ Remove duplicates by _id
  List<Map<String, dynamic>> _uniqueProjects(List<Map<String, dynamic>> list) {
    final seen = <String>{};
    final out = <Map<String, dynamic>>[];

    for (final p in list) {
      final id = _projectId(p);
      if (id.isEmpty) continue;
      if (seen.add(id)) out.add(p);
    }
    return out;
  }

  /// ✅ Proper fetch projects
  Future<void> _fetchProjects({bool silent = false}) async {
    if (token.isEmpty) {
      if (!mounted) return;
      setState(() {
        loading = false;
        errorMsg = "Token missing. Please login again.";
      });
      return;
    }

    try {
      if (!silent) {
        if (!mounted) return;
        setState(() {
          loading = true;
          errorMsg = "";
          projects = []; // ✅ force UI refresh
        });
      } else {
        if (!mounted) return;
        setState(() => errorMsg = "");
      }

      final url = Uri.parse("$baseUrl/projects");
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
        throw data["message"] ?? "Failed to load projects";
      }

      final List list = (data["projects"] ?? []) as List;
      final mapped = list.map((e) => Map<String, dynamic>.from(e)).toList();
      final unique = _uniqueProjects(mapped);

      if (!mounted) return;
      setState(() {
        projects = List<Map<String, dynamic>>.from(unique); // ✅ NEW reference
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        errorMsg = "Network error: $e";
      });
    }
  }

  List<Map<String, dynamic>> get filtered {
    final q = searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return projects;

    return projects.where((p) {
      final name = _projectName(p).toLowerCase();
      final loc = _projectLocation(p).toLowerCase();
      return name.contains(q) || loc.contains(q);
    }).toList();
  }

  void _openJoinModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _JoinByCodeModal(
        token: token,
        onSuccess: () async {
          // ✅ refresh
          await _fetchProjects(silent: true);
        },
      ),
    );
  }

  int _gridCount(double width) {
    if (width >= 1024) return 3;
    if (width >= 720) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

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
                  "Failed to load projects",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  errorMsg,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: _fetchProjects,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Retry"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B3C5D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Text(
                      "My Projects",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _openJoinModal,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text(
                      "Join",
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 14),

              /// SEARCH
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: "Search projects...",
                    prefixIcon: Icon(Icons.search),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              /// GRID
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => _fetchProjects(silent: true),
                  child: filtered.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 140),
                            Center(
                              child: Text(
                                "No projects yet.\nJoin using invite code.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        )
                      : GridView.builder(
                          itemCount: filtered.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: _gridCount(w),
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 1.35,
                          ),
                          itemBuilder: (context, index) {
                            final p = filtered[index];
                            return _ProjectCardBackend(
                              project: p,
                              onEnter: () {
                                Navigator.of(context, rootNavigator: true).push(
                                  MaterialPageRoute(
                                    builder: (_) => EngineerProjectNav(
                                      projectId: _projectId(p),
                                      projectName: _projectName(p),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ============================================================
/// PROJECT CARD (BACKEND)
/// ============================================================
class _ProjectCardBackend extends StatelessWidget {
  final Map<String, dynamic> project;
  final VoidCallback onEnter;

  const _ProjectCardBackend({
    required this.project,
    required this.onEnter,
  });

  String _projectName(Map<String, dynamic> p) =>
      (p["projectName"] ?? p["name"] ?? "-").toString();

  String _projectLocation(Map<String, dynamic> p) {
    final loc = p["location"] ?? {};
    final taluka = (loc["taluka"] ?? "").toString();
    final district = (loc["district"] ?? "").toString();
    final state = (loc["state"] ?? "").toString();
    final parts =
        [taluka, district, state].where((e) => e.trim().isNotEmpty).toList();
    return parts.isEmpty ? "-" : parts.join(", ");
  }

  @override
  Widget build(BuildContext context) {
    final name = _projectName(project);
    final location = _projectLocation(project);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 12,
            offset: Offset(0, 8),
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(height: 6, color: const Color(0xFF10B981)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          location,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B3C5D),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: onEnter,
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text(
                        "Enter Site",
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

/// ============================================================
/// JOIN MODAL (INVITE CODE)
/// ============================================================
class _JoinByCodeModal extends StatefulWidget {
  final String token;
  final Future<void> Function() onSuccess;

  const _JoinByCodeModal({
    required this.token,
    required this.onSuccess,
  });

  @override
  State<_JoinByCodeModal> createState() => _JoinByCodeModalState();
}

class _JoinByCodeModalState extends State<_JoinByCodeModal> {
  static const String baseUrl = "http://10.0.2.2:5000/api";

  final codeCtrl = TextEditingController();
  bool joining = false;
  String error = "";

  @override
  void dispose() {
    codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = codeCtrl.text.trim().toUpperCase();

    if (code.isEmpty || code.length < 4) {
      setState(() => error = "Enter valid invite code");
      return;
    }

    setState(() {
      joining = true;
      error = "";
    });

    try {
      final url = Uri.parse("$baseUrl/projects/join/code");
      final res = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
        body: jsonEncode({"inviteCode": code}),
      );

      if (res.body.isEmpty) throw "Empty response from server";
      final data = jsonDecode(res.body);

      if (res.statusCode >= 400) {
        setState(() {
          joining = false;
          error = data["message"] ?? "Failed to join project";
        });
        return;
      }

      final msg = (data["message"] ?? "").toString().toLowerCase();

      if (!mounted) return;
      Navigator.pop(context);

      await widget.onSuccess();

      if (!mounted) return;

      if (msg.contains("already")) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Already added ✅")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Joined project successfully ✅")),
        );
      }
    } catch (e) {
      setState(() {
        joining = false;
        error = "Network error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        18,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Join Project",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(
                onPressed: joining ? null : () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              )
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: codeCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: "Enter Invite Code",
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            ),
          ),
          if (error.isNotEmpty) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                error,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFDC2626),
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
              ),
              onPressed: joining ? null : _join,
              child: joining
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      "JOIN PROJECT",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
