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
    final timeAgo = _getTimeAgo(notif['created_at']);
    final actorName = notif['actor_name'] ?? 'System';
    final initial = actorName.isNotEmpty ? actorName[0].toUpperCase() : 'S';

    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
      color: notif['is_read'] ? Colors.transparent : Colors.white.withValues(alpha: 0.05),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF00D2FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.3),
                children: [
                  TextSpan(text: actorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: _getActionText(notif['action_type'])),
                  if (notif['book_title'] != null && notif['action_type'] != 'LIKE')
                    TextSpan(text: notif['book_title'], style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white70)),
                  if (notif['message'] != null && notif['action_type'] == 'COMMENT')
                    TextSpan(text: ' "${notif['message']}"', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.white70)),
                  TextSpan(
                    text: '  $timeAgo',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          // Trailing Action/Indicator
          if (notif['action_type'] == 'FOLLOW')
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: notif['is_read'] ? Colors.white10 : const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                minimumSize: const Size(0, 32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(notif['is_read'] ? 'Following' : 'Follow Back', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            )
          else if (notif['action_type'] == 'LIKE' || notif['action_type'] == 'COMMENT' || notif['action_type'] == 'NEW_BOOK')
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                notif['action_type'] == 'LIKE' 
                    ? Icons.favorite_rounded 
                    : notif['action_type'] == 'COMMENT' ? Icons.comment_rounded : Icons.auto_stories_rounded,
                color: notif['action_type'] == 'LIKE' 
                    ? Colors.redAccent 
                    : notif['action_type'] == 'COMMENT' ? Colors.blueAccent : Colors.greenAccent,
                size: 20,
              ),
            ),
            
          if (!notif['is_read'] && notif['action_type'] != 'FOLLOW' && notif['action_type'] != 'LIKE' && notif['action_type'] != 'COMMENT')
            Container(width: 8, height: 8, margin: const EdgeInsets.only(left: 8), decoration: const BoxDecoration(color: Color(0xFF6C63FF), shape: BoxShape.circle)),
        ],
      ),
    );
  }

  String _getActionText(String? type) {
    switch (type) {
      case 'LIKE': return ' liked your book.';
      case 'COMMENT': return ' commented:';
      case 'FOLLOW': return ' started following you.';
      case 'NEW_BOOK': return ' published a new book: ';
      default: return ' sent a notification. ';
    }
  }

  String _getTimeAgo(String? timestamp) {
    if (timestamp == null) return '1h';
    try {
      final date = DateTime.parse(timestamp);
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 0) return '${diff.inDays}d';
      if (diff.inHours > 0) return '${diff.inHours}h';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m';
      return 'Just now';
    } catch (_) {
      return '2h';
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
