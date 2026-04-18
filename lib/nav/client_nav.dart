import 'package:flutter/material.dart';
import '../routes.dart';
import '../layout/app_header.dart';
import '../components/logout.dart';
import '../services/session_manager.dart';

// Client pages
import '../pages/client/siteview/client_siteview.dart';
import '../pages/client/docs/client_docs.dart';
import '../pages/client/chat/client_chat.dart';

class ClientNav extends StatefulWidget {
  final int initialIndex;
  const ClientNav({super.key, this.initialIndex = 0});

  @override
  State<ClientNav> createState() => _ClientNavState();
}

class _ClientNavState extends State<ClientNav> {
  late int currentIndex;

  List<Widget> pages = const [
    ClientSiteViewPage(),
    ClientDocsPage(),
    SizedBox(), // placeholder until token loaded
  ];

  String token = "";
  String phone = "";

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex.clamp(0, pages.length - 1);
    _loadAuthAndInitPages();
  }

  Future<void> _loadAuthAndInitPages() async {
    final t = await SessionManager.getToken();
    final user = await SessionManager.getUser();

    token = t ?? "";
    phone = (user?["phone"] ?? "").toString();

    debugPrint("✅ ClientNav token loaded: ${token.isNotEmpty}");
    debugPrint("✅ ClientNav phone loaded: $phone");

    setState(() {
      pages = [
        const ClientSiteViewPage(),
        const ClientDocsPage(),
        ClientChatPage(token: token, clientPhoneNumber: phone),
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

      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: _goToIndex,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map_rounded), label: "SiteView"),
          NavigationDestination(icon: Icon(Icons.folder_rounded), label: "Docs"),
          NavigationDestination(icon: Icon(Icons.chat_rounded), label: "Chat"),
        ],
      ),
    );
  }
}
