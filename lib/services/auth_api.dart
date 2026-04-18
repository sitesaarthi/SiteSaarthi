import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class AuthApi {
  static Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    required String password,
    required String role,
  }) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/auth/register");

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name,
        "phone": phone,
        "password": password,
        "role": role,
      }),
    );

    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) throw data["message"] ?? "Register failed";
    return data;
  }

  static Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/auth/login");

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "phone": phone,
        "password": password,
      }),
    );

    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) throw data["message"] ?? "Login failed";
    return data;
  }
}
