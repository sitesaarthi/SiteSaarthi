import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_config.dart';
import '../services/session_manager.dart';

class ProjectService {
  Future<Map<String, String>> _headers() async {
    final token = await SessionManager.getToken();
    if (token == null || token.isEmpty) throw "Token missing";
    return {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
  }

  Future<Map<String, dynamic>> uploadDoc({
    required String projectId,
    required String key,
    required String url,
  }) async {
    final headers = await _headers();

    final res = await http.patch(
      Uri.parse("${ApiConfig.baseUrl}/projects/$projectId/docs/upload"),
      headers: headers,
      body: jsonEncode({"key": key, "url": url}),
    );

    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) throw data["message"] ?? "Upload doc failed";
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> updateMap({
    required String projectId,
    required double centerLat,
    required double centerLng,
    int zoom = 16,
  }) async {
    final headers = await _headers();

    final res = await http.patch(
      Uri.parse("${ApiConfig.baseUrl}/projects/$projectId/siteview/map"),
      headers: headers,
      body: jsonEncode({
        "centerLat": centerLat,
        "centerLng": centerLng,
        "zoom": zoom,
      }),
    );

    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) throw data["message"] ?? "Update map failed";
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> addMarker({
    required String projectId,
    required String title,
    required double lat,
    required double lng,
  }) async {
    final headers = await _headers();

    final res = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/projects/$projectId/siteview/marker"),
      headers: headers,
      body: jsonEncode({
        "title": title,
        "lat": lat,
        "lng": lng,
      }),
    );

    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) throw data["message"] ?? "Add marker failed";
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> deleteMarker({
    required String projectId,
    required int index,
  }) async {
    final headers = await _headers();

    final res = await http.delete(
      Uri.parse("${ApiConfig.baseUrl}/projects/$projectId/siteview/marker/$index"),
      headers: headers,
    );

    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) throw data["message"] ?? "Delete marker failed";
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> updateSiteAssets({
    required String projectId,
    String? plan2dUrl,
    String? model3dUrl,
  }) async {
    final headers = await _headers();

    final body = <String, dynamic>{};
    if (plan2dUrl != null && plan2dUrl.trim().isNotEmpty) {
      body["plan2dUrl"] = plan2dUrl;
    }
    if (model3dUrl != null && model3dUrl.trim().isNotEmpty) {
      body["model3dUrl"] = model3dUrl;
    }

    final res = await http.patch(
      Uri.parse("${ApiConfig.baseUrl}/projects/$projectId/siteview/assets"),
      headers: headers,
      body: jsonEncode(body),
    );

    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) throw data["message"] ?? "Update assets failed";
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> setDprUploaders({
    required String projectId,
    required List<String> uploaderIds,
  }) async {
    final headers = await _headers();

    final res = await http.patch(
      Uri.parse("${ApiConfig.baseUrl}/projects/$projectId/dpr-uploaders"),
      headers: headers,
      body: jsonEncode({"uploaderIds": uploaderIds}),
    );

    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) throw data["message"] ?? "Update DPR uploaders failed";
    return Map<String, dynamic>.from(data);
  }
    Future<List<Map<String, dynamic>>> getProjectMembers(String projectId) async {
    final headers = await _headers();

    final res = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/projects/$projectId/members"),
      headers: headers,
    );

    final data = jsonDecode(res.body);

    if (res.statusCode >= 400) {
      throw data["message"] ?? "Get members failed";
    }

    final List list = data["members"] ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }
  Future<Map<String, dynamic>> updateMapBoundary({
  required String projectId,
  required double centerLat,
  required double centerLng,
  required double radiusMeters,
}) async {
  final headers = await _headers();

  final res = await http.patch(
    Uri.parse("${ApiConfig.baseUrl}/projects/$projectId/siteview/boundary"),
    headers: headers,
    body: jsonEncode({
      "centerLat": centerLat,
      "centerLng": centerLng,
      "radiusMeters": radiusMeters,
    }),
  );

  final data = jsonDecode(res.body);
  if (res.statusCode >= 400) throw data["message"] ?? "Update boundary failed";
  return Map<String, dynamic>.from(data);
}

}
