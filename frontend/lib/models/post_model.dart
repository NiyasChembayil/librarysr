import '../core/media_service.dart';

class PostAuthor {
  final int id;
  final String username;
  final String? avatarUrl;

  PostAuthor({required this.id, required this.username, this.avatarUrl});

  factory PostAuthor.fromJson(Map<String, dynamic> json) {
    return PostAuthor(
      id: json['user'] ?? 0,
      username: json['username'] ?? 'unknown',
      avatarUrl: MediaService.sanitizeUrl(json['user_avatar']),
    );
  }

  PostAuthor copyWith({
    int? id,
    String? username,
    String? avatarUrl,
  }) {
    return PostAuthor(
      id: id ?? this.id,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

class PostModel {
  final int id;
  final int userId;
  final String username;
  final String? userAvatar;
  final String text;
  final String postType; // REVIEW, QUOTE, OPINION, UPDATE
  final int? bookId;
  final String? bookTitle;
  final String? bookCover;
  final int? chapterId;
  final String? audioUrl;
  final PostModel? parentPost;
  final DateTime createdAt;
  final int likesCount;
  final int commentsCount;
  final int repostsCount;
  final bool isLiked;
  final bool isVerified;
  final PollModel? poll;

  PostModel({
    required this.id,
    required this.userId,
    required this.username,
    this.userAvatar,
    required this.text,
    required this.postType,
    this.bookId,
    this.bookTitle,
    this.bookCover,
    this.chapterId,
    this.audioUrl,
    this.parentPost,
    required this.createdAt,
    required this.likesCount,
    required this.commentsCount,
    required this.repostsCount,
    required this.isLiked,
    this.isVerified = false,
    this.poll,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    PostModel? parent;
    if (json['parent_post_data'] != null) {
      parent = PostModel.fromJson(json['parent_post_data']);
    }

    return PostModel(
      id: json['id'],
      userId: json['user'] ?? 0,
      username: json['username'] ?? 'unknown',
      userAvatar: MediaService.sanitizeUrl(json['user_avatar']),
      text: json['text'] ?? '',
      postType: json['post_type'] ?? 'UPDATE',
      bookId: json['book'],
      bookTitle: json['book_title'],
      bookCover: MediaService.sanitizeUrl(json['book_cover']),
      chapterId: json['chapter_id'],
      audioUrl: MediaService.sanitizeUrl(json['audio_file']),
      parentPost: parent,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      repostsCount: json['reposts_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
      isVerified: json['is_verified'] ?? false,
      poll: json['poll'] != null ? PollModel.fromJson(json['poll']) : null,
    );
  }

  PostModel copyWith({
    int? id,
    int? userId,
    String? username,
    String? userAvatar,
    String? text,
    String? postType,
    int? bookId,
    String? bookTitle,
    String? bookCover,
    int? chapterId,
    String? audioUrl,
    PostModel? parentPost,
    DateTime? createdAt,
    int? likesCount,
    int? commentsCount,
    int? repostsCount,
    bool? isLiked,
    PollModel? poll,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userAvatar: userAvatar ?? this.userAvatar,
      text: text ?? this.text,
      postType: postType ?? this.postType,
      bookId: bookId ?? this.bookId,
      bookTitle: bookTitle ?? this.bookTitle,
      bookCover: bookCover ?? this.bookCover,
      chapterId: chapterId ?? this.chapterId,
      audioUrl: audioUrl ?? this.audioUrl,
      parentPost: parentPost ?? this.parentPost,
      createdAt: createdAt ?? this.createdAt,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      repostsCount: repostsCount ?? this.repostsCount,
      isLiked: isLiked ?? this.isLiked,
      isVerified: isVerified ?? this.isVerified,
      poll: poll ?? this.poll,
    );
  }

  String get postTypeLabel {
    switch (postType) {
      case 'REVIEW':
        return '⭐ Review';
      case 'QUOTE':
        return '💬 Quote';
      case 'OPINION':
        return '🗣 Opinion';
      case 'UPDATE':
        return '📖 Update';
      case 'POLL':
        return '📊 Poll';
      case 'MILESTONE':
        return '🎉 Milestone';
      default:
        return '📝 Post';
    }
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class PostCommentModel {
  final int id;
  final int userId;
  final String username;
  final String? userAvatar;
  final int postId;
  final String text;
  final DateTime createdAt;
  final int likesCount;
  final bool isLiked;

  PostCommentModel({
    required this.id,
    required this.userId,
    required this.username,
    this.userAvatar,
    required this.postId,
    required this.text,
    required this.createdAt,
    this.likesCount = 0,
    this.isLiked = false,
  });

  factory PostCommentModel.fromJson(Map<String, dynamic> json) {
    return PostCommentModel(
      id: json['id'],
      userId: json['user'] ?? 0,
      username: json['username'] ?? 'unknown',
      userAvatar: MediaService.sanitizeUrl(json['user_avatar']),
      postId: json['post'] ?? 0,
      text: json['text'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      likesCount: json['likes_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
    );
  }

  PostCommentModel copyWith({
    int? id,
    int? userId,
    String? username,
    String? userAvatar,
    int? postId,
    String? text,
    DateTime? createdAt,
    int? likesCount,
    bool? isLiked,
  }) {
    return PostCommentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userAvatar: userAvatar ?? this.userAvatar,
      postId: postId ?? this.postId,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}

class PollModel {
  final int id;
  final String question;
  final List<PollOptionModel> options;
  final DateTime? expiresAt;
  final int? userVotedOptionId;
  final int totalVotes;

  PollModel({
    required this.id,
    required this.question,
    required this.options,
    this.expiresAt,
    this.userVotedOptionId,
    required this.totalVotes,
  });

  factory PollModel.fromJson(Map<String, dynamic> json) {
    return PollModel(
      id: json['id'] ?? 0,
      question: json['question'] ?? '',
      options: (json['options'] as List? ?? [])
          .map((o) => PollOptionModel.fromJson(o))
          .toList(),
      expiresAt: DateTime.tryParse(json['expires_at'] ?? ''),
      userVotedOptionId: json['user_voted_option_id'],
      totalVotes: json['total_votes'] ?? 0,
    );
  }
}

class PollOptionModel {
  final int id;
  final String text;
  final int votesCount;

  PollOptionModel({
    required this.id,
    required this.text,
    required this.votesCount,
  });

  factory PollOptionModel.fromJson(Map<String, dynamic> json) {
    return PollOptionModel(
      id: json['id'] ?? 0,
      text: json['text'] ?? '',
      votesCount: json['votes_count'] ?? 0,
    );
  }
}
