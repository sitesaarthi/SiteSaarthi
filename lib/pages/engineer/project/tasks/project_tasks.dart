import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

/// ============================================================
/// PROJECT TASKS PAGE
/// Shows tasks only for 1 project
///
/// Backend:
/// GET    /api/tasks/project/:projectId
/// POST   /api/tasks
/// PATCH  /api/tasks/:taskId/status
/// ============================================================
class ProjectTasksPage extends StatefulWidget {
  final String projectId;
  final String projectName;

  const ProjectTasksPage({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<ProjectTasksPage> createState() => _ProjectTasksPageState();
}

class _ProjectTasksPageState extends State<ProjectTasksPage> {
  static const String baseUrl = "http://10.0.2.2:5000/api";

  String token = "";
  bool loading = true;
  String errorMsg = "";
  String filter = "ALL"; // ALL | PENDING | DONE

  List<Map<String, dynamic>> tasks = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadAuth();
    await _fetchProjectTasks();
  }

  Future<void> _loadAuth() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("authToken") ?? "";
  }

  /// ✅ ONLY PROJECT TASKS
  Future<void> _fetchProjectTasks() async {
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

      final url = Uri.parse("$baseUrl/tasks/project/${widget.projectId}");
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

  /// Helpers
  String _taskId(Map<String, dynamic> t) => (t["_id"] ?? t["id"] ?? "").toString();

  String _taskTitle(Map<String, dynamic> t) => (t["title"] ?? "-").toString();

  String _taskStatus(Map<String, dynamic> t) {
    final s = (t["status"] ?? "PENDING").toString().toUpperCase();
    return s == "COMPLETED" ? "DONE" : s;
  }

  String _priority(Map<String, dynamic> t) {
    final p = (t["priority"] ?? "MED").toString().toUpperCase();
    if (p == "MEDIUM") return "MED";
    return p;
  }

  String _formatDate(dynamic dueDate) {
    if (dueDate == null) return "-";
    final s = dueDate.toString();
    if (s.length >= 10) return s.substring(0, 10);
    return s;
  }

  int _priorityRank(String p) {
    if (p == "HIGH") return 1;
    if (p == "MED") return 2;
    return 3; // LOW
  }

  /// ✅ sort tasks HIGH > MED > LOW, also pending first
  List<Map<String, dynamic>> get filteredSortedTasks {
    final list = tasks.where((t) {
      if (filter == "ALL") return true;
      return _taskStatus(t) == filter;
    }).toList();

    list.sort((a, b) {
      // pending first
      final sa = _taskStatus(a);
      final sb = _taskStatus(b);
      if (sa != sb) return sa == "PENDING" ? -1 : 1;

      // priority high->low
      final pa = _priorityRank(_priority(a));
      final pb = _priorityRank(_priority(b));
      if (pa != pb) return pa.compareTo(pb);

      // newest first
      final ca = a["createdAt"]?.toString() ?? "";
      final cb = b["createdAt"]?.toString() ?? "";
      return cb.compareTo(ca);
    });

    return list;
  }

  /// Mark done
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

      if (res.statusCode >= 400) throw data["message"] ?? "Failed";

      final updated = Map<String, dynamic>.from(data["task"]);

      setState(() {
        tasks = tasks.map((t) {
          if (_taskId(t) == id) return updated;
          return t;
        }).toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Marked as DONE ✅")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed: $e")),
      );
    }
  }

  /// ✅ Add Task modal (fixed project)
  void _openAddTaskModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _AddTaskModalFixedProject(
        token: token,
        projectId: widget.projectId,
        projectName: widget.projectName,
        onCreated: (newTask) {
          setState(() => tasks.insert(0, newTask));
        },
      ),
    );
  }

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
        body: Center(child: Text(errorMsg)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _fetchProjectTasks,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER ROW WITH + ADD TASK
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.projectName.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Project Tasks",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _openAddTaskModal,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text(
                      "Add Task",
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  )
                ],
              ),

              const SizedBox(height: 14),

              /// FILTERS
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

              const SizedBox(height: 18),

              if (filteredSortedTasks.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text(
                      "No tasks found.",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),

              ...filteredSortedTasks.map((task) {
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
                          offset: Offset(0, 2))
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              _taskTitle(task),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: priorityBg(priority),
                              borderRadius: BorderRadius.circular(6),
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
                      const SizedBox(height: 8),
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
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            status,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: status == "DONE"
                                  ? Colors.green
                                  : Colors.blue,
                            ),
                          ),
                          status != "DONE"
                              ? ElevatedButton(
                                  onPressed: () => _markDone(task),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
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
                              : const Icon(Icons.check_circle,
                                  color: Colors.green),
                        ],
                      )
                    ],
                  ),
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
/// ADD TASK MODAL (FIXED PROJECT)
/// No project dropdown
/// ============================================================
class _AddTaskModalFixedProject extends StatefulWidget {
  final String token;
  final String projectId;
  final String projectName;
  final Function(Map<String, dynamic>) onCreated;

  const _AddTaskModalFixedProject({
    required this.token,
    required this.projectId,
    required this.projectName,
    required this.onCreated,
  });

  @override
  State<_AddTaskModalFixedProject> createState() =>
      _AddTaskModalFixedProjectState();
}

class _AddTaskModalFixedProjectState extends State<_AddTaskModalFixedProject> {
  static const String baseUrl = "http://10.0.2.2:5000/api";

  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  String priority = "MED";

  bool submitting = false;
  String error = "";

  Future<void> _createTask() async {
    final title = titleCtrl.text.trim();
    final desc = descCtrl.text.trim();

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
          "projectId": widget.projectId,
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
              Expanded(
                child: Text(
                  "Add Task • ${widget.projectName}",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(
                onPressed: submitting ? null : () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              )
            ],
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
              DropdownMenuItem(value: "HIGH", child: Text("HIGH")),
              DropdownMenuItem(value: "MED", child: Text("MED")),
              DropdownMenuItem(value: "LOW", child: Text("LOW")),
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
                    fontWeight: FontWeight.w800, color: Color(0xFFDC2626)),
              ),
            ),
          ],

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: submitting ? null : _createTask,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
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
