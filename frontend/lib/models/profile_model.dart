class ProfileModel {
  final int id;
  final String username;
  final String role;
  final String bio;
  final String? avatar;
  final int followersCount;
  final int followingCount;

  ProfileModel({
    required this.id,
    required this.username,
    required this.role,
    required this.bio,
    this.avatar,
    required this.followersCount,
    required this.followingCount,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    // The profile endpoint nests data; handle both flat and nested user data
    final user = json['user'] as Map<String, dynamic>?;

    return ProfileModel(
      id: json['id'] ?? 0,
      username: user?['username'] ?? json['username'] ?? 'User',
      role: json['role'] ?? 'reader',
      bio: json['bio'] ?? '',
      avatar: json['avatar'],
      // 'followed_by' is the correct field name on the model
      followersCount: (json['followed_by'] as List?)?.length ?? json['followers_count'] ?? 0,
      followingCount: json['following_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'role': role,
      'bio': bio,
      'avatar': avatar,
      'followers_count': followersCount,
      'following_count': followingCount,
    };
  }
}
