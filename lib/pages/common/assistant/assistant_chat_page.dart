import 'package:flutter/material.dart';

class AssistantChatPage extends StatefulWidget {
  const AssistantChatPage({super.key});

  @override
  State<AssistantChatPage> createState() => _AssistantChatPageState();
}

class _AssistantChatPageState extends State<AssistantChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<_ChatMessage> messages = [
    _ChatMessage(
      text: "👋 Hi, I'm Saarthi.\nWhat would you like to check?",
      isUser: false,
      options: ["Projects", "DPR Status", "Tasks", "Progress", "Others"],
    ),
  ];

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      messages.add(_ChatMessage(text: text, isUser: true));
      _controller.clear();
    });

    _scrollToBottom();

    // ⏳ Simulated AI delay
    Future.delayed(const Duration(milliseconds: 500), () {
      final lowerText = text.toLowerCase();

      // 📁 Projects Flow
      if (lowerText.contains("project")) {
        setState(() {
          messages.add(_ChatMessage(
            text: "Here are your projects:",
            isUser: false,
            options: [
              "Skyline Residency",
              "Green Valley Villa",
            ],
          ));
        });
      }

      // 🏗️ Project 1 Details
      else if (lowerText.contains("skyline")) {
        setState(() {
          messages.add(_ChatMessage(
            text:
                "Skyline Residency\n• Progress: 70%\n• Budget: ₹5CR used\n• Status: On Track",
            isUser: false,
          ));
        });
      }

      // 🏡 Project 2 Details
      else if (lowerText.contains("green valley")) {
        setState(() {
          messages.add(_ChatMessage(
            text:
                "Green Valley Villa\n• Progress: 55%\n• Budget: ₹3.5CR used\n• Status: Slight Delay",
            isUser: false,
          ));
        });
      }

      // 🔁 Default logic
      else {
        final reply = _getDummyResponse(text);

        setState(() {
          messages.add(_ChatMessage(
            text: reply,
            isUser: false,
          ));
        });
      }

      _scrollToBottom();
    });
  }

  String _getDummyResponse(String userText) {
    final text = userText.toLowerCase();

    // 👋 Greetings (ADD THIS FIRST)
    if (text.contains("hi") || text.contains("hello") || text.contains("hey")) {
      return "👋 Hey! I'm Saarthi.\nYour project assistant.\nHow can I help you today?";
    }

    // 🙌 How are you
    else if (text.contains("how are you")) {
      return "I'm doing great and ready to assist your project!";
    }

    // 📄 DPR
    else if (text.contains("dpr")) {
      return " Yes, today's DPR has been uploaded by Engineer Rahul at 5:30 PM.";
    }

    // 🚧 Progress
    else if (text.contains("progress") || text.contains("status")) {
      return " Project is 65% completed. Plumbing and interior work is ongoing.";
    }

    // ⚠️ Delay
    else if (text.contains("delay")) {
      return " Slight delay due to late cement delivery. Expected to recover by tomorrow.";
    }

    // 💰 Budget / Cost
    else if (text.contains("cost") || text.contains("budget")) {
      return " ₹7.2CR out of ₹10CR budget has been used. You're within budget.";
    }

    // 📝 Tasks
    else if (text.contains("task")) {
      return " Pending tasks:\n• Electrical wiring\n• Site inspection\n• Cement unloading";
    }

    // 👷 Engineer
    else if (text.contains("engineer")) {
      return "Engineer Rahul is currently on-site supervising slab work.";
    }

    // 🚚 Materials
    else if (text.contains("material") || text.contains("cement")) {
      return "Cement delivery is arriving today at 4 PM.";
    }

    // 📸 Photos / Updates
    else if (text.contains("photo") ||
        text.contains("image") ||
        text.contains("update")) {
      return "Latest site images uploaded. You can check the progress visually.";
    }

    // 📅 Timeline / Completion
    else if (text.contains("complete") || text.contains("finish")) {
      return "Expected project completion: 28 Feb 2026.";
    }

    // 👥 Workers
    else if (text.contains("worker") || text.contains("labour")) {
      return "12 workers are currently active on-site.";
    }

    // 🏗️ Site Info
    else if (text.contains("site")) {
      return "Work is ongoing smoothly at Site A. No major issues reported.";
    }

    // 🚨 Issues
    else if (text.contains("issue") || text.contains("problem")) {
      return "Minor issue: Delay in raw material supply. Manager has been notified.";
    }

    // 📊 Summary
    else if (text.contains("summary") || text.contains("report")) {
      return "Project Summary:\n• Progress: 65%\n• Budget Used: 72%\n• Status: On Track";
    }

    // 🙋 Default
    else {
      return "I understood: \"$userText\". Try asking about DPR, progress, cost, or tasks.";
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onVoiceTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("🎙 Voice input coming soon...")),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // ✅ TOP BAR (Back Arrow + Title)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(99),
                    onTap: () => Navigator.pop(context),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.arrow_back_ios_new_rounded, size: 22),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Saarthi Assistant",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Chat list
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  return _ChatBubble(
                    text: msg.text,
                    isUser: msg.isUser,
                    options: msg.options, // 👈 THIS LINE IS IMPORTANT
                  );
                },
              ),
            ),

            // Input bar
            _ChatInputBar(
              controller: _controller,
              onSend: _sendMessage,
              onVoice: _onVoiceTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final List<String>? options;

  _ChatMessage({
    required this.text,
    required this.isUser,
    this.options,
  });
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final List<String>? options; // 👈 ADD THIS

  const _ChatBubble({
    required this.text,
    required this.isUser,
    this.options, // 👈 ADD THIS
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // 💬 Message Bubble
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            decoration: BoxDecoration(
              color: isUser ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black12),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: isUser ? Colors.white : const Color(0xFF0F172A),
                fontSize: 15,
              ),
            ),
          ),

          // 📋 LIST OPTIONS (THIS IS YOUR FEATURE 🔥)
          if (options != null && !isUser)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: options!.map((option) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: () {
                        final state = context
                            .findAncestorStateOfType<_AssistantChatPageState>();

                        state?._controller.text = option;
                        state?._sendMessage();
                      },
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width *
                            0.65, // 👈 SAME WIDTH
                        child: Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(option),
                              const Icon(Icons.arrow_forward_ios, size: 14),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onVoice;

  const _ChatInputBar({
    required this.controller,
    required this.onSend,
    required this.onVoice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.black12),
        ),
      ),
      child: Row(
        children: [
          // 🎙 Voice button
          InkWell(
            borderRadius: BorderRadius.circular(99),
            onTap: onVoice,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: Colors.black12),
              ),
              child: const Icon(Icons.mic_rounded, size: 22),
            ),
          ),

          const SizedBox(width: 10),

          // Textfield
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 5,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: "Type a message...",
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.black12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.black12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.black45),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Send button
          InkWell(
            borderRadius: BorderRadius.circular(99),
            onTap: onSend,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(99),
              ),
              child:
                  const Icon(Icons.send_rounded, size: 22, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
