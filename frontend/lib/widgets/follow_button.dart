import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';

/// Reusable follow button for authors.
/// Communicates with the 'social/follows/' API endpoint.
class FollowButton extends ConsumerStatefulWidget {
  final String authorUsername;
  final bool isCompact;

  const FollowButton({
    super.key,
    required this.authorUsername,
    this.isCompact = false,
  });

  @override
  ConsumerState<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends ConsumerState<FollowButton> {
  bool isFollowing = false;
  bool _isLoading = false;

  Future<void> _toggleFollow() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(apiClientProvider).dio.post(
        'social/follows/',
        data: {'followed_username': widget.authorUsername},
      );
      setState(() => isFollowing = !isFollowing);
    } catch (_) {
      // Silently fail - but could show a Snackbar if needed
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: _isLoading ? null : _toggleFollow,
      style: OutlinedButton.styleFrom(
        foregroundColor: isFollowing ? Colors.grey : const Color(0xFF6C63FF),
        side: BorderSide(color: isFollowing ? Colors.grey : const Color(0xFF6C63FF)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: EdgeInsets.symmetric(
          horizontal: widget.isCompact ? 8 : 12,
          vertical: 0,
        ),
        minimumSize: Size(widget.isCompact ? 60 : 80, widget.isCompact ? 30 : 36),
      ),
      child: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6C63FF)),
            )
          : Text(
              isFollowing ? 'Following' : 'Follow',
              style: TextStyle(fontSize: widget.isCompact ? 11 : 12, fontWeight: FontWeight.bold),
            ),
    );
  }
}
