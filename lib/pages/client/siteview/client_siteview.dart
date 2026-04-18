import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../routes.dart';
import 'client_rera_page.dart';
import 'pdf_viewer_page.dart';

class ClientSiteViewPage extends StatefulWidget {
  const ClientSiteViewPage({super.key});

  @override
  State<ClientSiteViewPage> createState() => _ClientSiteViewPageState();
}

class _ClientSiteViewPageState extends State<ClientSiteViewPage> {
  static const String baseUrl = "http://10.0.2.2:5000/api";

  bool loading = true;
  String errorMsg = "";

  String token = "";

  List<Map<String, dynamic>> projects = [];
  String? selectedProjectId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadAuth();
    await _fetchProjects();
  }

  Future<void> _loadAuth() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("authToken") ?? "";
  }

  String _projectIdOf(Map<String, dynamic> p) {
    if (p["_id"] != null) return p["_id"].toString();
    if (p["id"] != null) return p["id"].toString();
    return "";
  }

  String _projectNameOf(Map<String, dynamic> p) {
    return (p["projectName"] ?? p["name"] ?? "-").toString();
  }

  List<Map<String, dynamic>> _uniqueProjects(List<Map<String, dynamic>> list) {
    final seen = <String>{};
    final out = <Map<String, dynamic>>[];

    for (final p in list) {
      final id = _projectIdOf(p);
      if (id.isEmpty) continue;
      if (seen.add(id)) out.add(p);
    }
    return out;
  }

  Future<void> _fetchProjects({bool silent = false}) async {
    if (token.isEmpty) {
      setState(() {
        loading = false;
        errorMsg = "Token missing. Please login again.";
      });
      return;
    }

    try {
      if (!silent) {
        setState(() {
          loading = true;
          errorMsg = "";
          projects = [];
        });
      } else {
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

      setState(() {
        projects = List<Map<String, dynamic>>.from(unique);

        if (projects.isNotEmpty) {
          selectedProjectId ??= _projectIdOf(projects.first);
        } else {
          selectedProjectId = null;
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
          await _fetchProjects(silent: true);
        },
      ),
    );
  }

  void _openRoute(String route) {
    if (selectedProjectId == null || selectedProjectId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Join or select a project first")),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      route,
      arguments: {"projectId": selectedProjectId},
    );
  }

  @override
  Widget build(BuildContext context) {
    /// ✅ LOADING
    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF0B3C5D)),
        ),
      );
    }

    /// ✅ ERROR
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

    /// ✅ UI
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // ✅ TOP STRIP (dropdown + join)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedProjectId,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
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
                                  fontWeight: FontWeight.w900,
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
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _openJoinModal,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text(
                      "Join",
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),

            // ✅ Cards
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  _BigNavCard(
                    title: "RERA Preview",
                    icon: Icons.verified_user_rounded,
                    gradient: [Color(0xFF6366F1), Color(0xFF4338CA)], // Indigo
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ClientReraPage(),
                        ),
                      );
                    },
                  ),
                  _BigNavCard(
                    title: "MAP",
                    icon: Icons.map_rounded,
                    gradient: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                    onTap: () => _openRoute(AppRoutes.clientMapView),
                  ),
                  _BigNavCard(
                    title: "2D",
                    icon: Icons.grid_view_rounded,
                    gradient: [Color(0xFF10B981), Color(0xFF047857)],
                    onTap: () => _openRoute(AppRoutes.client2DView),
                  ),
                  _BigNavCard(
                    title: "3D",
                    icon: Icons.view_in_ar_rounded,
                    gradient: [Color(0xFFF59E0B), Color(0xFFD97706)],
                    onTap: () => _openRoute(AppRoutes.client3DView),
                  ),
                  _BigNavCard(
                    title: "Weekly Progress Report",
                    icon: Icons.account_balance_wallet_rounded,
                    gradient: [Color(0xFF22C55E), Color(0xFF15803D)], // Green
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PdfViewerPage(
                            path: "assets/reports/weekly.pdf",
                          ),
                        ),
                      );
                    },
                  ),
                  _BigNavCard(
                    title: "Quatarly REPORT",
                    icon: Icons.analytics_rounded,
                    gradient: [Color(0xFFEF4444), Color(0xFFB91C1C)], // Red
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PdfViewerPage(
                            path: "assets/reports/qpr.pdf",
                          ),
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
}

/// ============================================================
/// JOIN MODAL (SAME AS ENGINEER)
// ============================================================
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
      // ✅ SAME as engineer
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
    } finally {
      if (mounted) setState(() => joining = false);
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

/// ============================================================
/// BIG NAV CARD
/// ============================================================
class _BigNavCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final List<Color> gradient;

  const _BigNavCard({
    required this.title,
    required this.icon,
    required this.onTap,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        height: 160,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradient.last.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Row(
          children: [
            // ICON CONTAINER
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: Colors.white),
            ),

            const SizedBox(width: 16),

            // TEXT
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Open $title View",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ],
            ),

            const Spacer(),

            const Icon(Icons.arrow_forward_ios, color: Colors.white)
          ],
        ),
      ),
    );
  }
}
