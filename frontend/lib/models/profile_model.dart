class ProfileModel {
  final String role;
  final String bio;
  final String? avatar;
  final int followersCount;

  ProfileModel({
    required this.role,
    required this.bio,
    this.avatar,
    required this.followersCount,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      role: json['role'] ?? 'reader',
      bio: json['bio'] ?? '',
      avatar: json['avatar'],
      followersCount: (json['followers'] as List?)?.length ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'bio': bio,
      'avatar': avatar,
      'followers_count': followersCount,
    };
  }
}
