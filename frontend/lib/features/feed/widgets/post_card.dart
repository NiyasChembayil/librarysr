import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/post_model.dart';
import '../../../providers/post_provider.dart';
import '../post_detail_screen.dart';
import '../../profile/profile_screen.dart';
import '../../book/book_detail_screen.dart';
import '../../book/reader_screen.dart';
import '../../../providers/book_provider.dart';
import '../../../providers/auth_provider.dart';
import 'audio_post_player.dart';

class PostCard extends ConsumerStatefulWidget {
  final PostModel post;
  const PostCard({super.key, required this.post});

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _heartController;
  bool _showBigHeart = false;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  void _onDoubleTap() {
    if (!widget.post.isLiked) {
      ref.read(postFeedProvider.notifier).toggleLike(widget.post);
    }
    setState(() => _showBigHeart = true);
    _heartController.forward(from: 0).then((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _showBigHeart = false);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return GestureDetector(
      onDoubleTap: _onDoubleTap,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF14141E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author row
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileScreen(targetUserId: post.userId),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFF6C63FF),
                          backgroundImage: post.userAvatar != null
                              ? NetworkImage(post.userAvatar!)
                              : null,
                          child: post.userAvatar == null
                              ? Text(
                                  post.username.isNotEmpty
                                      ? post.username[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    post.username,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (post.isVerified)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 4),
                                      child: Icon(
                                        Icons.verified_rounded,
                                        color: Color(0xFF00D2FF),
                                        size: 14,
                                      ),
                                    ),
                                ],
                              ),
                              Text(
                                post.timeAgo,
                                style: TextStyle(
                                    color: Colors.grey[500], fontSize: 12),
                               ),
                            ],
                          ),
                        ),
                        if (ref.watch(authProvider).profile?.userId == post.userId)
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_horiz, color: Colors.grey[600]),
                            color: const Color(0xFF1E1E2E),
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showEditDialog(context, ref, post);
                              } else if (value == 'delete') {
                                _showPostDeleteDialog(context, ref, post);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit Post', style: TextStyle(color: Colors.white)),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete Post', style: TextStyle(color: Colors.redAccent)),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Repost (parent post)
                  if (post.parentPost != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF6C63FF).withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '↩️ ${post.parentPost!.username}',
                            style: const TextStyle(
                                color: Color(0xFF6C63FF),
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            post.parentPost!.text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Post text & Media content
                  if (post.postType == 'QUOTE')
                    Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2A2D3E), Color(0xFF1E1E2E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.format_quote_rounded, color: Color(0xFF6C63FF), size: 30),
                          const SizedBox(height: 8),
                          Text(
                            post.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (post.bookId != null)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () async {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Opening book...'), duration: Duration(seconds: 1)),
                                  );
                                  
                                  final book = await ref.read(currentBookProvider(post.bookId!).future);
                                  if (book != null && context.mounted) {
                                    int initialIndex = 0;
                                    if (post.chapterId != null) {
                                      initialIndex = book.chapters.indexWhere((c) => c.id == post.chapterId);
                                      if (initialIndex == -1) initialIndex = 0;
                                    }
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => ReaderScreen(
                                      bookId: book.id,
                                      title: book.title,
                                      chapters: book.chapters,
                                      initialChapterIndex: initialIndex,
                                    )));
                                  }
                                },
                                icon: const Icon(Icons.auto_stories_rounded, color: Color(0xFF6C63FF), size: 18),
                                label: const Text(
                                  'Continue Reading',
                                  style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
                      ),
                    )
                  else if (post.postType == 'AUDIO')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (post.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: MentionRichText(
                              text: post.text,
                              onProfileTap: (id) => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(targetUserId: int.tryParse(id)))),
                              onBookTap: (id) {
                                final bookId = int.tryParse(id);
                                if (bookId != null) Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailScreen(id: bookId, title: '', author: '', coverUrl: '', description: '')));
                              },
                            ),
                          ),
                        if (post.audioUrl != null)
                          AudioPostPlayer(audioUrl: post.audioUrl!),
                        const SizedBox(height: 8),
                      ],
                    )
                  else if (post.postType == 'POLL' && post.poll != null)
                    _buildPollWidget(post.poll!)
                  else if (post.text.isNotEmpty)
                    MentionRichText(
                      text: post.text,
                      onProfileTap: (id) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfileScreen(targetUserId: int.tryParse(id)),
                          ),
                        );
                      },
                      onBookTap: (id) {
                        final bookId = int.tryParse(id);
                        if (bookId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookDetailScreen(
                                id: bookId,
                                title: '', 
                                author: '',
                                coverUrl: '',
                                description: '',
                              ),
                            ),
                          );
                        }
                      },
                    ),

                  // Rich Media Book Preview
                  if (post.bookId != null && post.postType != 'QUOTE')
                    _buildBookPreview(post.bookId!, post.bookTitle ?? 'Book', post.bookCover),

                  const SizedBox(height: 14),
                  // Action bar
                  Row(
                    children: [
                      _ActionButton(
                        icon: post.isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: post.isLiked
                            ? const Color(0xFFFF6584)
                            : Colors.grey,
                        count: post.likesCount,
                        onTap: () async {
                          try {
                            await ref.read(postFeedProvider.notifier).toggleLike(post);
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Login required to like posts'),
                                backgroundColor: Color(0xFFFF6584),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 20),
                      _ActionButton(
                        icon: Icons.chat_bubble_outline_rounded,
                        color: Colors.grey,
                        count: post.commentsCount,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => PostDetailScreen(post: post)),
                        ),
                      ),
                      const SizedBox(width: 20),
                      _ActionButton(
                        icon: Icons.repeat_rounded,
                        color: Colors.grey,
                        count: post.repostsCount,
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              backgroundColor: const Color(0xFF1E1E2E),
                              title: const Text('Repost?',
                                  style: TextStyle(color: Colors.white)),
                              content: const Text(
                                'Share this post with your followers?',
                                style: TextStyle(color: Colors.white70),
                              ),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel')),
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Repost',
                                        style: TextStyle(
                                            color: Color(0xFF6C63FF)))),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            try {
                              await ref.read(postFeedProvider.notifier).repost(post);
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Login required to repost'),
                                  backgroundColor: Color(0xFF6C63FF),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Double-tap heart animation
            if (_showBigHeart)
              Positioned.fill(
                child: Center(
                  child: ScaleTransition(
                    scale: CurvedAnimation(
                      parent: _heartController,
                      curve: Curves.elasticOut,
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Color(0xFFFF6584),
                      size: 80,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, PostModel post) {
    final controller = TextEditingController(text: post.text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text('Edit Post', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          maxLines: 5,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'What\'s on your mind?',
            hintStyle: TextStyle(color: Colors.grey[600]),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
            onPressed: () async {
              try {
                await ref.read(postFeedProvider.notifier).editPost(post.id, controller.text);
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Post updated'))
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update post: $e'))
                );
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPostDeleteDialog(BuildContext context, WidgetRef ref, PostModel post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text('Delete Post?', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this post?', 
          style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              try {
                await ref.read(postFeedProvider.notifier).deletePost(post.id);
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Post deleted'))
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete post: $e'))
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildPollWidget(PollModel poll) {
    bool hasVoted = poll.userVotedOptionId != null;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            poll.question,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...poll.options.map((option) {
            double percentage = poll.totalVotes > 0 ? (option.votesCount / poll.totalVotes) : 0;
            bool isSelected = poll.userVotedOptionId == option.id;

            return GestureDetector(
              onTap: () => ref.read(postFeedProvider.notifier).vote(widget.post.id, option.id),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                height: 48,
                child: Stack(
                  children: [
                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: hasVoted ? percentage : 0,
                        backgroundColor: Colors.white.withValues(alpha: 0.03),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isSelected ? const Color(0xFF6C63FF).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.1),
                        ),
                        minHeight: 48,
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              option.text,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white70,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (hasVoted)
                            Text(
                              '${(percentage * 100).toInt()}%',
                              style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
          Text(
            '${poll.totalVotes} votes',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildBookPreview(int bookId, String title, String? coverUrl) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Book Cover
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: coverUrl != null
                ? Image.network(
                    coverUrl,
                    width: 60,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholderCover(),
                  )
                : _buildPlaceholderCover(),
          ),
          const SizedBox(width: 16),
          // Book Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.post.bookRating ?? 4.8}',
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => BookDetailScreen(
                                  id: bookId,
                                  title: title,
                                  author: '',
                                  coverUrl: coverUrl ?? '',
                                  description: '')),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 32),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Read Now', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        ref.read(bookProvider.notifier).toggleLibrary(bookId, ref);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Library updated!')),
                        );
                      },
                      icon: const Icon(Icons.library_add_rounded,
                          color: Colors.white70, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(32, 32),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderCover() {
    return Container(
      width: 60,
      height: 90,
      color: Colors.grey[900],
      child: const Icon(Icons.book_rounded, color: Colors.white24, size: 30),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int count;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
                color: Colors.grey[400], fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MentionRichText — renders @username (purple) and @[Book Title] (gold) spans
// ─────────────────────────────────────────────────────────────────────────────

class MentionRichText extends StatelessWidget {
  final String text;
  final void Function(String id)? onProfileTap;
  final void Function(String id)? onBookTap;

  const MentionRichText({
    super.key,
    required this.text,
    this.onProfileTap,
    this.onBookTap,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      _buildSpans(text),
      style: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 15,
        height: 1.5,
      ),
    );
  }

  TextSpan _buildSpans(String input) {
    final spans = <InlineSpan>[];
    // Matches structured tokens: @{ID|label} or @[ID|label]
    // Group 1: User ID, Group 2: Username
    // Group 3: Book ID, Group 4: Book Title
    final pattern = RegExp(r'@\{(\d+)\|([^}]+)\}|@\[(\d+)\|([^\]]+)\]');
    int lastEnd = 0;

    for (final match in pattern.allMatches(input)) {
      // Plain text before this match
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: input.substring(lastEnd, match.start)));
      }

      final userId = match.group(1);
      final username = match.group(2);
      final bookId = match.group(3);
      final bookTitle = match.group(4);

      if (userId != null) {
        spans.add(TextSpan(
          text: '@$username',
          style: const TextStyle(
            color: Color(0xFF6C63FF),
            fontWeight: FontWeight.bold,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => onProfileTap?.call(userId),
        ));
      } else if (bookId != null) {
        spans.add(TextSpan(
          text: '@$bookTitle',
          style: const TextStyle(
            color: Color(0xFFFFD700),
            fontWeight: FontWeight.bold,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => onBookTap?.call(bookId),
        ));
      }

      lastEnd = match.end;
    }

    // Trailing plain text
    if (lastEnd < input.length) {
      spans.add(TextSpan(text: input.substring(lastEnd)));
    }

    return TextSpan(children: spans);
  }
}

