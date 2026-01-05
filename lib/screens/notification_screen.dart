import 'package:clothesapp/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

class NotificationScreen extends StatefulWidget {
  final String token;
  const NotificationScreen({super.key, required this.token});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final data = await _notificationService.getNotifications(widget.token);
    if (mounted) {
      setState(() {
        _notifications = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(String id) async {
    final success = await _notificationService.markAsRead(widget.token, id);
    if (success) {
      // Optimistically update local state or reload
      setState(() {
        final index = _notifications.indexWhere((n) => n['_id'] == id);
        if (index != -1) {
          _notifications[index]['status'] = 'read';
        }
      });
    }
  }

  Future<void> _markAllAsRead() async {
    final success = await _notificationService.markAllAsRead(widget.token);
    if (success) {
      _loadNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Thông Báo',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: theme.iconTheme,
        actions: [
          if (_notifications.isNotEmpty)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Đã đọc tất cả',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        color: theme.colorScheme.primary,
        backgroundColor: theme.cardColor,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _notifications.isEmpty
            ? _buildEmptyState(theme)
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final item = _notifications[index];
                  final isUnread = item['status'] == 'unread';
                  final date = DateTime.parse(item['createdAt']);
                  final timeStr = DateFormat(
                    'HH:mm - dd/MM/yyyy',
                  ).format(date.toLocal());

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () {
                        if (isUnread) _markAsRead(item['_id']);
                      },
                      child:
                          Container(
                                decoration: BoxDecoration(
                                  color: isUnread
                                      ? theme.colorScheme.primary.withOpacity(
                                          0.05,
                                        )
                                      : theme.cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isUnread
                                        ? theme.colorScheme.primary.withOpacity(
                                            0.3,
                                          )
                                        : Colors.white.withOpacity(0.05),
                                  ),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: _getIconColor(
                                          item['title'],
                                        ).withOpacity(0.2),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _getIconColor(
                                            item['title'],
                                          ).withOpacity(0.5),
                                        ),
                                      ),
                                      child: Icon(
                                        _getIcon(item['title']),
                                        color: _getIconColor(item['title']),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  item['title'],
                                                  style: theme
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        fontWeight: isUnread
                                                            ? FontWeight.bold
                                                            : FontWeight.w600,
                                                        color: isUnread
                                                            ? Colors.white
                                                            : Colors.white70,
                                                      ),
                                                ),
                                              ),
                                              if (isUnread)
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  margin: const EdgeInsets.only(
                                                    left: 8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: theme
                                                        .colorScheme
                                                        .primary,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            item['message'],
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: Colors.white54,
                                                  height: 1.4,
                                                ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            timeStr,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: Colors.white30,
                                                  fontSize: 11,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              .animate()
                              .fadeIn(duration: 300.ms)
                              .slideY(begin: 0.1, end: 0),
                    ),
                  );
                },
              ),
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
              Icons.notifications_none_outlined,
              size: 60,
              color: theme.disabledColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Chưa có thông báo nào',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.disabledColor,
            ),
          ),
        ],
      ).animate().fade().scale(),
    );
  }

  IconData _getIcon(String title) {
    String lowerId = title.toLowerCase();
    if (lowerId.contains('thành công')) return Icons.check_circle_outline;
    if (lowerId.contains('đang giao')) return Icons.local_shipping_outlined;
    if (lowerId.contains('hủy')) return Icons.cancel_outlined;
    if (lowerId.contains('khuyến mãi')) return Icons.local_offer_outlined;
    return Icons.info_outline;
  }

  Color _getIconColor(String title) {
    String lowerId = title.toLowerCase();
    if (lowerId.contains('thành công')) return Colors.greenAccent;
    if (lowerId.contains('đang giao')) return Colors.blueAccent;
    if (lowerId.contains('hủy')) return Colors.redAccent;
    if (lowerId.contains('khuyến mãi')) return Colors.amber;
    return Colors.white;
  }
}
