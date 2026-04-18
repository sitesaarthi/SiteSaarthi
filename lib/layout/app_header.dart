import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class AppHeader extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback onLogout;
  final VoidCallback onSettings;
  final VoidCallback onReadAloud;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;

  const AppHeader({
    super.key,
    required this.onReadAloud,
    required this.onNotifications,
    required this.onProfile,
    required this.onSettings,
    required this.onLogout,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  OverlayEntry? _notificationOverlay;
  bool isOffline = false;
  StreamSubscription<ConnectivityResult>? _sub;
  void _showNotifications(BuildContext ctx) {
    if (_notificationOverlay != null) {
      _notificationOverlay!.remove();
      _notificationOverlay = null;
      return;
    }

    final RenderBox button = ctx.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(ctx).context.findRenderObject() as RenderBox;

    final position = button.localToGlobal(Offset.zero, ancestor: overlay);

    _notificationOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: position.dy + button.size.height + 6,
        left: position.dx - 200 + button.size.width,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 260,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: Colors.black26, blurRadius: 10),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Row(
                  children: [
                    Icon(Icons.upload_file, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text("DPR uploaded for Skyline Residency"),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.orange, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text("Delay in Green Valley Villa"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_notificationOverlay!);
  }

  @override
  void initState() {
    super.initState();
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    // ✅ initial check
    final ConnectivityResult result = await Connectivity().checkConnectivity();
    _updateStatus(result);

    // ✅ listen for changes
    _sub = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      _updateStatus(result);
    });
  }

  void _updateStatus(ConnectivityResult result) {
    final offlineNow = result == ConnectivityResult.none;
    if (!mounted) return;

    setState(() {
      isOffline = offlineNow;
    });
  }

  @override
  void dispose() {
    _notificationOverlay?.remove();
    _sub?.cancel();
    super.dispose();
  }

  void _onToggleOffline() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isOffline ? "No Internet ❌" : "Internet Connected ✅"),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      titleSpacing: 16,
      title: Row(
        children: [
          Image.asset("assets/SiteSaarthiLogo.png", height: 32),
          const SizedBox(width: 10),
          const Text(
            "SiteSaarthi",
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      actions: [
        // ✅ WIFI ICON ONLY (AUTO GREEN/RED)
        Padding(
          padding: const EdgeInsets.only(right: 4), // ✅ reduced
          child: Tooltip(
            message: isOffline ? "Offline" : "Online",
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: _onToggleOffline,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isOffline
                      ? const Color(0xFFFFE4E6)
                      : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(
                  isOffline ? Icons.wifi_off : Icons.wifi,
                  size: 18,
                  color: isOffline
                      ? const Color(0xFFE11D48)
                      : const Color(0xFF059669),
                ),
              ),
            ),
          ),
        ),

        // ✅ Read aloud (compact)
        IconButton(
          tooltip: "Read aloud",
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
          onPressed: () {
            print("HEADER CLICKED"); // 🔥 MUST PRINT
            print(widget.onReadAloud);
            widget.onReadAloud();
          },
          icon: const Icon(Icons.volume_up_outlined,
              color: Colors.black54, size: 22),
        ),

        // ✅ Notifications (compact)
        Builder(
          builder: (ctx) {
            return Stack(
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 38, minHeight: 38),
                  onPressed: () => _showNotifications(ctx), // ✅ ONLY THIS
                  icon: const Icon(
                    Icons.notifications_none,
                    color: Colors.black54,
                    size: 22,
                  ),
                ),

                // 🔴 RED DOT
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        // ✅ Profile menu button (already compact)
        Padding(
          padding: const EdgeInsets.only(right: 10), // ✅ reduced
          child: Builder(
            builder: (ctx) {
              return InkWell(
                onTap: () async {
                  final RenderBox button = ctx.findRenderObject() as RenderBox;
                  final RenderBox overlay =
                      Overlay.of(ctx).context.findRenderObject() as RenderBox;

                  final RelativeRect position = RelativeRect.fromRect(
                    Rect.fromPoints(
                      button.localToGlobal(Offset.zero, ancestor: overlay),
                      button.localToGlobal(
                        button.size.bottomRight(Offset.zero),
                        ancestor: overlay,
                      ),
                    ),
                    Offset.zero & overlay.size,
                  );

                  final selected = await showMenu<String>(
                    context: context,
                    position: position,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    items: [
                      PopupMenuItem<String>(
                        value: "profile",
                        child: Row(
                          children: const [
                            Icon(Icons.person_outline, size: 18),
                            SizedBox(width: 10),
                            Text("Profile",
                                style: TextStyle(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: "settings",
                        child: Row(
                          children: const [
                            Icon(Icons.settings_outlined, size: 18),
                            SizedBox(width: 10),
                            Text("Settings",
                                style: TextStyle(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem<String>(
                        value: "logout",
                        child: Row(
                          children: const [
                            Icon(Icons.logout, size: 18, color: Colors.red),
                            SizedBox(width: 10),
                            Text(
                              "Logout",
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );

                  if (selected == null) return;

                  if (selected == "profile") {
                    widget.onProfile();
                  } else if (selected == "settings") {
                    widget.onSettings();
                  } else if (selected == "logout") {
                    widget.onLogout();
                  }
                },
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child:
                      const Icon(Icons.person_outline, color: Colors.black54),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
