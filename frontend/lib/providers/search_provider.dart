import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../models/book_model.dart';

final searchProvider = StateNotifierProvider<SearchNotifier, List<BookModel>>((ref) {
  return SearchNotifier(ref.read(apiClientProvider));
});

class SearchNotifier extends StateNotifier<List<BookModel>> {
  final ApiClient _apiClient;

  SearchNotifier(this._apiClient) : super([]);

  Future<void> searchBooks(String query) async {
    if (query.isEmpty) {
      state = [];
      return;
    }
    try {
      final response = await _apiClient.dio.get('core/books/?search=$query');
      final List data = response.data['results'] ?? [];
      state = data.map((json) => BookModel.fromJson(json)).toList();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> filterByCategory(String categorySlug) async {
    try {
      final response = await _apiClient.dio.get('core/books/?category=$categorySlug');
      final List data = response.data['results'] ?? [];
      state = data.map((json) => BookModel.fromJson(json)).toList();
    } catch (e) {
      // Handle error
    }
  }
}
