import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/services/custom_http_client.dart';
import '../../../core/constants/app_colors.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/snackbar_utils.dart';

class NotificationScreen extends StatefulWidget {
  final String token;

  const NotificationScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _client = CustomHttpClient();
  bool _isLoading = true;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final response = await _client.get(Uri.parse(ApiConfig.getNotifications));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _notifications = data['data'];
          });
        }
      } else {
        _showError('Không thể tải thông báo.');
      }
    } catch (e) {
      _showError('Lỗi kết nối máy chủ.');
      debugPrint('Fetch notifications error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markAsRead(String id, String currentStatus) async {
    if (currentStatus == 'READ') return;

    try {
      final response = await _client.put(
        Uri.parse(ApiConfig.markNotificationRead),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'notificationIds': [id],
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          final index = _notifications.indexWhere((n) => n['id'] == id);
          if (index != -1) {
            _notifications[index]['status'] = 'READ';
          }
        });
      }
    } catch (e) {
      debugPrint('Mark as read error: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final response = await _client.put(
        Uri.parse(ApiConfig.markAllNotificationsRead),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() {
          for (var notif in _notifications) {
            notif['status'] = 'READ';
          }
        });
        SnackbarUtils.showSuccess(context, 'Đã đánh dấu tất cả là đã đọc');
      }
    } catch (e) {
      debugPrint('Mark all as read error: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  String _formatDate(String dateStr) {
    try {
      final DateTime dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (e) {
      return dateStr;
    }
  }

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'TRANSACTION':
        return Icons.swap_horiz_rounded;
      case 'SYSTEM':
        return Icons.info_outline_rounded;
      case 'PROMOTION':
        return Icons.card_giftcard_rounded;
      case 'SECURITY':
        return Icons.security_rounded;
      case 'CHAT':
        return Icons.chat_bubble_outline_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color _getColorForType(String? type) {
    switch (type) {
      case 'TRANSACTION':
        return Colors.green;
      case 'SYSTEM':
        return Colors.blue;
      case 'PROMOTION':
        return Colors.pink;
      case 'SECURITY':
        return Colors.orange;
      case 'CHAT':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Thông báo',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          if (_notifications.any((n) => n['status'] == 'UNREAD'))
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Đọc tất cả',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryPink),
            )
          : RefreshIndicator(
              onRefresh: _fetchNotifications,
              color: AppColors.primaryPink,
              child: _notifications.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        height: MediaQuery.of(context).size.height - 100,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_off_rounded,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có thông báo nào',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _notifications.length,
                      padding: const EdgeInsets.only(top: 8, bottom: 24),
                      itemBuilder: (context, index) {
                        final notif = _notifications[index];
                        final isUnread = notif['status'] == 'UNREAD';
                        final iconType = _getIconForType(
                          notif['notification_type'],
                        );
                        final iconColor = _getColorForType(
                          notif['notification_type'],
                        );

                        return GestureDetector(
                          onTap: () {
                            _markAsRead(notif['id'], notif['status']);
                            // Here you could add navigation to transaction detail if needed
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isUnread
                                  ? Colors.blue.withValues(alpha: 0.05)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isUnread
                                    ? Colors.blue.withValues(alpha: 0.3)
                                    : Colors.grey.withValues(alpha: 0.1),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: iconColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    iconType,
                                    color: iconColor,
                                    size: 24,
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
                                              notif['title'] ?? '',
                                              style: TextStyle(
                                                fontWeight: isUnread
                                                    ? FontWeight.bold
                                                    : FontWeight.w600,
                                                fontSize: 16,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                          if (isUnread)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: Colors.blue,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        notif['content'] ?? '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isUnread
                                              ? Colors.black87
                                              : Colors.black54,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        DateFormatter.format(
                                          notif['created_at'],
                                        ),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
