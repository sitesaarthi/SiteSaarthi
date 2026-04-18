import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'project_details_page.dart';

class OwnerProjectsPage extends StatefulWidget {
  const OwnerProjectsPage({super.key});

  @override
  State<OwnerProjectsPage> createState() => _OwnerProjectsPageState();
}

class _OwnerProjectsPageState extends State<OwnerProjectsPage> {
  static const String baseUrl = "http://10.0.2.2:5000/api";

  //static const String baseUrl = "http://192.168.5.104:5000/api";


  final TextEditingController searchCtrl = TextEditingController();
  String searchQuery = "";

  bool loading = true;
  String errorMsg = "";

  String token = "";
  Map<String, dynamic>? authUser;

  List<Map<String, dynamic>> projects = [];
  @override
  void initState() {
    super.initState();

    searchCtrl.addListener(() {
      setState(() => searchQuery = searchCtrl.text.trim().toLowerCase());
    });

    _init();
  }

  Future<void> _init() async {
    await _loadAuth();
    await _fetchProjects();
  }

  Future<void> _loadAuth() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("authToken") ?? "";
    final raw = prefs.getString("authUser");

    if (raw != null) {
      authUser = jsonDecode(raw);
    }
  }

  Future<void> _fetchProjects() async {
    if (token.isEmpty) {
      setState(() {
        loading = false;
        errorMsg = "No token found. Please login again.";
      });
      return;
    }

    try {
      setState(() {
        loading = true;
        errorMsg = "";
      });

      final url = Uri.parse("$baseUrl/projects");
      final res = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      final data = jsonDecode(res.body);

      if (res.statusCode >= 400) {
        setState(() {
          loading = false;
          errorMsg = data["message"] ?? "Failed to load projects";
        });
        return;
      }

      final List list = (data["projects"] ?? []) as List;
      final mapped = list.map((e) => Map<String, dynamic>.from(e)).toList();

      setState(() {
        projects = mapped;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        errorMsg = "Network error: $e";
      });
    }
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  bool _matchesSearch(Map<String, dynamic> p) {
    if (searchQuery.isEmpty) return true;

    final name = (p["projectName"] ?? "").toString().toLowerCase();

    final loc = p["location"] ?? {};
    final state = (loc["state"] ?? "").toString().toLowerCase();
    final district = (loc["district"] ?? "").toString().toLowerCase();
    final taluka = (loc["taluka"] ?? "").toString().toLowerCase();
    final addressLine = (loc["addressLine"] ?? "").toString().toLowerCase();

    final combinedLoc = "$state $district $taluka $addressLine";

    return name.contains(searchQuery) || combinedLoc.contains(searchQuery);
  }

  void _openAddProjectModal() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AddProjectDialogBackend(
        token: token,
        onCreated: (createdProject) {
          setState(() {
            projects.insert(0, createdProject);
          });

          // ✅ Success popup showing invite code properly
          final code = (createdProject["inviteCode"] ?? "").toString();
          if (code.isNotEmpty) {
            Future.delayed(const Duration(milliseconds: 250), () {
              if (!mounted) return;
              showDialog(
                context: context,
                barrierDismissible: true,
                builder: (_) => InviteCodeSuccessDialog(inviteCode: code),
              );
            });
          }
        },
      ),
    );
  }

  void _viewDetails(Map<String, dynamic> project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectDetailsPage(project: project),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = 1200.0;
    final filtered = projects.where(_matchesSearch).toList();

    final width = MediaQuery.of(context).size.width;
    final cols = width >= 1100
        ? 3
        : width >= 780
            ? 2
            : 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row (only title + refresh)
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Project Management",
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Manage and monitor your active construction sites.",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _fetchProjects,
                        icon: const Icon(LucideIcons.refreshCcw, size: 18),
                        tooltip: "Refresh",
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ✅ Add Project button moved above search bar (separate row)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openAddProjectModal,
                      icon: const Icon(LucideIcons.plus, size: 18),
                      label: Text(
                        "Add New Project",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B3C5D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Search bar
                  Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        const Icon(LucideIcons.search,
                            size: 18, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: searchCtrl,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                            decoration: InputDecoration(
                              hintText: "Search projects...",
                              hintStyle: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF94A3B8),
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        if (searchQuery.isNotEmpty)
                          IconButton(
                            onPressed: () => searchCtrl.clear(),
                            icon: const Icon(Icons.close_rounded, size: 18),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  Expanded(
                    child: loading
                        ? const Center(child: CircularProgressIndicator())
                        : errorMsg.isNotEmpty
                            ? _ErrorState(
                                error: errorMsg,
                                onRetry: _fetchProjects,
                              )
                            : filtered.isEmpty
                                ? _EmptyState(onAdd: _openAddProjectModal)
                                : GridView.builder(
                                    itemCount: filtered.length,
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: cols,
                                      crossAxisSpacing: 14,
                                      mainAxisSpacing: 14,
                                      childAspectRatio: 1.25,
                                    ),
                                    itemBuilder: (context, index) {
                                      final p = filtered[index];
                                      return ProjectCardBackend(
                                        project: p,
                                        onViewDetails: () => _viewDetails(p),
                                      );
                                    },
                                  ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// INVITE CODE SUCCESS DIALOG
/// ------------------------------------------------------------
class InviteCodeSuccessDialog extends StatelessWidget {
  final String inviteCode;

  const InviteCodeSuccessDialog({super.key, required this.inviteCode});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(18),
        width: 420,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              blurRadius: 24,
              offset: Offset(0, 16),
              color: Color(0x22000000),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(Icons.check_rounded,
                  color: Color(0xFF16A34A), size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              "Project Created!",
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Invite Code",
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  inviteCode,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0B3C5D),
                    letterSpacing: 5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: inviteCode),
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Invite code copied",
                            style: GoogleFonts.inter(fontWeight: FontWeight.w800),
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      "Copy Code",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0B3C5D),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B3C5D),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      "Done",
                      style: GoogleFonts.inter(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// ERROR STATE
/// ------------------------------------------------------------
class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 26),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.triangleAlert,
                size: 42, color: Color(0xFFF59E0B)),
            const SizedBox(height: 10),
            Text(
              "Failed to load projects",
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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

/// ------------------------------------------------------------
/// EMPTY STATE
/// ------------------------------------------------------------
class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.building2,
                size: 44, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 12),
            Text(
              "No Projects Found",
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "You haven't added any projects yet.",
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B3C5D),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                "Add Project",
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// PROJECT CARD (Backend project map)
/// ------------------------------------------------------------
class ProjectCardBackend extends StatelessWidget {
  final Map<String, dynamic> project;
  final VoidCallback onViewDetails;

  const ProjectCardBackend({
    super.key,
    required this.project,
    required this.onViewDetails,
  });

  String _getLocationString(Map<String, dynamic> project) {
    final loc = project["location"] ?? {};
    final taluka = (loc["taluka"] ?? "").toString();
    final district = (loc["district"] ?? "").toString();
    final state = (loc["state"] ?? "").toString();

    final parts = [taluka, district, state]
        .where((e) => e.trim().isNotEmpty)
        .toList();
    return parts.isEmpty ? "-" : parts.join(", ");
  }

  String _getProjectAmount(Map<String, dynamic> project) {
    final costs = project["costs"] ?? {};
    final raw = costs["totalProjectCostCr"];

    if (raw == null) return "-";

    double v = 0;
    if (raw is int) v = raw.toDouble();
    if (raw is double) v = raw;
    if (raw is String) v = double.tryParse(raw) ?? 0;

    if (v <= 0) return "-";

    // Format: ₹16.85 Cr
    String out = v.toStringAsFixed(v % 1 == 0 ? 0 : 2);
    return "₹$out Cr";
  }

  Future<void> _copyCode(BuildContext context) async {
    final code = (project["inviteCode"] ?? "").toString();
    if (code.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: code));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Copied code: $code",
          style: GoogleFonts.inter(fontWeight: FontWeight.w800),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = (project["projectName"] ?? "").toString();
    final location = _getLocationString(project);
    final amount = _getProjectAmount(project);
    final invite = (project["inviteCode"] ?? "").toString();

    final progress = 40 + Random().nextInt(55);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onViewDetails,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              blurRadius: 18,
              offset: Offset(0, 12),
              color: Color(0x0C000000),
            )
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEDD5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          (project["status"] ?? "ACTIVE").toString(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFEA580C),
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "Completion",
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF94A3B8),
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$progress%",
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        const Icon(LucideIcons.mapPin,
                            size: 14, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            location,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF64748B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 0, color: Color(0xFFF1F5F9)),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _MiniInfo(label: "Project Amount", value: amount),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MiniInfo(
                          label: "Invite Code",
                          value: invite.isEmpty ? "-" : invite,
                          mono: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text(
                        "Progress",
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF94A3B8),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        "$progress%",
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F172A),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: progress / 100.0,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: const AlwaysStoppedAnimation(
                        Color(0xFF0B3C5D),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onViewDetails,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "View Details",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0B3C5D),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(LucideIcons.chevronRight,
                              size: 16, color: Color(0xFF0B3C5D)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: invite.isEmpty ? null : () => _copyCode(context),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(LucideIcons.share2,
                          size: 18, color: Color(0xFF94A3B8)),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;

  const _MiniInfo({
    required this.label,
    required this.value,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        )
      ],
    );
  }
}

