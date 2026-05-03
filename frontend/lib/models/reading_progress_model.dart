class ReadingProgressModel {
  final int bookId;
  final String bookTitle;
  final String? bookCover;
  final String authorName;
  final int chapterIndex;
  final int totalChapters;
  final DateTime updatedAt;

  ReadingProgressModel({
    required this.bookId,
    required this.bookTitle,
    this.bookCover,
    required this.authorName,
    required this.chapterIndex,
    required this.totalChapters,
    required this.updatedAt,
  });

  factory ReadingProgressModel.fromJson(Map<String, dynamic> json) {
    String? cover = json['book_cover'];
    if (cover != null && cover.isNotEmpty && !cover.startsWith('http')) {
      cover = 'http://127.0.0.1:8000$cover';
    }

    return ReadingProgressModel(
      bookId: json['book_id'],
      bookTitle: json['book_title'],
      bookCover: cover,
      authorName: json['author_name'] ?? 'Unknown',
      chapterIndex: json['chapter_index'] ?? 0,
      totalChapters: json['total_chapters'] ?? 0,
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  double get progressPercentage {
    if (totalChapters == 0) return 0;
    return (chapterIndex + 1) / totalChapters;
  }
}
