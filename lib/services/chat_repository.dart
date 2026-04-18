import 'dart:convert';
import 'package:http/http.dart' as http;

import '../services/api_config.dart';

class ChatUser {
  final String id;
  final String role;
  final String name;

  const ChatUser({required this.id, required this.role, required this.name});

  factory ChatUser.fromJson(Map<String, dynamic> json) => ChatUser(
        id: (json["id"] ?? "").toString(),
        role: (json["role"] ?? "").toString(),
        name: (json["name"] ?? "").toString(),
      );

  Map<String, dynamic> toJson() => {"id": id, "role": role, "name": name};
}

class ChatMessage {
  final String id;
  final String projectId;
  final String projectName;
  final String chatType; // TEAM / CLIENT
  final ChatUser sender;
  final ChatUser receiver;
  final String message;
  final String type;
  final DateTime createdAt;
  final String status;

  const ChatMessage({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.chatType,
    required this.sender,
    required this.receiver,
    required this.message,
    required this.type,
    required this.createdAt,
    required this.status,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: (json["_id"] ?? json["id"] ?? "").toString(),
        projectId: (json["projectId"] ?? "").toString(),
        projectName: (json["projectName"] ?? "Project").toString(),
        chatType: (json["chatType"] ?? "TEAM").toString(),
        sender: ChatUser.fromJson(json["sender"] ?? {}),
        receiver: ChatUser.fromJson(json["receiver"] ?? {}),
        message: (json["message"] ?? "").toString(),
        type: (json["type"] ?? "TEXT").toString(),
        createdAt: DateTime.tryParse((json["createdAt"] ?? "").toString()) ??
            DateTime.now(),
        status: (json["status"] ?? "SENT").toString(),
      );
}

/// Inbox tile model
class InboxItem {
  final String projectId;
  final String projectName;
  final String chatType;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final ChatUser? lastSender;

  const InboxItem({
    required this.projectId,
    required this.projectName,
    required this.chatType,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
    required this.lastSender,
  });

  factory InboxItem.fromJson(Map<String, dynamic> json) => InboxItem(
        projectId: (json["projectId"] ?? "").toString(),
        projectName: (json["projectName"] ?? "Project").toString(),
        chatType: (json["chatType"] ?? "TEAM").toString(),
        lastMessage: (json["lastMessage"] ?? "").toString(),
        lastMessageAt: json["lastMessageAt"] != null
            ? DateTime.tryParse(json["lastMessageAt"].toString())
            : null,
        unreadCount: (json["unreadCount"] ?? 0) is int
            ? json["unreadCount"]
            : int.tryParse(json["unreadCount"].toString()) ?? 0,
        lastSender: json["lastSender"] != null
            ? ChatUser.fromJson(json["lastSender"])
            : null,
      );
}

class BackendChatRepository {
  final String token;

  BackendChatRepository({required this.token});

  Map<String, String> get _headers => {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      };

  /// ✅ WhatsApp-like list (projects)
  Future<List<InboxItem>> inbox({String chatType = "TEAM"}) async {
    final uri = Uri.parse("${ApiConfig.baseUrl}/chat/inbox?chatType=$chatType");
    final res = await http.get(uri, headers: _headers);

    final data = jsonDecode(res.body);
    if (res.statusCode != 200 || data["success"] != true) {
      throw Exception(data["message"] ?? "Inbox failed");
    }

    final List list = data["inbox"] ?? [];
    return list.map((e) => InboxItem.fromJson(e)).toList();
  }

  /// ✅ Load messages for a project
  Future<List<ChatMessage>> messages({
    required String projectId,
    String chatType = "TEAM",
  }) async {
    final uri = Uri.parse(
        "${ApiConfig.baseUrl}/chat/messages?projectId=$projectId&chatType=$chatType");
    final res = await http.get(uri, headers: _headers);

    final data = jsonDecode(res.body);
    if (res.statusCode != 200 || data["success"] != true) {
      throw Exception(data["message"] ?? "Fetch messages failed");
    }

    final List list = data["messages"] ?? [];
    return list.map((e) => ChatMessage.fromJson(e)).toList();
  }

  /// ✅ Send message
  Future<ChatMessage> send({
    required String projectId,
    required String projectName,
    required String message,
    required ChatUser receiver,
    String chatType = "TEAM",
  }) async {
    final uri = Uri.parse("${ApiConfig.baseUrl}/chat/send");

    final res = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        "projectId": projectId,
        "projectName": projectName,
        "chatType": chatType,
        "receiver": receiver.toJson(),
        "message": message,
      }),
    );

    final data = jsonDecode(res.body);
    if (res.statusCode != 200 || data["success"] != true) {
      throw Exception(data["message"] ?? "Send failed");
    }

    return ChatMessage.fromJson(data["message"]);
  }

  /// ✅ Mark seen
  Future<void> seen(
      {required String projectId, String chatType = "TEAM"}) async {
    final uri = Uri.parse("${ApiConfig.baseUrl}/chat/seen");
    final res = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({"projectId": projectId, "chatType": chatType}),
    );

    final data = jsonDecode(res.body);
    if (res.statusCode != 200 || data["success"] != true) {
      throw Exception(data["message"] ?? "Seen failed");
    }
  }

  Future<List<InboxItem>> inboxAll() async {
    final uri = Uri.parse("${ApiConfig.baseUrl}/chat/inbox-all");
    final res = await http.get(uri, headers: _headers);

    final data = jsonDecode(res.body);
    if (res.statusCode != 200 || data["success"] != true) {
      throw Exception(data["message"] ?? "Inbox-all failed");
    }

    final List list = data["inbox"] ?? [];
    return list.map((e) => InboxItem.fromJson(e)).toList();
  }
}