/// ------------------------------------------------------------
/// ADD PROJECT DIALOG (Backend) + INDIAN STATES DROPDOWN
/// ------------------------------------------------------------
class AddProjectDialogBackend extends StatefulWidget {
  final String token;
  final Function(Map<String, dynamic>) onCreated;

  const AddProjectDialogBackend({
    super.key,
    required this.token,
    required this.onCreated,
  });

  @override
  State<AddProjectDialogBackend> createState() => _AddProjectDialogBackendState();
}

class _AddProjectDialogBackendState extends State<AddProjectDialogBackend> {
  static const String baseUrl = "http://10.0.2.2:5000/api";

  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController districtCtrl = TextEditingController();
  final TextEditingController talukaCtrl = TextEditingController();
  final TextEditingController amountCtrl = TextEditingController();

  String slab = "";
  String state = "";

  bool submitting = false;
  String error = "";

  static const List<String> indianStates = [
    "Andhra Pradesh",
    "Arunachal Pradesh",
    "Assam",
    "Bihar",
    "Chhattisgarh",
    "Goa",
    "Gujarat",
    "Haryana",
    "Himachal Pradesh",
    "Jharkhand",
    "Karnataka",
    "Kerala",
    "Madhya Pradesh",
    "Maharashtra",
    "Manipur",
    "Meghalaya",
    "Mizoram",
    "Nagaland",
    "Odisha",
    "Punjab",
    "Rajasthan",
    "Sikkim",
    "Tamil Nadu",
    "Telangana",
    "Tripura",
    "Uttar Pradesh",
    "Uttarakhand",
    "West Bengal",
    "Andaman and Nicobar Islands",
    "Chandigarh",
    "Dadra and Nagar Haveli and Daman and Diu",
    "Delhi",
    "Jammu and Kashmir",
    "Ladakh",
    "Lakshadweep",
    "Puducherry",
  ];

