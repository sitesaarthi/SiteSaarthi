import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../services/api_config.dart';
import '../../../services/session_manager.dart';
import '../../../services/project_service.dart';
import '../../../services/dpr_service.dart';
import 'package:geolocator/geolocator.dart';

// ✅ Create DPR Page import (adjust if needed)
import '../../engineer/create_dpr_page.dart';
import '../../owner/docs/pdf_preview_page.dart';

class ProjectDetailsPage extends StatefulWidget {
  final Map<String, dynamic> project;

  const ProjectDetailsPage({
    super.key,
    required this.project,
  });

  @override
  State<ProjectDetailsPage> createState() => _ProjectDetailsPageState();
}

class _ProjectDetailsPageState extends State<ProjectDetailsPage> {
  final projectService = ProjectService();
  final dprService = DprService();

  bool teamLoading = false;
  List<Map<String, dynamic>> backendTeam = [];

  Map<String, dynamic> _siteMap() {
    return projectLive["siteView"]?["map"] ?? {};
  }

  bool dprLoading = false;
  List<Map<String, dynamic>> backendDprs = [];

  Map<String, dynamic> projectLive = {};

  String myRole = "";
  String myUserId = "";

  @override
  void initState() {
    super.initState();
    projectLive = Map<String, dynamic>.from(widget.project);

    _loadMe();
    _fetchDprs(); // ✅ load DPRs on open
  }

  Future<void> _loadMe() async {
    final u = await SessionManager.getUser();
    if (u != null) {
      myRole = (u["role"] ?? "").toString();
      myUserId = (u["_id"] ?? u["id"] ?? "").toString();
      setState(() {});
    }
  }

  String _projectName() =>
      (projectLive["projectName"] ?? projectLive["name"] ?? "Project")
          .toString();

  String _projectLocation() {
    final loc = projectLive["location"] ?? {};
    final taluka = (loc["taluka"] ?? "").toString();
    final district = (loc["district"] ?? "").toString();
    final state = (loc["state"] ?? "").toString();

    final parts =
        [taluka, district, state].where((e) => e.trim().isNotEmpty).toList();

    return parts.isEmpty ? "-" : parts.join(", ");
  }

  String _projectId() {
    if (projectLive["_id"] != null) return projectLive["_id"].toString();
    if (projectLive["id"] != null) return projectLive["id"].toString();
    return "";
  }

  List<dynamic> _dprUploaders() {
    return (projectLive["dprUploaders"] ?? []) as List<dynamic>;
  }

  List<Map<String, dynamic>> _docs() {
    final List list = (projectLive["docs"] ?? []) as List;
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /* ===================== DPR ===================== */

  Future<void> _fetchDprs() async {
    final pid = _projectId();
    if (pid.isEmpty) return;

    try {
      setState(() => dprLoading = true);
      backendDprs = await dprService.getProjectDprs(pid);
      setState(() => dprLoading = false);
    } catch (e) {
      setState(() => dprLoading = false);

      final msg = e.toString().toLowerCase();
      // ✅ No DPRs yet -> no error
      if (msg.contains("not found") ||
          msg.contains("no dprs") ||
          msg.contains("empty")) {
        backendDprs = [];
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load DPRs: $e")),
      );
    }
  }

  Future<void> _openAllDprPage() async {
    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AllDprsPage(projectId: _projectId()),
      ),
    );

