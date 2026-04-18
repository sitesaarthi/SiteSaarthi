import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/chat_repository.dart';
import '../../../services/session_manager.dart';

class EngineerChatPage extends StatefulWidget {
  final String token;

  // ✅ for direct call button
  final String engineerPhoneNumber;

  const EngineerChatPage({
    super.key,
    required this.token,
    required this.engineerPhoneNumber,
  });

  @override
  State<EngineerChatPage> createState() => _EngineerChatPageState();
}

class _EngineerChatPageState extends State<EngineerChatPage> {
  late final BackendChatRepository repo;

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  List<InboxItem> inboxList = [];
  List<ChatMessage> activeMessages = [];

  String? activeProjectId;
  String activeProjectName = "Project Chat";

  bool loadingInbox = true;
  bool loadingMessages = false;

  bool showProjectListMobile = true;

  Timer? pollTimer;

  late ChatUser authUser;

  @override
  void initState() {
    super.initState();
    repo = BackendChatRepository(token: widget.token);

    authUser = const ChatUser(id: "", role: "ENGINEER", name: "Engineer");
    _initAuthUser();
    _loadInbox();

    // ✅ polling until socket.io
    pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (activeProjectId != null) {
        await _loadMessages(activeProjectId!, markSeen: false, silent: true);
      }
      await _loadInbox(silent: true);
    });
  }

  Future<void> _initAuthUser() async {
    final user = await SessionManager.getUser();
    setState(() {
      authUser = ChatUser(
        id: (user?["_id"] ?? user?["id"] ?? "").toString(),
        role: (user?["role"] ?? "ENGINEER").toString(),
        name: (user?["name"] ?? "Engineer").toString(),
      );
    });
  }

  @override
  void dispose() {
    pollTimer?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadInbox({bool silent = false}) async {
    try {
      if (!silent) setState(() => loadingInbox = true);

      final list = await repo.inbox(chatType: "TEAM");

      if (!mounted) return;
      setState(() {
        inboxList = list;
        loadingInbox = false;
      });

      // auto select first
      if (activeProjectId == null && list.isNotEmpty) {
        final first = list.first;
        activeProjectId = first.projectId;
        activeProjectName = first.projectName;
        await _loadMessages(first.projectId, markSeen: true);
        setState(() => showProjectListMobile = false);
      }
    } catch (e) {
      debugPrint("❌ ENGINEER INBOX ERROR: $e");
      if (!silent) setState(() => loadingInbox = false);
    }
  }

  Future<void> _loadMessages(
    String projectId, {
    bool markSeen = false,
    bool silent = false,
  }) async {
    try {
      if (!silent) setState(() => loadingMessages = true);

      final msgs = await repo.messages(projectId: projectId, chatType: "TEAM");

      if (!mounted) return;

      setState(() {
        activeMessages = msgs;
        loadingMessages = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

      if (markSeen) {
        await repo.seen(projectId: projectId, chatType: "TEAM");
        await _loadInbox(silent: true);
      }
    } catch (e) {
      debugPrint("❌ ENGINEER MSG ERROR: $e");
      if (!silent) setState(() => loadingMessages = false);
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
    if (text.isEmpty || activeProjectId == null) return;

    final pid = activeProjectId!;
    final pname = activeProjectName;

    const receiver = ChatUser(id: "team", role: "TEAM", name: "Team");

    _controller.clear();

    try {
      await repo.send(
        projectId: pid,
        projectName: pname,
        chatType: "TEAM",
        receiver: receiver,
        message: text,
      );

      await _loadMessages(pid, markSeen: false, silent: true);
      await _loadInbox(silent: true);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      debugPrint("❌ ENGINEER SEND ERROR: $e");
    }
  }

  /// ✅ in engineer chat, call owner (project owner)
  /// We'll store owner's phone later using /projects/:id/members
  /// For now: just call the number passed (or leave empty)
  Future<void> _callOwner() async {
    // TODO later: fetch owner phone dynamically
    final phone = ""; // keep empty for now
    if (phone.trim().isEmpty) return;

    final uri = Uri.parse("tel:$phone");
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isWide = w >= 768;

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
          child: Row(
            children: [
              // LEFT INBOX
              if (isWide || showProjectListMobile)
                SizedBox(
                  width: isWide ? 280 : w,
                  child: _ProjectListInbox(
                    loading: loadingInbox,
                    inbox: inboxList,
                    activeProjectId: activeProjectId,
                    onSelect: (item) async {
                      setState(() {
                        activeProjectId = item.projectId;
                        activeProjectName = item.projectName;
                        showProjectListMobile = false;
                      });
                      await _loadMessages(item.projectId, markSeen: true);
                    },
                  ),
                ),

              // RIGHT CHAT
              if (isWide || !showProjectListMobile)
                Expanded(
                  child: Column(
                    children: [
                      _ChatHeader(
                        title: "$activeProjectName Chat",
                        isWide: isWide,
                        onBackMobile: () => setState(() => showProjectListMobile = true),
                        onCall: _callOwner,
                      ),
                      Expanded(
                        child: Container(
                          color: const Color(0xFFF1F5F9),
                          padding: const EdgeInsets.all(16),
                          child: loadingMessages
                              ? const Center(child: CircularProgressIndicator())
                              : ListView.builder(
                                  controller: _scroll,
                                  itemCount: activeMessages.length,
                                  itemBuilder: (context, index) {
                                    final msg = activeMessages[index];
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
            ],
          ),
        ),
      ),
    );
  }
}

/// ✅ PROJECT INBOX
class _ProjectListInbox extends StatelessWidget {
  final bool loading;
  final List<InboxItem> inbox;
  final String? activeProjectId;
  final ValueChanged<InboxItem> onSelect;

  const _ProjectListInbox({
    required this.loading,
    required this.inbox,
    required this.activeProjectId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade50,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            alignment: Alignment.centerLeft,
            child: const Text(
              "Project Chats",
              style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey),
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : inbox.isEmpty
                    ? const Center(child: Text("No chats yet"))
                    : ListView.builder(
                        itemCount: inbox.length,
                        itemBuilder: (context, index) {
                          final p = inbox[index];
                          final isActive = p.projectId == activeProjectId;

                          return InkWell(
                            onTap: () => onSelect(p),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: isActive ? Colors.orange.shade100 : null,
                                border: Border(
                                  bottom: BorderSide(color: Colors.grey.shade300),
                                  left: isActive
                                      ? const BorderSide(color: Colors.orange, width: 4)
                                      : BorderSide.none,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.projectName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w900, fontSize: 14),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          p.lastMessage,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (p.unreadCount > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        "${p.unreadCount}",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  final String title;
  final bool isWide;
  final VoidCallback onBackMobile;
  final VoidCallback onCall;

  const _ChatHeader({
    required this.title,
    required this.isWide,
    required this.onBackMobile,
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
          if (!isWide)
            IconButton(
              onPressed: onBackMobile,
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
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
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
                      color: Colors.orange),
                ),
              Text(
                msg.message,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isMe ? Colors.white : Colors.black87),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  time,
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Colors.black.withOpacity(0.45)),
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  BoxShadow(color: Colors.orange.withOpacity(0.28), blurRadius: 10)
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
