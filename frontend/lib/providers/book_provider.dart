import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../models/book_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

final bookProvider = StateNotifierProvider<BookNotifier, List<BookModel>>((ref) {
  return BookNotifier(ref.read(apiClientProvider));
});

class BookNotifier extends StateNotifier<List<BookModel>> {
  final ApiClient _apiClient;

  BookNotifier(this._apiClient) : super([]) {
    _loadFromCache();
  }

  Future<void> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('cached_books');
    if (cached != null) {
      final List decoded = jsonDecode(cached);
      state = decoded.map((j) => BookModel.fromJson(j)).toList();
    }
  }

  Future<void> fetchBooks() async {
    try {
      final response = await _apiClient.dio.get('core/books/');
      final List data = response.data;
      
      // Cache the result
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_books', jsonEncode(data));
      
      state = data.map((json) => BookModel.fromJson(json)).toList();
    } catch (e) {
      // If network fails, we already have cached data in state
    }
  }

  Future<void> likeBook(int id) async {
    try {
      await _apiClient.dio.post('social/likes/', data: {'book': id});
    } catch (e) {
      // Silence error if liking fails (e.g. already liked or offline)
    }
  }

  Future<BookModel?> fetchBookDetails(int id) async {
    try {
      final response = await _apiClient.dio.get('core/books/$id/');
      return BookModel.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }
}

final currentBookProvider = FutureProvider.family<BookModel?, int>((ref, id) async {
  return ref.read(bookProvider.notifier).fetchBookDetails(id);
});
