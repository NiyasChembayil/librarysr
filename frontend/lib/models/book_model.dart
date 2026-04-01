class BookModel {
  final int id;
  final String title;
  final String authorName;
  final String coverUrl;
  final String description;
  final double price;
  final int likesCount;
  final int totalReads;
  final List<ChapterModel> chapters;
  final List<String> pages;

  BookModel({
    required this.id,
    required this.title,
    required this.authorName,
    required this.coverUrl,
    required this.description,
    required this.price,
    required this.likesCount,
    required this.totalReads,
    required this.chapters,
    this.pages = const [],
  });

  factory BookModel.fromJson(Map<String, dynamic> json) {
    return BookModel(
      id: json['id'],
      title: json['title'],
      authorName: json['author_name'] ?? 'Unknown Author',
      coverUrl: json['cover'] ?? '',
      description: json['description'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      likesCount: json['likes_count'] ?? 0,
      totalReads: json['total_reads'] ?? 0,
      chapters: (json['chapters'] as List? ?? [])
          .map((c) => ChapterModel.fromJson(c))
          .toList(),
      pages: (json['pages'] as List? ?? [])
          .map((p) => p.toString())
          .toList(),
    );
  }
}

class ChapterModel {
  final int id;
  final String title;
  final String content;
  final String? audioUrl;

  ChapterModel({
    required this.id,
    required this.title,
    required this.content,
    this.audioUrl,
  });

  factory ChapterModel.fromJson(Map<String, dynamic> json) {
    return ChapterModel(
      id: json['id'],
      title: json['title'],
      content: json['content'] ?? '',
      audioUrl: json['audio_file'],
    );
  }
}
