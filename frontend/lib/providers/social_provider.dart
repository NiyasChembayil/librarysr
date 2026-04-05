import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import 'auth_provider.dart';

/// Manages the following status of other users locally to ensure UI consistency.
class SocialNotifier extends StateNotifier<Map<String, bool>> {
  final ApiClient _apiClient;
  final Ref _ref;

  SocialNotifier(this._apiClient, this._ref) : super({});

  /// Toggles the follow status for a given profile ID and username.
  Future<void> toggleFollow(String username, int profileId) async {
    final currentlyFollowing = state[username] ?? false;
    
    // 1. Optimistic UI update
    state = {...state, username: !currentlyFollowing};
    
    // 2. Optimistic update of current user's profile stats
    _ref.read(authProvider.notifier).updateFollowingCount(currentlyFollowing ? -1 : 1);

    try {
      final response = await _apiClient.dio.post('accounts/profile/$profileId/follow/');
      final status = response.data['status'];
      
      // 3. Finalize state based on backend response
      state = {...state, username: status == 'followed'};
      
      debugPrint('Social: Successfully $status $username');
    } catch (e) {
      // 4. Revert optimistic updates on failure
      debugPrint('Social: Follow toggle failed for $username: $e');
      state = {...state, username: currentlyFollowing};
      _ref.read(authProvider.notifier).updateFollowingCount(currentlyFollowing ? 1 : -1);
    }
  }

  /// Manually set the following state (e.g., when a profile info is fetched from the server).
  void setFollowingStatus(String username, bool isFollowing) {
    if (state[username] == isFollowing) return;
    state = {...state, username: isFollowing};
  }
}

final socialProvider = StateNotifierProvider<SocialNotifier, Map<String, bool>>((ref) {
  return SocialNotifier(ref.read(apiClientProvider), ref);
});
