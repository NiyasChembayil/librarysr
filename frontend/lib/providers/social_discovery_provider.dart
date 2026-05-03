import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../models/profile_model.dart';
import '../models/post_model.dart';
import '../models/friend_activity_model.dart';

final socialDiscoveryProvider = StateNotifierProvider<SocialDiscoveryNotifier, SocialDiscoveryState>((ref) {
  return SocialDiscoveryNotifier(ref.read(apiClientProvider));
});

class SocialDiscoveryState {
  final List<ProfileModel> topCreators;
  final PostModel? pollOfTheDay;
  final List<FriendActivityModel> friendActivity;
  final bool isLoading;

  SocialDiscoveryState({
    this.topCreators = const [],
    this.pollOfTheDay,
    this.friendActivity = const [],
    this.isLoading = false,
  });

  SocialDiscoveryState copyWith({
    List<ProfileModel>? topCreators,
    PostModel? pollOfTheDay,
    List<FriendActivityModel>? friendActivity,
    bool? isLoading,
  }) {
    return SocialDiscoveryState(
      topCreators: topCreators ?? this.topCreators,
      pollOfTheDay: pollOfTheDay ?? this.pollOfTheDay,
      friendActivity: friendActivity ?? this.friendActivity,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SocialDiscoveryNotifier extends StateNotifier<SocialDiscoveryState> {
  final ApiClient _apiClient;

  SocialDiscoveryNotifier(this._apiClient) : super(SocialDiscoveryState());

  Future<void> fetchAll() async {
    state = state.copyWith(isLoading: true);
    try {
      final results = await Future.wait([
        _fetchTopCreators(),
        _fetchPollOfTheDay(),
        _fetchFriendActivity(),
      ]);

      state = SocialDiscoveryState(
        topCreators: results[0] as List<ProfileModel>,
        pollOfTheDay: results[1] as PostModel?,
        friendActivity: results[2] as List<FriendActivityModel>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<List<ProfileModel>> _fetchTopCreators() async {
    try {
      final response = await _apiClient.dio.get('social/posts/trending/');
      final List creators = response.data['top_creators'] ?? [];
      return creators.map((c) => ProfileModel.fromJson(c)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<PostModel?> _fetchPollOfTheDay() async {
    try {
      final response = await _apiClient.dio.get('social/posts/poll_of_the_day/');
      return PostModel.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  Future<List<FriendActivityModel>> _fetchFriendActivity() async {
    try {
      final response = await _apiClient.dio.get('core/books/friend_activity/');
      final List activity = response.data as List;
      return activity.map((a) => FriendActivityModel.fromJson(a)).toList();
    } catch (e) {
      return [];
    }
  }
}
