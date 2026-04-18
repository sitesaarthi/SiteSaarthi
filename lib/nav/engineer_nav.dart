import 'package:flutter/material.dart';
import '../routes.dart';
import '../layout/app_header.dart';
import '../components/logout.dart';
import '../components/assistant_fab.dart';
import '../services/session_manager.dart';

// Engineer Pages
import '../pages/engineer/dashboard/engineer_dashboard.dart';
import '../pages/engineer/projects/engineer_projects.dart';
import '../pages/engineer/tasks/engineer_tasks.dart';
import '../pages/engineer/materials_funds/engineer_materials_funds.dart';
import '../pages/engineer/chat/engineer_chat.dart';

class EngineerNav extends StatefulWidget {
  final int initialIndex;
  const EngineerNav({super.key, this.initialIndex = 0});

  @override
  State<EngineerNav> createState() => _EngineerNavState();
}

class _EngineerNavState extends State<EngineerNav> {
  late int currentIndex;

  List<Widget> pages = const [
    EngineerDashboardPage(),
    EngineerProjectsPage(),
    EngineerTasksPage(),
    EngineerMaterialsFundsPage(),
    SizedBox(), // placeholder
  ];

  String token = "";
  String phone = "";

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _loadAuthAndInitPages();
  }

  Future<void> _loadAuthAndInitPages() async {
    final t = await SessionManager.getToken();
    final user = await SessionManager.getUser();

    token = t ?? "";
    phone = (user?["phone"] ?? "").toString();

    debugPrint("✅ EngineerNav token loaded: ${token.isNotEmpty}");
    debugPrint("✅ EngineerNav phone loaded: $phone");

    setState(() {
      pages = [
        const EngineerDashboardPage(),
        const EngineerProjectsPage(),
        const EngineerTasksPage(),
        const EngineerMaterialsFundsPage(),
        EngineerChatPage(token: token, engineerPhoneNumber: phone),
      ];
    });
  }

  void _goToIndex(int index) => setState(() => currentIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
          child: IndexedStack(index: currentIndex, children: pages),
        ),
      ),
      floatingActionButton: const AssistantFab(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: _goToIndex,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: "Dashboard"),
          NavigationDestination(icon: Icon(Icons.map_rounded), label: "Projects"),
          NavigationDestination(icon: Icon(Icons.task_alt), label: "Tasks"),
          NavigationDestination(icon: Icon(Icons.inventory_2), label: "Materials"),
          NavigationDestination(icon: Icon(Icons.chat), label: "Chat"),
        ],
      ),
    );
  }
}
