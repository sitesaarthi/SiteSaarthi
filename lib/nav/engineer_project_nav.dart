import 'package:flutter/material.dart';
import '../layout/app_header.dart';
import '../routes.dart';
import '../components/logout.dart';
import '../components/assistant_fab.dart';

// ✅ project pages (create placeholders for now)
import '../pages/engineer/project/dashboard/project_dashboard.dart';
import '../pages/engineer/project/siteview/project_siteview.dart';
import '../pages/engineer/project/tasks/project_tasks.dart';
import '../pages/engineer/project/materials/project_materials.dart';
import '../pages/engineer/project/chat/project_chat.dart';

class EngineerProjectNav extends StatefulWidget {
  final String projectId;
  final String projectName;
  final int initialIndex;

  const EngineerProjectNav({
    super.key,
    required this.projectId,
    required this.projectName,
    this.initialIndex = 0,
  });

  @override
  State<EngineerProjectNav> createState() => _EngineerProjectNavState();
}

class _EngineerProjectNavState extends State<EngineerProjectNav> {
  bool isOffline = false;
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
  }

  void _goToIndex(int i) => setState(() => currentIndex = i);

  @override
  Widget build(BuildContext context) {
    final pages = [
  ProjectDashboardPage(
    projectId: widget.projectId,
    projectName: widget.projectName,
    onOpenMaterials: () => _goToIndex(3), // ✅ open Material tab
  ),
  ProjectSiteViewPage(projectId: widget.projectId, projectName: widget.projectName),
  ProjectTasksPage(projectId: widget.projectId, projectName: widget.projectName),
  ProjectMaterialsPage(projectId: widget.projectId, projectName: widget.projectName),
  ProjectChatPage(projectId: widget.projectId, projectName: widget.projectName),
];



    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      // ✅ AppHeader same as before
      appBar: AppHeader(
        onReadAloud: () {},
        onNotifications: () {},
        onProfile: () => Navigator.pushNamed(context, AppRoutes.profile),
        onSettings: () => Navigator.pushNamed(context, AppRoutes.settings),
        onLogout: () async => await logout(context),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Project title row (optional but looks clean)
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: Text(
                      widget.projectName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ✅ actual page stack
              Expanded(
                child: IndexedStack(
                  index: currentIndex,
                  children: pages,
                ),
              ),
            ],
          ),
        ),
      ),

      floatingActionButton: const AssistantFab(),

      // ✅ NEW dedicated bottom nav
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: _goToIndex,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: "Dashboard"),
          NavigationDestination(icon: Icon(Icons.map_rounded), label: "SiteView"),
          NavigationDestination(icon: Icon(Icons.task_alt), label: "Tasks"),
          NavigationDestination(icon: Icon(Icons.inventory_2), label: "Material"),
          NavigationDestination(icon: Icon(Icons.chat), label: "Chat"),
        ],
      ),
    );
  }
}
