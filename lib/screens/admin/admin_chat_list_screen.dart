import 'package:clothesapp/screens/admin/admin_chat_detail_screen.dart';
import 'package:clothesapp/services/chat_service.dart';
import 'package:flutter/material.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Hội Thoại Khách Hàng",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
          ? const Center(child: Text("Chưa có hội thoại nào"))
          : RefreshIndicator(
              onRefresh: () async => _fetchConversations(),
              child: ListView.separated(
                itemCount: _conversations.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final conv = _conversations[index];
                  final lastTime = DateTime.fromMillisecondsSinceEpoch(
                    conv['lastTime'],
                  );
                  final timeStr = DateFormat('HH:mm dd/MM').format(lastTime);

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blueGrey[100],
                      child: Text(
                        conv['name'][0].toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      conv['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      conv['lastMessage'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      timeStr,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminChatDetailScreen(
                            token: widget.token,
                            userId: conv['userId'],
                            userName: conv['name'],
                          ),
                        ),
                      ).then((_) => _fetchConversations());
                    },
                  );
                },
              ),
            ),
    );
  }
}
