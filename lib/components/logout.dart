import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../routes.dart';

Future<void> logout(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove("authUser");

  if (!context.mounted) return;

  Navigator.pushNamedAndRemoveUntil(
    context,
    AppRoutes.auth,
    (route) => false,
  );
}
