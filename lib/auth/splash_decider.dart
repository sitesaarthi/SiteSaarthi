import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../routes.dart';
import './auth_page.dart';


class SplashDecider extends StatefulWidget {
  const SplashDecider({super.key});
  @override
  State<SplashDecider> createState() => _SplashDeciderState();
}

class _SplashDeciderState extends State<SplashDecider> {
  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString("authUser");

    await Future.delayed(const Duration(milliseconds: 400)); // small splash feel

    if (!mounted) return;

    if (raw == null) {
      Navigator.pushReplacementNamed(context, AppRoutes.auth);
      return;
    }
    final user = jsonDecode(raw);
    final role = user["role"];

    if (role == "OWNER") {
      Navigator.pushReplacementNamed(context, AppRoutes.ownerHome);
    } else if (role == "ENGINEER") {
      Navigator.pushReplacementNamed(context, AppRoutes.engineerHome);
    } else if (role == "CLIENT") {
      Navigator.pushReplacementNamed(context, AppRoutes.clientHome);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.auth);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF4F4F5),
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
