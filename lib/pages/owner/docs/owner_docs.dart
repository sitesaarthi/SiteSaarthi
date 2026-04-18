import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../routes.dart';

class OwnerDocsPage extends StatefulWidget {
  const OwnerDocsPage({super.key});

  @override
  State<OwnerDocsPage> createState() => _OwnerDocsPageState();
}

class _OwnerDocsPageState extends State<OwnerDocsPage> {
  static const String baseUrl = "http://10.0.2.2:5000/api";

  List<Map<String, dynamic>> projects = [];
  String? selectedProjectId;

  bool loading = true;
  String errorMsg = "";

  @override
  void initState() {
    super.initState();
    _fetchProjects();
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("authToken") ?? "";
  }

  Future<void> _fetchProjects() async {
    final token = await _getToken();

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

      setState(() {
        projects = mapped;
        if (projects.isNotEmpty) {
          selectedProjectId =
              (projects.first["_id"] ?? projects.first["id"]).toString();
        }
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        errorMsg = "Network error: $e";
      });
    }
  }

  String _projectIdOf(Map<String, dynamic> p) {
    if (p["_id"] != null) return p["_id"].toString();
    if (p["id"] != null) return p["id"].toString();
    return "";
  }

  String _projectNameOf(Map<String, dynamic> p) {
    return (p["projectName"] ?? p["name"] ?? "-").toString();
  }

  Future<void> _openDocPage(String route, String projectId) async {
  final changed = await Navigator.pushNamed(
    context,
    route,
    arguments: {"projectId": projectId},
  );

  if (changed == true) {
    _fetchProjects(); // ✅ refresh the docs screen
  }
}


  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final cols = width >= 720 ? 2 : 1;

    // ✅ LOADING
    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF0B3C5D)),
        ),
      );
    }

    // ✅ ERROR
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
                Text(
                  "Failed to load projects",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  errorMsg,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: const Color(0xFF64748B),
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

    // ✅ NO PROJECTS
    if (projects.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Text(
            "No projects found.\nCreate a project first.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF64748B),
            ),
          ),
        ),
      );
    }

    final selectedProject = projects.firstWhere(
      (p) => _projectIdOf(p) == selectedProjectId,
      orElse: () => projects.first,
    );

    final projectId = _projectIdOf(selectedProject);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ HEADER
              Text(
                "Paperwork & Billing",
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Manage all financial & compliance documents from one place",
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                ),
              ),

              const SizedBox(height: 14),

              // ✅ PROJECT SELECTOR
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.apartment_rounded,
                        size: 18, color: Color(0xFF64748B)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedProjectId,
                          isExpanded: true,
                          items: projects.map((p) {
                            final id = _projectIdOf(p);
                            final name = _projectNameOf(p);

                            return DropdownMenuItem<String>(
                              value: id,
                              child: Text(
                                name,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() => selectedProjectId = v);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ✅ GRID (SAME UX)
              GridView.count(
                crossAxisCount: cols,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.8,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // ✅ INIT docs (manual upload by Owner)
                  PaperCard(
                    title: "RERA Certificate",
                    desc: "Upload official RERA certificate PDF",
                    icon: Icons.verified_user_rounded,
                    bg: const Color(0xFFEFF6FF),
                    fg: const Color(0xFF2563EB),
                    ctaText: "Open →",
                    onTap: () =>
                        _openDocPage(AppRoutes.ownerDocsRera, projectId),
                  ),

                  PaperCard(
                    title: "IOD",
                    desc: "Upload IOD document PDF",
                    icon: Icons.assignment_rounded,
                    bg: const Color(0xFFFFFBEB),
                    fg: const Color(0xFFD97706),
                    ctaText: "Open →",
                    onTap: () =>
                        _openDocPage(AppRoutes.ownerDocsIod, projectId),
                  ),

                  PaperCard(
                    title: "Commencement Certificate (CC)",
                    desc: "Upload Commencement certificate PDF",
                    icon: Icons.approval_rounded,
                    bg: const Color(0xFFECFDF5),
                    fg: const Color(0xFF059669),
                    ctaText: "Open →",
                    onTap: () => _openDocPage(AppRoutes.ownerDocsCc, projectId),
                  ),

                  // ✅ LATER docs (auto-generate)
                  PaperCard(
                    title: "Proposal Report",
                    desc: "Generate proposal + report PDF",
                    icon: Icons.description_rounded,
                    bg: const Color(0xFFEEF2FF),
                    fg: const Color(0xFF4F46E5),
                    ctaText: "Open →",
                    onTap: () => _openDocPage(AppRoutes.ownerDocsProposal, projectId),

                  ),
                  PaperCard(
                    title: "Quotation",
                    desc: "Generate quotation PDF",
                    icon: Icons.request_quote_rounded,
                    bg: const Color(0xFFFFF1F2),
                    fg: const Color(0xFFDC2626),
                    ctaText: "Open →",
                    onTap: () => _openDocPage(AppRoutes.ownerDocsQuotation, projectId),

                  ),
                  PaperCard(
                    title: "Material Order",
                    desc: "Generate material order PDF",
                    icon: Icons.shopping_cart_rounded,
                    bg: const Color(0xFFF1F5F9),
                    fg: const Color(0xFF0B3C5D),
                    ctaText: "Open →",
                    onTap: () => _openDocPage(AppRoutes.ownerDocsPurchaseOrder, projectId),

                  ),
                  PaperCard(
                    title: "GST Invoice",
                    desc: "Generate GST invoice PDF",
                    icon: Icons.receipt_long_rounded,
                    bg: const Color(0xFFEFF6FF),
                    fg: const Color(0xFF2563EB),
                    ctaText: "Open →",
                    onTap: () => _openDocPage(AppRoutes.ownerDocsGstInvoice, projectId),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ============================================================
/// ✅ CARD COMPONENT (SAME STYLE)
// ============================================================
class PaperCard extends StatelessWidget {
  final String title;
  final String desc;
  final IconData icon;
  final Color bg;
  final Color fg;
  final String ctaText;
  final VoidCallback onTap;

  const PaperCard({
    super.key,
    required this.title,
    required this.desc,
    required this.icon,
    required this.bg,
    required this.fg,
    required this.ctaText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 14,
              offset: Offset(0, 8),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: fg, size: 22),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                desc,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                ),
              ),
              const Spacer(),
              Text(
                ctaText,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
