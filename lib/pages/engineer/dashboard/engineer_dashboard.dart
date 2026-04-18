import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class EngineerDashboardPage extends StatefulWidget {
  const EngineerDashboardPage({super.key});

  @override
  State<EngineerDashboardPage> createState() =>
      _EngineerDashboardPageState();
}

class _EngineerDashboardPageState extends State<EngineerDashboardPage> {
  static const String baseUrl = "http://10.0.2.2:5000/api";

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
      final mapped =
          list.map((e) => Map<String, dynamic>.from(e)).toList();

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

  List<Map<String, dynamic>> get dashboardProjects {
    return projects.map((p) {
      return {...p, "status": "On Track"};
    }).toList();
  }

  int get onTrack =>
      dashboardProjects.where((p) => p["status"] == "On Track").length;

  int get attention =>
      dashboardProjects.where((p) => p["status"] == "Attention Needed").length;

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
        body: Center(child: Text(errorMsg)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
              Text(
                "Dashboard 👷‍♂️",
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    "Shift started at 08:30 AM",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              /// UTILIZATION CARD
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("UTILIZATION",
                        style: TextStyle(color: Colors.white70)),
                    SizedBox(height: 8),
                    Text("92%",
                        style: TextStyle(
                            fontSize: 36,
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: 0.92,
                      color: Colors.white,
                      backgroundColor: Colors.white24,
                    )
                  ],
                ),
              ),

              const SizedBox(height: 24),

              /// STATS GRID
              GridView.builder(
                itemCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.3,
                ),
                itemBuilder: (context, index) {
                  final items = [
                    ("On Track", onTrack.toString(), Icons.check_circle,
                        Color(0xFFDCFCE7), Color(0xFF16A34A)),
                    ("Attention", attention.toString(), Icons.warning,
                        Color(0xFFFFEDD5), Color(0xFFF97316)),
                    ("Projects",
                        dashboardProjects.length.toString(),
                        Icons.grid_view,
                        Color(0xFFDBEAFE),
                        Color(0xFF2563EB)),
                    ("Quality", "✓", Icons.verified,
                        Color(0xFFE0F2FE), Color(0xFF0284C7)),
                  ];

                  final item = items[index];

                  return StatCard(
                    title: item.$1,
                    value: item.$2,
                    icon: item.$3,
                    bg: item.$4,
                    fg: item.$5,
                  );
                },
              ),

              const SizedBox(height: 24),

              /// ATTENTION RADAR
              const Text("🚨 Projects",
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),

              const SizedBox(height: 12),

              Column(
                children: dashboardProjects.map((p) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: Colors.blue),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(_projectName(p),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(_projectLocation(p),
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text("ON TRACK",
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF047857))),
                        )
                      ],
                    ),
                  );
                }).toList(),
              )
            ],
          ),
        ),
      ),
    );
  }
}

/// STAT CARD
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color bg;
  final Color fg;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // ✅ FIX
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: fg),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(title,
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }
}