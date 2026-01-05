import 'dart:async';
import 'package:clothesapp/services/chat_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final String token;
  const ChatScreen({super.key, required this.user, required this.token});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  Timer? _timer;
  bool _isLoading = true;

  // Admin ID (backend logic usually handles 'admin' alias, but helps to know)
  final String adminId = 'admin';

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    // Poll for new messages every 3 seconds
    _timer = Timer.periodic(
      const Duration(seconds: 3),
      (timer) => _fetchMessages(showLoading: false),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoading = true);
    final data = await _chatService.getChatHistory(adminId, widget.token);

    if (mounted) {
      if (data.length != _messages.length || showLoading) {
        setState(() {
          _messages = data;
          _isLoading = false;
        });
        // Scroll to bottom if it's the first load or new messages
        if (showLoading || data.length > _messages.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.jumpTo(
                _scrollController.position.maxScrollExtent,
              );
            }
          });
        }
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    // Optimistically add message
    final tempMsg = ChatMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      senderId: widget.user['_id'] ?? 'user', // Fallback if ID missing
      receiverId: adminId,
      text: text,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    setState(() {
      _messages.add(tempMsg);
    });

    _scrollToBottom();

    final success = await _chatService.sendMessage(adminId, text, widget.token);
    if (!success) {
      // Handle failure (e.g., remove message or show error)
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Gửi tin nhắn thất bại")));
        setState(() {
          _messages.remove(tempMsg);
        });
      }
    } else {
      // Refresh to get actual ID etc.
      _fetchMessages(showLoading: false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: theme.colorScheme.onSurface,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: theme.cardColor,
              child: Icon(
                Icons.support_agent,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hỗ trợ Admin",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Trực tuyến",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.greenAccent,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _fetchMessages(),
            icon: Icon(Icons.refresh, color: theme.colorScheme.onSurface),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.white.withOpacity(0.05), height: 1.0),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                  )
                : _messages.isEmpty
                ? _buildEmptyState(theme)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      // Backend returns senderId.
                      final currentUserId =
                          widget.user['_id'] ?? widget.user['id'];
                      // Sometimes backend uses '_id', sometimes 'id', handle gracefully?
                      // Assuming standard is '_id' based on previous files.

                      final isMe =
                          msg.senderId == currentUserId ||
                          msg.senderId == 'user';
                      // 'user' is fallback in sendMessage optimistically

                      // Check if previous message was same user for grouping (optional but nice)
                      bool isSequence =
                          index > 0 &&
                          _messages[index - 1].senderId == msg.senderId;

                      return _buildMessageBubble(msg, isMe, isSequence, theme);
                    },
                  ),
          ),
          _buildInputArea(theme),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 60,
              color: theme.disabledColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Chưa có tin nhắn nào",
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 8),
          Text(
            "Hãy bắt đầu trò chuyện với chúng tôi!",
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white38),
          ),
        ],
      ).animate().fade().scale(),
    );
  }

  Widget _buildMessageBubble(
    ChatMessage msg,
    bool isMe,
    bool isSequence,
    ThemeData theme,
  ) {
    final timeStr = DateFormat(
      'HH:mm',
    ).format(DateTime.fromMillisecondsSinceEpoch(msg.createdAt));

    return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.only(
              top: isSequence ? 4 : 16,
              bottom: 2,
              left: isMe ? 50 : 0,
              right: isMe ? 0 : 50,
            ),
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isMe
                        ? theme
                              .colorScheme
                              .primary // Gold for me
                        : theme.cardColor, // Dark Card for admin
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isMe
                          ? const Radius.circular(16)
                          : Radius.zero,
                      bottomRight: isMe
                          ? Radius.zero
                          : const Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                    border: isMe
                        ? null
                        : Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Text(
                    msg.text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isMe ? Colors.black : Colors.white,
                      fontWeight: isMe ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Text(
                    timeStr,
                    style: TextStyle(color: Colors.white30, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fade(duration: 300.ms)
        .slideX(begin: isMe ? 0.2 : -0.2, end: 0, curve: Curves.easeOut);
  }

  Widget _buildInputArea(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: TextField(
                  controller: _messageController,
                  style: theme.textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: "Nhập tin nhắn...",
                    hintStyle: TextStyle(color: Colors.white38),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _sendMessage,
              child:
                  Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.black,
                          size: 24,
                        ),
                      )
                      .animate(
                        target: _messageController.text.isNotEmpty ? 1 : 0,
                      )
                      .scale(
                        begin: const Offset(0.9, 0.9),
                        end: const Offset(1.1, 1.1),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
