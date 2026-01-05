import 'package:clothesapp/screens/admin/admin_chat_detail_screen.dart';
import 'package:clothesapp/services/chat_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class AdminChatListScreen extends StatefulWidget {
  final String token;
  const AdminChatListScreen({super.key, required this.token});

  @override
  State<AdminChatListScreen> createState() => _AdminChatListScreenState();
}

class _AdminChatListScreenState extends State<AdminChatListScreen> {
  final ChatService _chatService = ChatService();
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchConversations();
  }

  void _fetchConversations() async {
    setState(() => _isLoading = true);
    final data = await _chatService.getAdminConversations(widget.token);
    if (mounted) {
      setState(() {
        _conversations = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Tin Nhắn Khách Hàng",
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: theme.iconTheme,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : _conversations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.white24,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Chưa có tin nhắn nào",
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.all(16),
              itemCount: _conversations.length,
              separatorBuilder: (_, __) => SizedBox(height: 12),
              itemBuilder: (context, index) {
                final conv = _conversations[index];
                DateTime? lastTime;
                if (conv['lastTime'] is int) {
                  lastTime = DateTime.fromMillisecondsSinceEpoch(
                    conv['lastTime'],
                  );
                } else if (conv['lastTime'] is String) {
                  lastTime = DateTime.tryParse(conv['lastTime']);
                }

                final timeStr = lastTime != null
                    ? DateFormat('HH:mm dd/MM').format(lastTime.toLocal())
                    : "";

                return Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(12),
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundColor: theme.colorScheme.primary
                              .withOpacity(0.2),
                          child: Text(
                            (conv['name']?.toString() ?? 'U')[0].toUpperCase(),
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        title: Text(
                          conv['name']?.toString() ?? 'Unknown',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (conv['lastMessage'] != null) ...[
                              SizedBox(height: 4),
                              Text(
                                conv['lastMessage']?.toString() ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              timeStr,
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.white24,
                              size: 20,
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdminChatDetailScreen(
                                token: widget.token,
                                userId: conv['userId']?.toString() ?? '',
                                userName: conv['name']?.toString() ?? 'Unknown',
                              ),
                            ),
                          ).then((_) => _fetchConversations());
                        },
                      ),
                    )
                    .animate()
                    .fadeIn(delay: (50 * index).ms)
                    .slideX(begin: -0.1, end: 0);
              },
            ),
    );
  }
}
