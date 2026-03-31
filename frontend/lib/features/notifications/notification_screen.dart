import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/notification_provider.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(notificationProvider.notifier).fetchNotifications());
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => ref.read(notificationProvider.notifier).markAllRead(),
            icon: const Icon(Icons.done_all_rounded, color: Color(0xFF6C63FF)),
          ),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return _buildNotificationTile(notif);
              },
            ),
    );
  }

  Widget _buildNotificationTile(dynamic notif) {
    IconData icon;
    Color color;

    switch (notif['action_type']) {
      case 'LIKE':
        icon = Icons.favorite_rounded;
        color = Colors.redAccent;
        break;
      case 'COMMENT':
        icon = Icons.comment_rounded;
        color = Colors.blueAccent;
        break;
      case 'NEW_BOOK':
        icon = Icons.auto_stories_rounded;
        color = Colors.greenAccent;
        break;
      case 'FOLLOW':
        icon = Icons.person_add_rounded;
        color = const Color(0xFF00D2FF);
        break;
      default:
        icon = Icons.notifications_rounded;
        color = const Color(0xFF6C63FF);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: notif['is_read'] ? Colors.white.withValues(alpha: 0.02) : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: notif['is_read'] ? Colors.transparent : Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    children: [
                      TextSpan(text: notif['actor_name'] ?? 'System', style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: _getActionText(notif['action_type'])),
                      if (notif['book_title'] != null)
                        TextSpan(text: notif['book_title'], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00D2FF))),
                    ],
                  ),
                ),
                if (notif['message'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(notif['message'], style: const TextStyle(color: Colors.white54, fontSize: 13)),
                  ),
                const SizedBox(height: 5),
                Text('2 hours ago', style: const TextStyle(color: Colors.white24, fontSize: 11)),
              ],
            ),
          ),
          if (!notif['is_read'])
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF6C63FF), shape: BoxShape.circle)),
        ],
      ),
    );
  }

  String _getActionText(String? type) {
    switch (type) {
      case 'LIKE': return ' liked ';
      case 'COMMENT': return ' commented on ';
      case 'FOLLOW': return ' started following you';
      case 'NEW_BOOK': return ' published a new book: ';
      default: return ' sent a notification ';
    }
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded, size: 80, color: Colors.white10),
          SizedBox(height: 15),
          Text('All caught up!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white24)),
          Text('No new notifications for you.', style: TextStyle(color: Colors.white10)),
        ],
      ),
    );
  }
}
