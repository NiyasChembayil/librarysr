import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/notification_provider.dart';
import '../../providers/social_provider.dart';
import '../profile/profile_screen.dart';

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
    final groupedNotifs = _groupNotifications(notifications);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A12),
      appBar: AppBar(
        title: Text('Notifications', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => ref.read(notificationProvider.notifier).markAllRead(ref),
            icon: const Icon(Icons.done_all_rounded, color: Color(0xFF6C63FF)),
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: () => ref.read(notificationProvider.notifier).fetchNotifications(),
              color: const Color(0xFF6C63FF),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: groupedNotifs.entries.where((e) => e.value.isNotEmpty).map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 25, bottom: 15, left: 4),
                        child: Text(
                          entry.key.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white24,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      ...entry.value.map((notif) => _buildDismissibleNotification(notif)),
                    ],
                  );
                }).toList(),
              ),
            ),
    );
  }

  Widget _buildDismissibleNotification(dynamic notif) {
    return Dismissible(
      key: Key('notif_${notif['id']}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
      ),
      onDismissed: (direction) {
        // Optimistically remove from state
        // In a real app we'd call a delete API
      },
      child: _buildNotificationTile(notif),
    );
  }

  Widget _buildNotificationTile(dynamic notif) {
    final timeAgo = _getTimeAgo(notif['created_at']);
    final actorName = notif['actor_name'] ?? 'System';
    final initial = actorName.isNotEmpty ? actorName[0].toUpperCase() : 'S';
    final bool isUnread = !notif['is_read'];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isUnread ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isUnread ? const Color(0xFF6C63FF).withValues(alpha: 0.1) : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          // Avatar with Glow if Unread
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isUnread 
                  ? [const Color(0xFF6C63FF), const Color(0xFF00D2FF)]
                  : [Colors.white10, Colors.white10],
              ),
              shape: BoxShape.circle,
              boxShadow: isUnread ? [
                BoxShadow(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ] : null,
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (notif['actor'] != null) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(targetUserId: notif['actor'])));
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 14, height: 1.4),
                      children: [
                        TextSpan(text: actorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: _getActionText(notif['action_type'])),
                        if (notif['book_title'] != null && notif['action_type'] != 'LIKE')
                          TextSpan(text: ' "${notif['book_title']}"', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6C63FF))),
                      ],
                    ),
                  ),
                  if (notif['message'] != null && (notif['action_type'] == 'COMMENT' || notif['action_type'] == 'POST_COMMENT'))
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          notif['message'],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(timeAgo, style: GoogleFonts.inter(color: Colors.white24, fontSize: 11)),
                      if (isUnread) ...[
                        const SizedBox(width: 8),
                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF6C63FF), shape: BoxShape.circle)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (notif['action_type'] == 'FOLLOW')
            _buildFollowBackAction(notif)
          else
            _buildIconAction(notif),
        ],
      ),
    );
  }

  Widget _buildFollowBackAction(dynamic notif) {
    return Consumer(builder: (context, ref, _) {
      final followingMap = ref.watch(socialProvider);
      final isFollowing = followingMap[notif['actor_name']] ?? notif['is_following'] ?? false;
      
      return ElevatedButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          if (notif['actor_name'] != null && notif['actor_profile_id'] != null) {
            ref.read(socialProvider.notifier).toggleFollow(notif['actor_name'], notif['actor_profile_id']);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isFollowing ? Colors.white10 : const Color(0xFF6C63FF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          minimumSize: const Size(80, 32),
        ),
        child: Text(isFollowing ? 'Following' : 'Follow Back', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      );
    });
  }

  Widget _buildIconAction(dynamic notif) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
      child: Icon(_getNotificationIcon(notif['action_type']), color: _getNotificationColor(notif['action_type']), size: 16),
    );
  }

  String _getActionText(String? type) {
    switch (type) {
      case 'LIKE': return ' liked your book.';
      case 'POST_LIKE': return ' liked your post.';
      case 'POST_COMMENT_LIKE': return ' liked your comment.';
      case 'COMMENT': return ' commented:';
      case 'POST_COMMENT': return ' commented on your post.';
      case 'FOLLOW': return ' started following you.';
      case 'NEW_BOOK': return ' published a new book: ';
      case 'REPOST': return ' reposted your post.';
      case 'SYSTEM': return ''; // Message contains the full text
      default: return ' sent a notification. ';
    }
  }

  IconData _getNotificationIcon(String? type) {
    if (type == 'LIKE' || type == 'POST_LIKE' || type == 'POST_COMMENT_LIKE') return Icons.favorite_rounded;
    if (type == 'COMMENT' || type == 'POST_COMMENT') return Icons.comment_rounded;
    if (type == 'REPOST') return Icons.repeat_rounded;
    if (type == 'SYSTEM') return Icons.verified_rounded;
    return Icons.auto_stories_rounded;
  }

  Color _getNotificationColor(String? type) {
    if (type == 'LIKE' || type == 'POST_LIKE' || type == 'POST_COMMENT_LIKE') return Colors.redAccent;
    if (type == 'COMMENT' || type == 'POST_COMMENT') return Colors.blueAccent;
    if (type == 'REPOST') return Colors.greenAccent;
    if (type == 'SYSTEM') return const Color(0xFF00D2FF);
    return Colors.purpleAccent;
  }

  String _getTimeAgo(String? timestamp) {
    if (timestamp == null) return '1h';
    try {
      final date = DateTime.parse(timestamp);
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 7) return '${diff.inDays ~/ 7}w';
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