    if (!mounted) return;
    _fetchDprs();
  }
  /* ===================== TEAM ===================== */

  Future<void> _fetchProjectMembersAndOpen() async {
    final projectId = _projectId();
    if (projectId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Project ID missing")),
      );
      return;
    }

    final token = await SessionManager.getToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Token missing. Login again.")),
      );
      return;
    }

    try {
      setState(() => teamLoading = true);

      final url = Uri.parse("${ApiConfig.baseUrl}/projects/$projectId/members");
      final res =
          await http.get(url, headers: {"Authorization": "Bearer $token"});

      if (!mounted) return;

      if (res.body.isEmpty) throw "Empty response from server";

      final data = jsonDecode(res.body);
      if (res.statusCode >= 400) {
        throw data["message"] ?? "Failed to load team";
      }

      backendTeam = (data["members"] as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      setState(() => teamLoading = false);

      if (!mounted) return;
      _openTeamSheetBackend();
    } catch (e) {
      if (!mounted) return;
      setState(() => teamLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Network error: $e")),
      );
    }
  }

  void _openTeamSheetBackend() async {
    final pid = _projectId();
    if (pid.isEmpty) return;

    final currentUploaders = _dprUploaders().map((e) => e.toString()).toList();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TeamBottomSheetOwner(
        team: backendTeam,
        projectId: pid,
        initialDprUploaderIds: currentUploaders,
        onSaved: (ids) {
          setState(() {
            projectLive["dprUploaders"] = ids;
          });
        },
      ),
    );
  }

  /* ===================== DOCS (keep your old flow) ===================== */

  Future<void> _refreshProjectLocalDocs(List<Map<String, dynamic>> docs) async {
    setState(() {
      projectLive["docs"] = docs;
    });
  }

  /* ===================== UI ===================== */

  @override
  Widget build(BuildContext context) {
    final shownDprs = backendDprs.take(2).toList();
    final hasBoundary = _siteMap().isNotEmpty;

    final w = MediaQuery.of(context).size.width;
    final isDesktop = w >= 980;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF8FAFC),
        surfaceTintColor: const Color(0xFFF8FAFC),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(LucideIcons.chevronLeft, size: 20),
          color: const Color(0xFF0F172A),
        ),
        title: Text(
          _projectName(),
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: const Color(0xFF0F172A),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.mapPin,
                          size: 16, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _projectLocation(),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              _ManageTeamButton(
                                onTap: teamLoading
                                    ? () {}
                                    : _fetchProjectMembersAndOpen,
                                loading: teamLoading,
                                subtitle: "Choose DPR upload engineers (max 3)",
                              ),
                              const SizedBox(height: 12),
                              _DprCard(
                                dprs: shownDprs,
                                onViewAll: _openAllDprPage,
                                loading: dprLoading,
                                canCreate: myRole.toUpperCase() == "ENGINEER",
                                onCreate: () async {
                                  final ok = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CreateDprPage(
                                        projectId: _projectId(),
                                        projectName: _projectName(),
                                      ),
                                    ),
                                  );
                                  if (ok == true) _fetchDprs();
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          flex: 1,
                          child: _ProjectHealthRiskCard(),
                        ),
                      ],
                    )
                  else ...[
                    _ManageTeamButton(
                      onTap: teamLoading ? () {} : _fetchProjectMembersAndOpen,
                      loading: teamLoading,
                      subtitle: "Choose DPR upload engineers (max 3)",
                    ),
                    const SizedBox(height: 12),
                    _DprCard(
                      dprs: shownDprs,
                      onViewAll: _openAllDprPage,
                      loading: dprLoading,
                      canCreate: myRole.toUpperCase() == "ENGINEER",
                      onCreate: () async {
                        final ok = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CreateDprPage(
                              projectId: _projectId(),
                              projectName: _projectName(),
                            ),
                          ),
                        );
                        if (ok == true) _fetchDprs();
                      },
                    ),
                    const SizedBox(height: 14),
                    const _ProjectHealthRiskCard(),
                  ],

                  const SizedBox(height: 14),

                  // ✅ DOCS CARD (OWNER)
                  _DocsCardOwner(
                    projectId: _projectId(),
                    docs: _docs(),
                    onUpdatedDocs: _refreshProjectLocalDocs,
                  ),

                  const SizedBox(height: 14),

                  // ✅ Removed Map/SiteView fully

                  _SiteViewMapCard(
                    projectId: _projectId(),
                    mapData: _siteMap(),
                    canEditBoundary:
                        myRole.toUpperCase() == "OWNER" && !hasBoundary,
                    onSaved: (updatedMap) {
                      setState(() {
                        projectLive["siteView"] ??= {};
                        projectLive["siteView"]["map"] = updatedMap;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  /// 👇 SAME UI AS YOUR PAGE
BigNavCard(
  title: "2D",
  icon: Icons.grid_view_rounded,
  gradient: const [Color(0xFF10B981), Color(0xFF047857)],
  onTap: () {
    print("Open 2D");
  },
),

BigNavCard(
  title: "3D",
  icon: Icons.view_in_ar_rounded,
  gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
  onTap: () {
    print("Open 3D");
  },
),

const SizedBox(height: 16),

                  if (myRole.toUpperCase() == "OWNER")
                    if (myRole.toUpperCase() == "OWNER")
                      EngineerRatingCard(
                        engineers: const [
                          {"id": "e1", "name": "Engineer 1"},
                          {"id": "e2", "name": "Engineer 2"},
                          {"id": "e3", "name": "Engineer 3"},
                        ],
                      ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EngineerRatingCard extends StatefulWidget {
  final List<Map<String, dynamic>> engineers;

  const EngineerRatingCard({
    super.key,
    required this.engineers,
  });

  @override
  State<EngineerRatingCard> createState() => _EngineerRatingCardState();
}

class _EngineerRatingCardState extends State<EngineerRatingCard> {
  String? selectedEngineerId;
  double get _finalScore {
    final total = ratings.values.fold(0.0, (a, b) => a + b);
    return total / ratings.length; // average → out of 10
  }

  final Map<String, double> ratings = {
    "Data Records & Documents": 0,
    "Payment Hours": 0,
    "Defects in Work": 0,
    "Time Management": 0,
    "Material Usage": 0,
  };

  final remarkCtrl = TextEditingController();
  bool saving = false;

  void _submitRating() async {
    if (selectedEngineerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select an engineer")),
      );
      return;
    }

    setState(() => saving = true);

    // ⏳ fake delay just for demo feel
    await Future.delayed(const Duration(milliseconds: 900));

    setState(() => saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Rating submitted ✅ Final Score: ${_finalScore.toStringAsFixed(1)} / 10",
        ),
      ),
    );

    // reset UI
    selectedEngineerId = null;
    remarkCtrl.clear();
    ratings.updateAll((key, value) => 0);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Rate Engineer (Demo)",
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedEngineerId,
            hint: const Text("Select Engineer"),
            items: widget.engineers.map((e) {
              return DropdownMenuItem(
                value: (e["_id"] ?? e["id"] ?? "").toString(),
                child: Text(e["name"] ?? "-"),
              );
            }).toList(),
            onChanged: (v) => setState(() => selectedEngineerId = v),
          ),
          const SizedBox(height: 16),
          ...ratings.keys.map(
            (k) => _RatingRow(
              label: k,
              value: ratings[k]!,
              onChanged: (v) => setState(() => ratings[k] = v),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                "Final Score:",
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${_finalScore.toStringAsFixed(1)} / 10",
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF15803D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: remarkCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: "Optional remarks (demo only)",
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: saving ? null : _submitRating,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B3C5D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text("Submit Rating"),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _RatingRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              Text(
                value.toStringAsFixed(1),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: 0,
            max: 10,
            divisions: 10,
            label: value.toStringAsFixed(1),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/* ============================================================
   MANAGE TEAM BUTTON
============================================================ */
class _ManageTeamButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool loading;
  final String subtitle;

  const _ManageTeamButton({
    required this.onTap,
    required this.loading,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            offset: Offset(0, 12),
            color: Color(0x0C000000),
          )
        ],
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFEDE9FE),
            borderRadius: BorderRadius.circular(14),
          ),
          child: loading
              ? const Padding(
                  padding: EdgeInsets.all(10),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF7C3AED),
                  ),
                )
              : const Icon(LucideIcons.users,
                  size: 18, color: Color(0xFF7C3AED)),
        ),
        title: Text(
          "Manage Team",
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF0F172A),
          ),
        ),
        subtitle: Text(
          loading ? "Loading members..." : subtitle,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF64748B),
          ),
        ),
        trailing: const Icon(LucideIcons.chevronRight,
            size: 18, color: Color(0xFF94A3B8)),
      ),
    );
  }
}

