import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../services/api_config.dart';
import '../services/session_manager.dart';
import 'package:http_parser/http_parser.dart';

class DprService {
  Future<String> _token() async {
    final t = await SessionManager.getToken();
    if (t == null || t.isEmpty) throw "Token missing";
    return t;
  }

  Future<Map<String, String>> _headers() async {
    final token = await _token();
    return {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
  }

  /// ✅ Upload DPR PDF and return fileUrl
  Future<String> uploadDprPdf(File pdfFile) async {
    final token = await _token();

    final uri = Uri.parse("${ApiConfig.baseUrl}/upload/dpr");

    final req = http.MultipartRequest("POST", uri);
    req.headers["Authorization"] = "Bearer $token";

    req.files.add(
      await http.MultipartFile.fromPath(
        "pdf",
        pdfFile.path,
        filename: "dpr.pdf",
        contentType: MediaType("application", "pdf"),
      ),
    );

    final streamed = await req.send();
    final resStr = await streamed.stream.bytesToString();

    final data = jsonDecode(resStr);

    if (streamed.statusCode >= 400) {
      throw data["message"] ?? "PDF Upload failed";
    }

    return (data["fileUrl"] ?? "").toString();
  }

  Future<List<Map<String, dynamic>>> getProjectDprs(String projectId) async {
    final headers = await _headers();

    final res = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/dpr/$projectId"),
      headers: headers,
    );

    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) throw data["message"] ?? "Failed to load DPRs";

    final List list = (data["dprs"] ?? []) as List;
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> createDpr({
    required String projectId,
    required DateTime date,
    String title = "",
    String workDone = "",
    String issues = "",
    List<String> photos = const [],
    String fileUrl = "",
  }) async {
    final headers = await _headers();

    final res = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/dpr"),
      headers: headers,
      body: jsonEncode({
        "projectId": projectId,
        "date": date.toIso8601String(),
        "title": title,
        "workDone": workDone,
        "issues": issues,
        "photos": photos,
        "fileUrl": fileUrl,
      }),
    );

    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) throw data["message"] ?? "Create DPR failed";

    return Map<String, dynamic>.from(data);
  }
}
