class GenreDna {
  final String genre;
  final int count;

  GenreDna({required this.genre, required this.count});

  factory GenreDna.fromJson(Map<String, dynamic> json) {
    return GenreDna(
      genre: json['genre'] ?? 'Other',
      count: json['count'] ?? 0,
    );
  }
}

class LibraryStatsModel {
  final int streak;
  final List<GenreDna> genreDna;
  final int monthlyMilestone;
  final int totalLibraryBooks;

  LibraryStatsModel({
    required this.streak,
    required this.genreDna,
    required this.monthlyMilestone,
    required this.totalLibraryBooks,
  });

  factory LibraryStatsModel.fromJson(Map<String, dynamic> json) {
    return LibraryStatsModel(
      streak: json['streak'] ?? 0,
      genreDna: (json['genre_dna'] as List?)?.map((g) => GenreDna.fromJson(g)).toList() ?? [],
      monthlyMilestone: json['monthly_milestone'] ?? 0,
      totalLibraryBooks: json['total_library_books'] ?? 0,
    );
  }
}