/* ============================================================
   DPR CARD
============================================================ */
class _DprCard extends StatelessWidget {
  final List<Map<String, dynamic>> dprs;
  final VoidCallback onViewAll;
  final bool loading;

  final bool canCreate;
  final VoidCallback? onCreate;

  const _DprCard({
    required this.dprs,
    required this.onViewAll,
    required this.loading,
    this.canCreate = false,
    this.onCreate,
  });

  String _dateText(Map<String, dynamic> dpr) {
    final iso = (dpr["date"] ?? "").toString();
    if (iso.isEmpty) return "-";
    return iso.length >= 10 ? iso.substring(0, 10) : iso;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            offset: Offset(0, 12),
            color: Color(0x0C000000),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Daily Progress Reports",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onViewAll,
                child: Text(
                  "View All",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ),
              if (canCreate) ...[
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: const Text("Create DPR"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B3C5D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (dprs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  "No DPRs submitted yet",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
            )
          else
            ...dprs.map((dpr) {
              final date = _dateText(dpr);
              final work = (dpr["workDone"] ?? dpr["work"] ?? "").toString();
              final issues = (dpr["issues"] ?? "").toString();
              final fileUrl = (dpr["fileUrl"] ?? "").toString();

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          date,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "SUBMITTED",
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF15803D),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (work.isNotEmpty)
                      Text(
                        work,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    if (issues.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        "Issues: $issues",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                    if (fileUrl.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PdfPreviewPage(
                                title: "DPR - $date",
                                pdfUrl: fileUrl,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(LucideIcons.fileText, size: 16),
                        label: const Text("View PDF"),
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      Text(
                        "PDF not available",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}

/* ============================================================
   TRUST SCORE
============================================================ */
class _ProjectHealthRiskCard extends StatelessWidget {
  const _ProjectHealthRiskCard();

  @override
  Widget build(BuildContext context) {
    const int trustScore = 88;
    const int dprScore = 95;
    const int materialScore = 82;

    const String delayRisk = "HIGH";
    const int delayMin = 4;
    const int delayMax = 6;
    const String lastUpdated = "14 Apr, 04:32 PM";

    const List<String> reasons = [
      "Missing DPRs (2 days)",
      "High defect reports",
    ];

    const String suggestion = "Increase manpower or review material supply";

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// HEADER
          Row(
            children: [
              const Icon(LucideIcons.shieldCheck,
                  size: 18, color: Color(0xFF0B3C5D)),
              const SizedBox(width: 8),
              Text(
                "Project Health & Risk",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "AI Insights",
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Updated $lastUpdated",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              )
            ],
          ),

          const SizedBox(height: 16),

          /// TRUST SCORE
          Row(
            children: [
              Text(
                "Trust Score",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: trustScore >= 80
                      ? const Color(0xFFDCFCE7)
                      : trustScore >= 50
                          ? const Color(0xFFFEF9C3)
                          : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "$trustScore / 100",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          /// HEALTH SIGNALS
          Text(
            "Health Signals",
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 10),

          _ScoreBar(label: "DPR Consistency", score: dprScore),
          const SizedBox(height: 10),
          _ScoreBar(label: "Material Accuracy", score: materialScore),

          const SizedBox(height: 16),
          const Divider(height: 1),

          const SizedBox(height: 12),

          /// DELAY RISK
          Row(
            children: [
              Text(
                "Delay Risk",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: delayRisk == "HIGH"
                      ? const Color(0xFFFEE2E2)
                      : delayRisk == "MEDIUM"
                          ? const Color(0xFFFEF9C3)
                          : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  delayRisk,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          /// EXPECTED DELAY
          Text(
            "Expected Delay: $delayMin–$delayMax days",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),

          const SizedBox(height: 14),

          /// REASONS
          Text(
            "Key Factors",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
            ),
          ),

          const SizedBox(height: 6),

          ...reasons.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(LucideIcons.dot,
                      size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      r,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          /// SUGGESTION
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.lightbulb,
                    size: 16, color: Color(0xFF2563EB)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    suggestion,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final String label;
  final int score;

  const _ScoreBar({required this.label, required this.score});

  @override
  Widget build(BuildContext context) {
    final double pct = score.clamp(0, 100).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFCBD5E1),
                ),
              ),
            ),
            Text(
              "$pct%",
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: pct / 100.0,
            minHeight: 7,
            backgroundColor: Colors.white.withOpacity(0.12),
          ),
        ),
      ],
    );
  }
}

/* ============================================================
   DOCS CARD (OWNER) -> SAME AS BEFORE
============================================================ */
class _DocsCardOwner extends StatefulWidget {
  final String projectId;
  final List<Map<String, dynamic>> docs;
  final Future<void> Function(List<Map<String, dynamic>> docs) onUpdatedDocs;

  const _DocsCardOwner({
    required this.projectId,
    required this.docs,
    required this.onUpdatedDocs,
  });

  @override
  State<_DocsCardOwner> createState() => _DocsCardOwnerState();
}

class _DocsCardOwnerState extends State<_DocsCardOwner> {
  final projectService = ProjectService();
  bool saving = false;

  Future<void> _uploadDoc(Map<String, dynamic> doc) async {
    final key = (doc["key"] ?? "").toString();
    final title = (doc["title"] ?? key).toString();

    final ctrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Upload: $title"),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: "Paste file URL (pdf/image)",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final url = ctrl.text.trim();
              if (url.isEmpty) return;

              Navigator.pop(context);

              try {
                setState(() => saving = true);
                final res = await projectService.uploadDoc(
                  projectId: widget.projectId,
                  key: key,
                  url: url,
                );

                final List list = (res["docs"] ?? []) as List;
                final updatedDocs =
                    list.map((e) => Map<String, dynamic>.from(e)).toList();
                await widget.onUpdatedDocs(updatedDocs);

                setState(() => saving = false);

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Doc uploaded ✅")),
                );
              } catch (e) {
                setState(() => saving = false);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Upload failed: $e")),
                );
              }
            },
            child: const Text("Upload"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final docs = widget.docs;

    final initDocs = docs.where((d) => (d["stage"] ?? "") == "INIT").toList();
    final laterDocs = docs.where((d) => (d["stage"] ?? "") == "LATER").toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Project Documents",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              if (saving)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _DocGroup(
            title: "Mandatory (Upload once)",
            docs: initDocs,
            onUpload: _uploadDoc,
          ),
          const SizedBox(height: 14),
          _DocGroup(
            title: "Execution Docs",
            docs: laterDocs,
            onUpload: _uploadDoc,
          ),
        ],
      ),
    );
  }
}

class _DocGroup extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> docs;
  final Future<void> Function(Map<String, dynamic> doc) onUpload;

  const _DocGroup({
    required this.title,
    required this.docs,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 10),
        ...docs.map((doc) {
          final t = (doc["title"] ?? doc["key"] ?? "-").toString();
          final uploaded = (doc["uploaded"] ?? false) == true;
          final url = (doc["url"] ?? "").toString();

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Icon(
                  uploaded ? LucideIcons.fileCheck2 : LucideIcons.fileX2,
                  size: 18,
                  color: uploaded
                      ? const Color(0xFF16A34A)
                      : const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        uploaded ? "Uploaded" : "Not uploaded",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      if (uploaded && url.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          url,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (!uploaded)
                  ElevatedButton(
                    onPressed: () => onUpload(doc),
                    child: const Text("Upload"),
                  )
                else
                  const Icon(LucideIcons.lock,
                      size: 16, color: Color(0xFF94A3B8)),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}

/* ============================================================
   ✅ TEAM BOTTOMSHEET OWNER (FULL PROPER)
============================================================ */
class _TeamBottomSheetOwner extends StatefulWidget {
  final List<Map<String, dynamic>> team;
  final String projectId;
  final List<String> initialDprUploaderIds;
  final void Function(List<String>) onSaved;

  const _TeamBottomSheetOwner({
    required this.team,
    required this.projectId,
    required this.initialDprUploaderIds,
    required this.onSaved,
  });

  @override
  State<_TeamBottomSheetOwner> createState() => _TeamBottomSheetOwnerState();
}

class _TeamBottomSheetOwnerState extends State<_TeamBottomSheetOwner> {
  final projectService = ProjectService();

  late List<String> selectedUploaderIds;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    selectedUploaderIds = List<String>.from(widget.initialDprUploaderIds);
  }

  Color _roleColor(String role) {
    switch (role.toUpperCase()) {
      case "OWNER":
        return const Color(0xFF0B3C5D);
      case "MANAGER":
        return const Color(0xFF7C3AED);
      case "ENGINEER":
        return const Color(0xFF2563EB);
      case "CLIENT":
        return const Color(0xFF16A34A);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final engineers = widget.team
        .where((m) => (m["role"] ?? "").toString().toUpperCase() == "ENGINEER")
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 46,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Text(
                  "Project Team",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 0),

          /* ✅ DPR Permission box */
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.fileText,
                          size: 18, color: Color(0xFF2563EB)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "DPR Upload Permission (max 3 engineers)",
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      if (saving)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (engineers.isEmpty)
                    Text(
                      "No engineers in project",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF64748B),
                      ),
                    )
                  else
                    Column(
                      children: engineers.map((m) {
                        // ✅ FIX: backend usually gives _id not id
                        final id = (m["_id"] ?? m["id"] ?? "").toString();
                        final name = (m["name"] ?? "-").toString();
                        final checked = selectedUploaderIds.contains(id);

                        return CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          value: checked,
                          title: Text(
                            name,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          subtitle: Text(
                            checked ? "Can upload DPR" : "View only",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          onChanged: (v) {
                            if (v == true) {
                              if (selectedUploaderIds.length >= 3) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("Max 3 engineers allowed")),
                                );
                                return;
                              }
                              setState(() => selectedUploaderIds.add(id));
                            } else {
                              setState(() => selectedUploaderIds.remove(id));
                            }
                          },
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saving
                          ? null
                          : () async {
                              try {
                                setState(() => saving = true);

                                await projectService.setDprUploaders(
                                  projectId: widget.projectId,
                                  uploaderIds: selectedUploaderIds,
                                );

                                setState(() => saving = false);

                                widget.onSaved(selectedUploaderIds);

                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Saved ✅")),
                                );
                              } catch (e) {
                                setState(() => saving = false);
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Save failed: $e")),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B3C5D),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text("Save Permission"),
                    ),
                  )
                ],
              ),
            ),
          ),

          /* ✅ Team list */
          Expanded(
            child: widget.team.isEmpty
                ? Center(
                    child: Text(
                      "No members found",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: widget.team.length,
                    itemBuilder: (context, index) {
                      final m = widget.team[index];

                      final name = (m["name"] ?? "-").toString();
                      final role = (m["role"] ?? "MEMBER").toString();
                      final phone = (m["phone"] ?? "").toString();
                      final col = _roleColor(role);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: col.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : "?",
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: col,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  if (phone.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      phone,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: col.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: Text(
                                      role.toUpperCase(),
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: col,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
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
    );
  }
}

/* ============================================================
   ALL DPR PAGE
============================================================ */
class AllDprsPage extends StatefulWidget {
  final String projectId;

  const AllDprsPage({super.key, required this.projectId});

  @override
  State<AllDprsPage> createState() => _AllDprsPageState();
}

class _AllDprsPageState extends State<AllDprsPage> {
  final dprService = DprService();
  bool loading = true;
  List<Map<String, dynamic>> dprs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() => loading = true);
      dprs = await dprService.getProjectDprs(widget.projectId);
      setState(() => loading = false);
    } catch (e) {
      setState(() => loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Load failed: $e")),
      );
    }
  }

  String _date(Map<String, dynamic> dpr) {
    final raw = (dpr["date"] ?? "").toString();
    if (raw.isEmpty) return "-";
    try {
      final dt = DateTime.parse(raw);
      return DateFormat("dd MMM yyyy").format(dt);
    } catch (_) {
      return raw.length >= 10 ? raw.substring(0, 10) : raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        title: Text(
          "All DPRs",
          style: GoogleFonts.inter(fontWeight: FontWeight.w900),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : dprs.isEmpty
              ? Center(
                  child: Text(
                    "No DPRs yet",
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: dprs.length,
                  itemBuilder: (_, i) {
                    final d = dprs[i];
                    final work = (d["workDone"] ?? "").toString();
                    final issues = (d["issues"] ?? "").toString();
                    final fileUrl = (d["fileUrl"] ?? "").toString();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _date(d),
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (work.isNotEmpty)
                            Text(work,
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700)),
                          if (issues.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              "Issues: $issues",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                          if (fileUrl.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PdfPreviewPage(
                                      title: "DPR - ${_date(d)}",
                                      pdfUrl: fileUrl,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(LucideIcons.fileText, size: 16),
                              label: const Text("View PDF"),
                            ),
                          ]
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

class _SiteViewMapCard extends StatefulWidget {
  final String projectId;
  final Map<String, dynamic> mapData;
  final bool canEditBoundary; // ✅ NEW
  final void Function(Map<String, dynamic>) onSaved;

  const _SiteViewMapCard({
    required this.projectId,
    required this.mapData,
    required this.canEditBoundary,
    required this.onSaved,
  });

  @override
  State<_SiteViewMapCard> createState() => _SiteViewMapCardState();
}

class _SiteViewMapCardState extends State<_SiteViewMapCard> {
  GoogleMapController? _controller;

  late LatLng center;
  double radius = 200;
  double zoom = 16;

  bool saving = false;

  @override
  void initState() {
    super.initState();
    center = LatLng(
      (widget.mapData["centerLat"] ?? 19.0760).toDouble(),
      (widget.mapData["centerLng"] ?? 72.8777).toDouble(),
    );
    radius = ((widget.mapData["radiusMeters"] ?? 200) as num).toDouble();
    zoom = ((widget.mapData["zoom"] ?? 16) as num).toDouble();
  }

  void _goToProjectPin() {
    _controller?.animateCamera(
      CameraUpdate.newLatLngZoom(center, zoom),
    );
  }

  Future<void> _enableLocationAndMove() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final latLng = LatLng(pos.latitude, pos.longitude);

      _controller?.animateCamera(
        CameraUpdate.newLatLngZoom(latLng, 16),
      );
    }
  }

  Future<void> _save() async {
    try {
      setState(() => saving = true);

      await ProjectService().updateMapBoundary(
        projectId: widget.projectId,
        centerLat: center.latitude,
        centerLng: center.longitude,
        radiusMeters: radius, // ✅ double
      );

      if (!mounted) return;

      widget.onSaved({
        "centerLat": center.latitude,
        "centerLng": center.longitude,
        "radiusMeters": radius.round(),
        "zoom": zoom,
      });

      setState(() => saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Site location saved ✅")),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Save failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.map),
              const SizedBox(width: 8),
              Text(
                "Site Location",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              if (saving)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 260,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: center,
                  zoom: zoom,
                ),
                onMapCreated: (c) => _controller = c,
                zoomGesturesEnabled: true,
                scrollGesturesEnabled: true,
                rotateGesturesEnabled: true,
                tiltGesturesEnabled: true,
                zoomControlsEnabled: true,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                onCameraMove: (pos) => zoom = pos.zoom,
                onTap: widget.canEditBoundary
                    ? (latLng) => setState(() => center = latLng)
                    : null,
                markers: {
                  Marker(
                    markerId: const MarkerId("center"),
                    position: center,
                  ),
                },
                circles: widget.canEditBoundary
                    ? {
                        Circle(
                          circleId: const CircleId("radius"),
                          center: center,
                          radius: radius,
                          strokeWidth: 2,
                          strokeColor: Colors.blue,
                          fillColor: Colors.blue.withOpacity(0.15),
                        ),
                      }
                    : {},
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (widget.canEditBoundary)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saving ? null : _save,
                child: const Text("Save Site Boundary"),
              ),
            ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _goToProjectPin,
              icon: const Icon(LucideIcons.mapPin),
              label: const Text("Go to site location"),
            ),
          ),
        ],
      ),
    );
  }
}

/// ================= CARD =================
class BigNavCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final List<Color> gradient;

  const BigNavCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        height: 150,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradient.last.withOpacity(0.3), // ✅ fixed shadow
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Row(
          children: [
            /// ICON
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2), // ✅ fixed
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: Colors.white),
            ),

            const SizedBox(width: 16),

            /// TEXT
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Open $title View",
                  style: const TextStyle(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),

            const Spacer(),

            /// ARROW
            const Icon(Icons.arrow_forward_ios, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

