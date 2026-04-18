import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

/// ============================================================
/// GLOBAL TASKS PAGE (Engineer + Manager same UI)
/// Backend:
/// GET    /api/tasks
/// POST   /api/tasks
/// PATCH  /api/tasks/:taskId/status
/// ============================================================
class EngineerTasksPage extends StatefulWidget {
  const EngineerTasksPage({super.key});

  @override
  State<EngineerTasksPage> createState() => _EngineerTasksPageState();
}

class _EngineerTasksPageState extends State<EngineerTasksPage> {
  static const String baseUrl = "http://10.0.2.2:5000/api";
  int _priorityRank(String p) {
    final v = p.toUpperCase();
    if (v == "HIGH") return 0;
    if (v == "MED" || v == "MEDIUM") return 1;
    return 2; // LOW
  }

  String token = "";
  Map<String, dynamic>? authUser;

  String filter = "ALL"; // ALL | PENDING | DONE

  bool loading = true;
  String errorMsg = "";

  List<Map<String, dynamic>> tasks = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadAuth();
    await _fetchGlobalTasks();
  }

  Future<void> _loadAuth() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("authToken") ?? "";
    final raw = prefs.getString("authUser");
    if (raw != null) authUser = jsonDecode(raw);
  }

  /// ------------------------------------------------------------
  /// GET GLOBAL TASKS
  /// ------------------------------------------------------------
  Future<void> _fetchGlobalTasks() async {
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

      final url = Uri.parse("$baseUrl/tasks");
      final res = await http.get(url, headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });

      if (res.body.isEmpty) throw "Empty response from server";
      final data = jsonDecode(res.body);

      if (res.statusCode >= 400) {
        throw data["message"] ?? "Failed to load tasks";
      }

      final List list = (data["tasks"] ?? []) as List;

      setState(() {
        tasks = list.map((e) => Map<String, dynamic>.from(e)).toList();
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        errorMsg = "Network error: $e";
      });
    }
  }

  /// ------------------------------------------------------------
  /// Helpers
  /// ------------------------------------------------------------
  String _taskId(Map<String, dynamic> t) {
    if (t["_id"] != null) return t["_id"].toString();
    if (t["id"] != null) return t["id"].toString();
    return "";
  }

  String _taskTitle(Map<String, dynamic> t) {
    return (t["title"] ?? "-").toString();
  }

  String _taskStatus(Map<String, dynamic> t) {
    // backend: PENDING / DONE
    final s = (t["status"] ?? "PENDING").toString().toUpperCase();
    if (s == "COMPLETED") return "DONE"; // safety
    return s;
  }

  String _projectName(Map<String, dynamic> t) {
    // backend populates projectId: { projectName: ... }
    final p = t["projectId"];
    if (p is Map && p["projectName"] != null)
      return p["projectName"].toString();
    // fallback if backend sends projectName directly
    if (t["projectName"] != null) return t["projectName"].toString();
    return "Unknown Project";
  }

  String _formatDate(dynamic dueDate) {
    // backend sends ISO date string or null
    if (dueDate == null) return "-";
    final s = dueDate.toString();
    if (s.length >= 10) return s.substring(0, 10);
    return s;
  }

  String _priority(Map<String, dynamic> t) {
    // backend: LOW / MED / HIGH
    final p = (t["priority"] ?? "MED").toString().toUpperCase();
    if (p == "MEDIUM") return "MED";
    return p;
  }

  /// ------------------------------------------------------------
  /// FILTER + GROUP
  /// ------------------------------------------------------------
  Map<String, List<Map<String, dynamic>>> get groupedTasks {
    final filteredList = tasks.where((t) {
      if (filter == "ALL") return true;
      return _taskStatus(t) == filter;
    }).toList();

    // ✅ sort BEFORE grouping (HIGH → MED → LOW) + dueDate asc
    filteredList.sort((a, b) {
      final prA = _priorityRank(_priority(a));
      final prB = _priorityRank(_priority(b));
      if (prA != prB) return prA.compareTo(prB);

      // if same priority, earlier date first
      final da = _formatDate(a["dueDate"]);
      final db = _formatDate(b["dueDate"]);
      return da.compareTo(db);
    });

    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final t in filteredList) {
      final pName = _projectName(t);
      grouped.putIfAbsent(pName, () => []);
      grouped[pName]!.add(t);
    }

    return grouped;
  }
  /// ------------------------------------------------------------
  /// MARK DONE (PATCH)
  /// ------------------------------------------------------------
  Future<void> _markDone(Map<String, dynamic> task) async {
    final id = _taskId(task);
    if (id.isEmpty) return;

    if (_taskStatus(task) == "DONE") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Task already done ✅")),
      );
      return;
    }

    try {
      final url = Uri.parse("$baseUrl/tasks/$id/status");
      final res = await http.patch(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"status": "DONE"}),
      );

      if (res.body.isEmpty) throw "Empty response from server";
      final data = jsonDecode(res.body);

      if (res.statusCode >= 400) {
        throw data["message"] ?? "Failed to update task";
      }

      // update UI locally
      final updatedTask = Map<String, dynamic>.from(data["task"]);
      setState(() {
        tasks = tasks.map((t) {
          if (_taskId(t) == id) return updatedTask;
          return t;
        }).toList();
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Marked as DONE ✅")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed: $e")),
      );
    }
  }

  /// ------------------------------------------------------------
  /// CREATE TASK (POST)
  /// ------------------------------------------------------------
  void _openAddTaskModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _AddTaskModal(
        token: token,
        onCreated: (newTask) {
          setState(() => tasks.insert(0, newTask));
        },
      ),
    );
  }

  /// ------------------------------------------------------------
  /// Priority UI
  /// ------------------------------------------------------------
  Color priorityBg(String p) {
    if (p == "HIGH") return const Color(0xFFFEE2E2);
    if (p == "MED") return const Color(0xFFFEF3C7);
    return const Color(0xFFD1FAE5);
  }

  Color priorityText(String p) {
    if (p == "HIGH") return const Color(0xFFB91C1C);
    if (p == "MED") return const Color(0xFFB45309);
    return const Color(0xFF047857);
  }

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
                  "Failed to load tasks",
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
                  onPressed: _fetchGlobalTasks,
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
      body: RefreshIndicator(
        onRefresh: _fetchGlobalTasks,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              /// HEADER ROW (title + add button)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "GLOBAL TASKS",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Across all assigned sites",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _openAddTaskModal,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text(
                      "Add Task",
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // FILTERS
              Row(
                children: ["ALL", "PENDING", "DONE"].map((t) {
                  final active = filter == t;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            active ? const Color(0xFF0B3C5D) : Colors.white,
                        foregroundColor:
                            active ? Colors.white : Colors.grey[600],
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () => setState(() => filter = t),
                      child: Text(
                        t,
                        style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w900),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              if (tasks.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Text(
                      "No tasks found.",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),

              // GROUPED TASKS
              ...groupedTasks.entries.map((entry) {
                final projectName = entry.key;
                final projectTasks = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.grid_view,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          projectName.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...projectTasks.map((task) {
                      final status = _taskStatus(task);
                      final priority = _priority(task);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 4,
                              color: Colors.black12,
                              offset: Offset(0, 2),
                            )
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _taskTitle(task),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today,
                                              size: 12, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatDate(task["dueDate"]),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: priorityBg(priority),
                                    borderRadius: BorderRadius.circular(6),
                                    border:
                                        Border.all(color: priorityBg(priority)),
                                  ),
                                  child: Text(
                                    priority,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: priorityText(priority),
                                    ),
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 4,
                                      backgroundColor: status == "DONE"
                                          ? Colors.green
                                          : Colors.blue,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      status,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: status == "DONE"
                                            ? Colors.green
                                            : Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                                status != "DONE"
                                    ? ElevatedButton(
                                        onPressed: () => _markDone(task),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                        ),
                                        child: const Text(
                                          "MARK DONE",
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      )
                                    : Row(
                                        children: const [
                                          Icon(Icons.check_circle,
                                              size: 16, color: Colors.green),
                                          SizedBox(width: 6),
                                          Text(
                                            "DONE",
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.green,
                                            ),
                                          )
                                        ],
                                      )
                              ],
                            )
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}

/// ============================================================
/// ADD TASK MODAL
/// ============================================================
class _AddTaskModal extends StatefulWidget {
  final String token;
  final Function(Map<String, dynamic>) onCreated;

  const _AddTaskModal({
    required this.token,
    required this.onCreated,
  });

  @override
  State<_AddTaskModal> createState() => _AddTaskModalState();
}

class _AddTaskModalState extends State<_AddTaskModal> {
  static const String baseUrl = "http://10.0.2.2:5000/api";

  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  String priority = "MED";
  String projectId = "";

  bool submitting = false;
  String error = "";

  List<Map<String, dynamic>> myProjects = [];

  @override
  void initState() {
    super.initState();
    _loadMyProjects();
  }

  Future<void> _loadMyProjects() async {
    try {
      final url = Uri.parse("$baseUrl/projects");
      final res = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
      );

      if (res.body.isEmpty) throw "Empty response";
      final data = jsonDecode(res.body);

      if (res.statusCode >= 400)
        throw data["message"] ?? "Failed to load projects";

      final List list = (data["projects"] ?? []) as List;

      setState(() {
        myProjects = list.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    } catch (e) {
      setState(() => error = "Failed to load projects: $e");
    }
  }

  String _projectId(Map<String, dynamic> p) => (p["_id"] ?? "").toString();
  String _projectName(Map<String, dynamic> p) =>
      (p["projectName"] ?? "-").toString();

  Future<void> _createTask() async {
    final title = titleCtrl.text.trim();
    final desc = descCtrl.text.trim();

    if (projectId.isEmpty) {
      setState(() => error = "Select project");
      return;
    }
    if (title.isEmpty) {
      setState(() => error = "Enter task title");
      return;
    }

    setState(() {
      submitting = true;
      error = "";
    });

    try {
      final url = Uri.parse("$baseUrl/tasks");
      final res = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
        body: jsonEncode({
          "projectId": projectId,
          "title": title,
          "desc": desc,
          "priority": priority,
        }),
      );

      if (res.body.isEmpty) throw "Empty response";
      final data = jsonDecode(res.body);

      if (res.statusCode >= 400) {
        setState(() {
          submitting = false;
          error = data["message"] ?? "Failed to create task";
        });
        return;
      }

      final created = Map<String, dynamic>.from(data["task"]);

      widget.onCreated(created);

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Task created ✅")),
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
    titleCtrl.dispose();
    descCtrl.dispose();
    super.dispose();
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
                  "Add Task",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(
                onPressed: submitting ? null : () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              )
            ],
          ),

          const SizedBox(height: 12),

          /// PROJECT
          DropdownButtonFormField<String>(
            value: projectId.isEmpty ? null : projectId,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              hintText: "Select Project",
            ),
            items: myProjects.map((p) {
              return DropdownMenuItem(
                value: _projectId(p),
                child: Text(_projectName(p), overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (v) => setState(() => projectId = v ?? ""),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: titleCtrl,
            decoration: InputDecoration(
              hintText: "Task title",
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: descCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Description (optional)",
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 12),

          /// PRIORITY
          DropdownButtonFormField<String>(
            value: priority,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            items: const [
              DropdownMenuItem(value: "LOW", child: Text("LOW")),
              DropdownMenuItem(value: "MED", child: Text("MED")),
              DropdownMenuItem(value: "HIGH", child: Text("HIGH")),
            ],
            onChanged: (v) => setState(() => priority = v ?? "MED"),
          ),

          if (error.isNotEmpty) ...[
            const SizedBox(height: 12),
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

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
              ),
              onPressed: submitting ? null : _createTask,
              child: submitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      "CREATE TASK",
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