  double? _parseAmountCr() {
    final raw = amountCtrl.text.trim();
    if (raw.isEmpty) return null;

    // allow: 16.85 or 66
    return double.tryParse(raw);
  }

  Future<void> _createProject() async {
    final name = nameCtrl.text.trim();
    final district = districtCtrl.text.trim();
    final taluka = talukaCtrl.text.trim();
    final amountCr = _parseAmountCr();

    if (name.isEmpty || slab.isEmpty || state.isEmpty) {
      setState(() => error = "Please fill Project Name, State, and Slab.");
      return;
    }

    if (amountCr == null || amountCr <= 0) {
      setState(() => error = "Please enter Project Amount (in Cr). Example: 16.85");
      return;
    }

    setState(() {
      submitting = true;
      error = "";
    });

    try {
      final url = Uri.parse("$baseUrl/projects");
      final res = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
        body: jsonEncode({
          "projectName": name,
          "location": {
            "state": state,
            "district": district,
            "taluka": taluka,
            "addressLine": "",
          },
          "overview": {"slab": slab},
          "totalProjectCostCr": amountCr,
        }),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode >= 400) {
        setState(() {
          submitting = false;
          error = data["message"] ?? "Failed to create project";
        });
        return;
      }

      final createdProject = Map<String, dynamic>.from(data["project"]);
      widget.onCreated(createdProject);

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        submitting = false;
        error = "Network error: $e";
      });
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    districtCtrl.dispose();
    talukaCtrl.dispose();
    amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(14),
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    "Create New Project",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: submitting ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  )
                ],
              ),
              const SizedBox(height: 10),

              _label("Project Name *"),
              const SizedBox(height: 6),
              _field(nameCtrl, "e.g., ISKCON Mandir"),

              const SizedBox(height: 12),
              _label("State *"),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: state.isEmpty ? null : state,
                items: indianStates
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(
                            s,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => state = v ?? ""),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              _label("District"),
              const SizedBox(height: 6),
              _field(districtCtrl, "Mumbai Suburban"),

              const SizedBox(height: 12),
              _label("Taluka"),
              const SizedBox(height: 6),
              _field(talukaCtrl, "Andheri"),

              const SizedBox(height: 12),
              _label("Project Amount (₹ Cr) *"),
              const SizedBox(height: 6),
              _field(amountCtrl, "Example: 16.85", keyboard: TextInputType.number),

              const SizedBox(height: 12),
              _label("Project Slab *"),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: slab.isEmpty ? null : slab,
                items: const [
                  DropdownMenuItem(value: "0–20 Cr", child: Text("0–20 Cr")),
                  DropdownMenuItem(value: "20–100 Cr", child: Text("20–100 Cr")),
                  DropdownMenuItem(value: "100–300 Cr", child: Text("100–300 Cr")),
                  DropdownMenuItem(value: "300 Cr+", child: Text("300 Cr+")),
                ],
                onChanged: (v) => setState(() => slab = v ?? ""),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),

              if (error.isNotEmpty) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    error,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: submitting ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        "Cancel",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: submitting ? null : _createProject,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B3C5D),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: submitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              "Create Project",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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

  Widget _field(
    TextEditingController c,
    String hint, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: c,
      keyboardType: keyboard,
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