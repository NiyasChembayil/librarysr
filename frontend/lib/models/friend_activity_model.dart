class FriendActivityModel {
  final String username;
  final String? userAvatar;
  final int bookId;
  final String bookTitle;
  final String? bookCover;
  final DateTime timestamp;

  FriendActivityModel({
    required this.username,
    this.userAvatar,
    required this.bookId,
    required this.bookTitle,
    this.bookCover,
    required this.timestamp,
  });

  factory FriendActivityModel.fromJson(Map<String, dynamic> json) {
    String? avatar = json['user_avatar'];
    if (avatar != null && avatar.isNotEmpty && !avatar.startsWith('http')) {
      avatar = 'http://127.0.0.1:8000$avatar';
    }
    String? cover = json['book_cover'];
    if (cover != null && cover.isNotEmpty && !cover.startsWith('http')) {
      cover = 'http://127.0.0.1:8000$cover';
    }

    return FriendActivityModel(
      username: json['username'] ?? 'Someone',
      userAvatar: avatar,
      bookId: json['book_id'] ?? 0,
      bookTitle: json['book_title'] ?? 'a book',
      bookCover: cover,
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}
