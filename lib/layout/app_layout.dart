import 'package:flutter/material.dart';
import 'app_header.dart';
import '../components/logout.dart';
import '../routes.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum AppRole { owner, engineer, manager, client }

class AppLayout extends StatefulWidget {
  final Widget child;
  final AppRole? role;

  // ✅ add this
  final EdgeInsetsGeometry? padding;

  const AppLayout({
    super.key,
    required this.child,
    this.role,
    this.padding,
  });

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  final FlutterTts tts = FlutterTts();
  Future<void> readDummyData() async {
  print("LAYOUT FUNCTION CALLED");

  await tts.stop();

  await tts.setLanguage("en-US");
  await tts.setPitch(1.0);
  await tts.setSpeechRate(1.3);
  await tts.setVolume(1.0);

  // 🔥 IMPORTANT: init engine properly
  await tts.awaitSpeakCompletion(false);

  await Future.delayed(const Duration(milliseconds: 300));

  String text = "Hello bro this is working test";

  await tts.speak(text);
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppHeader(
        onReadAloud: readDummyData,
        onNotifications: () {},
        onProfile: () => Navigator.pushNamed(context, AppRoutes.profile),
        onSettings: () => Navigator.pushNamed(context, AppRoutes.settings),
        onLogout: () async => await logout(context),
      ),
      body: SafeArea(
        child: Padding(
          // ✅ default padding if not provided
          padding: widget.padding ?? const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: widget.child,
        ),
      ),
    );
  }
}
