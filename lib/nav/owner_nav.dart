import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../routes.dart';
import '../layout/app_header.dart';
import '../components/logout.dart';
import '../components/assistant_fab.dart';
import '../services/session_manager.dart';

// Owner Screens
import '../pages/owner/dashboard/owner_dashboard.dart';
import '../pages/owner/projects/owner_projects.dart';
import '../pages/owner/approvals/owner_approvals.dart';
import '../pages/owner/chat/owner_chat.dart';
import '../pages/owner/docs/owner_docs.dart';

class OwnerNav extends StatefulWidget {
  final int initialIndex;
  const OwnerNav({super.key, this.initialIndex = 0});

  @override
  State<OwnerNav> createState() => _OwnerNavState();
}

class _OwnerNavState extends State<OwnerNav> {
  bool isOffline = false;
  late int currentIndex;

  List<Widget> pages = const [
    OwnerDashboardPage(),
    OwnerProjectsPage(),
    OwnerApprovalsPage(),
    SizedBox(), // placeholder until token loaded
    OwnerDocsPage(),
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

  debugPrint("✅ OwnerNav token loaded: ${token.isNotEmpty}");
  debugPrint("✅ OwnerNav phone loaded: $phone");

  setState(() {
    pages = [
      const OwnerDashboardPage(),
      const OwnerProjectsPage(),
      const OwnerApprovalsPage(),
      OwnerChatPage(token: token, ownerPhoneNumber: phone),
      const OwnerDocsPage(),
    ];
  });
}


  void _goToIndex(int index) {
    setState(() => currentIndex = index);
  }

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

          child: IndexedStack(
            index: currentIndex,
            children: pages,
          ),
        ),
      ),

      floatingActionButton: const AssistantFab(),

      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: _goToIndex,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: "Dashboard"),
          NavigationDestination(icon: Icon(Icons.apartment), label: "Projects"),
          NavigationDestination(icon: Icon(Icons.approval), label: "Approvals"),
          NavigationDestination(icon: Icon(Icons.chat), label: "Chat"),
          NavigationDestination(icon: Icon(Icons.folder), label: "Docs"),
        ],
      ),
    );
  }
}
