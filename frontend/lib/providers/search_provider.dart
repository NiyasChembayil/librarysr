import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../models/book_model.dart';
import '../models/profile_model.dart';

class SearchState {
  final List<BookModel> books;
  final List<ProfileModel> profiles;
  final bool isLoading;

  SearchState({
    required this.books,
    required this.profiles,
    this.isLoading = false,
  });

  factory SearchState.initial() => SearchState(books: [], profiles: []);
}

final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier(ref.read(apiClientProvider));
});

class SearchNotifier extends StateNotifier<SearchState> {
  final ApiClient _apiClient;

  SearchNotifier(this._apiClient) : super(SearchState.initial());

  Future<void> searchAll(String query) async {
    if (query.isEmpty) {
      state = SearchState.initial();
      return;
    }
    
    state = SearchState(books: state.books, profiles: state.profiles, isLoading: true);
    
    try {
      // Run both searches in parallel
      final results = await Future.wait([
        _apiClient.dio.get('core/books/?search=$query'),
        _apiClient.dio.get('accounts/profiles/?search=$query'),
      ]);

      final bookData = results[0].data['results'] as List? ?? [];
      final profileData = results[1].data['results'] as List? ?? [];

      state = SearchState(
        books: bookData.map((j) => BookModel.fromJson(j)).toList(),
        profiles: profileData.map((j) => ProfileModel.fromJson(j)).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = SearchState(books: state.books, profiles: state.profiles, isLoading: false);
    }
  }

  // Deprecated: Use searchAll
  Future<void> searchBooks(String query) => searchAll(query);

  Future<void> filterByCategory(String categorySlug) async {
    state = SearchState(books: state.books, profiles: state.profiles, isLoading: true);
    try {
      final response = await _apiClient.dio.get('core/books/?category=$categorySlug');
      final List data = response.data['results'] ?? [];
      state = SearchState(
        books: data.map((json) => BookModel.fromJson(json)).toList(),
        profiles: [],
        isLoading: false,
      );
    } catch (e) {
      state = SearchState(books: state.books, profiles: state.profiles, isLoading: false);
    }
  }
}
