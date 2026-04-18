import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../projects/project_details_page.dart';
import '../../../l10n/app_localizations.dart';

import '../../../../routes.dart'; // ✅ for navigation if you use AppRoutes

class OwnerDashboardPage extends StatefulWidget {
  const OwnerDashboardPage({super.key});

  @override
  State<OwnerDashboardPage> createState() => _OwnerDashboardPageState();
}

class _OwnerDashboardPageState extends State<OwnerDashboardPage> {
  static const String baseUrl = "http://10.0.2.2:5000/api";

  bool isLoading = true;
  String errorMsg = "";

  String token = "";
  Map<String, dynamic>? authUser;

  List<Map<String, dynamic>> projects = [];

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
    final raw = prefs.getString("authUser");
    if (raw != null) authUser = jsonDecode(raw);
  }

  Future<void> _fetchProjects() async {
    if (token.isEmpty) {
      setState(() {
        isLoading = false;
        errorMsg = "Token missing. Please login again.";
      });
      return;
    }

    try {
      setState(() {
        isLoading = true;
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

      print("PROJECT API RESPONSE: ${res.body}");

      if (res.body.isEmpty) throw "Empty response from server";

      final data = jsonDecode(res.body);

      if (res.statusCode >= 400) {
        setState(() {
          isLoading = false;
          errorMsg = data["message"] ?? "Failed to load dashboard";
        });
        return;
      }

      final List list = (data["projects"] ?? []) as List;
      final mapped = list.map((e) => Map<String, dynamic>.from(e)).toList();

      setState(() {
        projects = mapped;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMsg = "Network error: $e";
      });
    }
  }

  // ------------------------------------------------------------
  // Helpers to calculate status
  // ------------------------------------------------------------

  int _membersCount(Map<String, dynamic> p) {
    final managers = (p["managers"] is List) ? (p["managers"] as List) : [];
    final engineers = (p["engineers"] is List) ? (p["engineers"] as List) : [];
    final clients = (p["clients"] is List) ? (p["clients"] as List) : [];

    return managers.length + engineers.length + clients.length + 1;
  }

  String _projectLocation(Map<String, dynamic> p) {
    final locRaw = p["location"];

    if (locRaw is! Map) return "-"; // ✅ prevents crash

    final loc = Map<String, dynamic>.from(locRaw);

    final state = (loc["state"] ?? "").toString();
    final district = (loc["district"] ?? "").toString();
    final taluka = (loc["taluka"] ?? "").toString();

    final parts =
        [taluka, district, state].where((e) => e.trim().isNotEmpty).toList();

    return parts.isEmpty ? "-" : parts.join(", ");
  }

  // ✅ until DPR/material backend arrives, we keep "attention" logic simple
  // - Attention if no engineers OR no clients
  // - You can change later
  List<Map<String, dynamic>> get projectStatus {
    return projects.map((p) {
      final engineers = (p["engineers"] ?? []) as List;
      final clients = (p["clients"] ?? []) as List;

      // Dummy progress now
      final progress = (p["progress"] ?? 0) is int ? p["progress"] : 40;

      final attention = engineers.isEmpty || clients.isEmpty;

      return {
        ...p,
        "name": (p["projectName"] ?? "-").toString(),
        "locationStr": _projectLocation(p),
        "progress": progress,
        "membersCount": _membersCount(p),
        "attention": attention,
      };
    }).toList();
  }

  Map<String, int> get stats {
    final total = projectStatus.length;
    final attention = projectStatus.where((p) => p["attention"] == true).length;
    final onTrack = total - attention;

    return {
      "active": total,
      "onTrack": onTrack,
      "needAttention": attention,
      "pendingRequests": 0, // will connect later
    };
  }

  void _openProjectsPage() {
    // ✅ route to your project listing page
    Navigator.pushNamed(context, AppRoutes.ownerProjects);
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF0B3C5D)),
        ),
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
                Text(
                  t.dashboardLoadFailed,
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
                  label: Text(t.retry),
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

    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ TOP HEADER
            Text(
              t.dashboard,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              t.dashboardSubtitle,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 14),

            // ✅ ALERT BANNER
            if (stats["needAttention"]! > 0)
              _AlertBanner(
                title: "${stats["needAttention"]} ${t.projectsNeedAttention}",
                subtitle: t.teamNotComplete,
                positive: false,
              )
            else
              _AlertBanner(
                title: t.allProjectsOnTrack,
                subtitle: t.noPendingActions,
                positive: true,
              ),

            const SizedBox(height: 14),

            // ✅ KPI CARDS
            GridView.count(
              crossAxisCount: isWide ? 4 : 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.85,
              children: [
                _KpiCard(
                  title: t.activeProjects,
                  value: stats["active"]!,
                  icon: Icons.apartment_rounded,
                  bg: const Color(0xFFEFF6FF),
                  fg: const Color(0xFF2563EB),
                ),
                _KpiCard(
                  title: t.onTrack,
                  value: stats["onTrack"]!,
                  icon: Icons.check_circle_rounded,
                  bg: const Color(0xFFECFDF5),
                  fg: const Color(0xFF16A34A),
                ),
                _KpiCard(
                  title: t.needAttention,
                  value: stats["needAttention"]!,
                  icon: Icons.warning_amber_rounded,
                  bg: const Color(0xFFFFFBEB),
                  fg: const Color(0xFFD97706),
                ),
                _KpiCard(
                  title: t.pendingRequests,
                  value: stats["pendingRequests"]!,
                  icon: Icons.inventory_2_rounded,
                  bg: const Color(0xFFEEF2FF),
                  fg: const Color(0xFF4F46E5),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ✅ PROJECTS SECTION
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t.projects,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                TextButton(
                  onPressed: _openProjectsPage,
                  child: Text(
                    t.viewAll,
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                )
              ],
            ),

            const SizedBox(height: 10),

            // ✅ PROJECT LIST
            if (projectStatus.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    t.noProjectsFound,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              )
            else
              Column(
                children: projectStatus
                    .take(6) // show few
                    .map((p) => _ProjectRow(p: p))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// Widgets
// ------------------------------------------------------------

class _AlertBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool positive;

  const _AlertBanner({
    required this.title,
    required this.subtitle,
    required this.positive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: positive ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: positive ? const Color(0xFFBBF7D0) : const Color(0xFFFFE08A),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color:
                  positive ? const Color(0xFFDCFCE7) : const Color(0xFFFFEDD5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              positive ? Icons.check_rounded : Icons.warning_amber_rounded,
              color:
                  positive ? const Color(0xFF16A34A) : const Color(0xFFD97706),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final int value;
  final IconData icon;
  final Color bg;
  final Color fg;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: fg),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _ProjectRow extends StatelessWidget {
  final Map p;
  const _ProjectRow({required this.p});

  @override
  Widget build(BuildContext context) {
    final bool attention = p["attention"] == true;
    final t = AppLocalizations.of(context)!;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProjectDetailsPage(
              project: Map<String, dynamic>.from(p),
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            // icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: attention
                    ? const Color(0xFFFFE4E6)
                    : const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                attention ? Icons.error_rounded : Icons.check_rounded,
                color: attention
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF16A34A),
              ),
            ),
            const SizedBox(width: 12),

            // main
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p["name"] ?? "-",
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    p["locationStr"] ?? "-",
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: ((p["progress"] ?? 0) as int) / 100,
                      minHeight: 7,
                      backgroundColor: const Color(0xFFE5E7EB),
                      color: attention
                          ? const Color(0xFFF97316)
                          : const Color(0xFF16A34A),
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(width: 10),

            // right
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${p["progress"] ?? 0}%",
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: attention
                        ? const Color(0xFFFFE4E6)
                        : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    attention ? t.attention : t.onTrack,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 0.6,
                      color: attention
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF16A34A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}
