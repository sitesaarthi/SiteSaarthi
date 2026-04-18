import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../services/chat_repository.dart';
import '../../../../services/session_manager.dart';

class ProjectChatPage extends StatefulWidget {
  final String projectId;
  final String projectName;

  const ProjectChatPage({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<ProjectChatPage> createState() => _ProjectChatPageState();
}

class _ProjectChatPageState extends State<ProjectChatPage> {
  BackendChatRepository? repo;

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  List<ChatMessage> messages = [];

  bool loading = true;
  Timer? pollTimer;

  ChatUser authUser =
      const ChatUser(id: "", role: "ENGINEER", name: "Engineer");

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final token = await SessionManager.getToken();
      final user = await SessionManager.getUser();

      if (token == null || token.isEmpty) {
        setState(() => loading = false);
        return;
      }

      repo = BackendChatRepository(token: token);

      authUser = ChatUser(
        id: (user?["_id"] ?? user?["id"] ?? "").toString(),
        role: (user?["role"] ?? "ENGINEER").toString(),
        name: (user?["name"] ?? "Engineer").toString(),
      );

      await _loadMessages(markSeen: true);

      // ✅ polling
      pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
        await _loadMessages(silent: true);
      });
    } catch (e) {
      debugPrint("❌ ProjectChat init error: $e");
      setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    pollTimer?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({bool markSeen = false, bool silent = false}) async {
    if (repo == null) return;

    try {
      if (!silent) setState(() => loading = true);

      final list = await repo!.messages(
        projectId: widget.projectId,
        chatType: "TEAM",
      );

      if (!mounted) return;
      setState(() {
        messages = list;
        loading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

      if (markSeen) {
        await repo!.seen(projectId: widget.projectId, chatType: "TEAM");
      }
    } catch (e) {
      debugPrint("❌ ProjectChat messages error: $e");
      if (!silent) setState(() => loading = false);
    }
  }

  void _scrollToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent + 200,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || repo == null) return;

    _controller.clear();

    // ✅ TEAM receiver dummy
    const receiver = ChatUser(id: "team", role: "TEAM", name: "Team");

    try {
      await repo!.send(
        projectId: widget.projectId,
        projectName: widget.projectName,
        chatType: "TEAM",
        receiver: receiver,
        message: text,
      );

      await _loadMessages(silent: true);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      debugPrint("❌ ProjectChat send error: $e");
    }
  }

  Future<void> _callOwner() async {
    // later you can fetch real phone using /projects/:id/members
    final phone = "";
    if (phone.trim().isEmpty) return;
    final uri = Uri.parse("tel:$phone");
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.black12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _ChatHeader(
                title: "${widget.projectName} Chat",
                onBack: () => Navigator.pop(context),
                onCall: _callOwner,
              ),
              Expanded(
                child: Container(
                  color: const Color(0xFFF1F5F9),
                  padding: const EdgeInsets.all(16),
                  child: loading
                      ? const Center(child: CircularProgressIndicator())
                      : messages.isEmpty
                          ? const Center(
                              child: Text(
                                "No messages yet",
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: _scroll,
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final msg = messages[index];
                                final isMe = msg.sender.id == authUser.id;
                                return _MessageBubble(msg: msg, isMe: isMe);
                              },
                            ),
                ),
              ),
              _ChatInput(
                controller: _controller,
                onSend: _send,
                onCamera: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final VoidCallback onCall;

  const _ChatHeader({
    required this.title,
    required this.onBack,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.chevron_left_rounded,
                color: Colors.orange, size: 28),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Center(
              child: Text(
                "SS",
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.orange,
                    fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: onCall,
            child: const Icon(Icons.phone, color: Colors.orange, size: 20),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage msg;
  final bool isMe;

  const _MessageBubble({required this.msg, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final time = DateFormat.Hm().format(msg.createdAt);

    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Container(
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78),
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isMe ? const Color(0xFF0B3C5D) : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(isMe ? 16 : 0),
              topRight: Radius.circular(isMe ? 0 : 16),
              bottomLeft: const Radius.circular(16),
              bottomRight: const Radius.circular(16),
            ),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Text(
                  msg.sender.name.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.orange,
                  ),
                ),
              Text(
                msg.message,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isMe ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  time,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Colors.black.withOpacity(0.45),
                  ),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}

class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onCamera;

  const _ChatInput({
    required this.controller,
    required this.onSend,
    required this.onCamera,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onCamera,
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.camera_alt, color: Colors.orange, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: "Type update...",
                filled: true,
                fillColor: Colors.grey.shade200,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onSend,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Colors.orange.withOpacity(0.28), blurRadius: 10)
                ],
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 18),
            ),
          )
        ],
      ),
    );
  }
}
