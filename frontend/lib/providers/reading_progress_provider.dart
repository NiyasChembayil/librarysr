import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../models/reading_progress_model.dart';

final readingProgressProvider = StateNotifierProvider<ReadingProgressNotifier, ReadingProgressModel?>((ref) {
  return ReadingProgressNotifier(ref.read(apiClientProvider));
});

class ReadingProgressNotifier extends StateNotifier<ReadingProgressModel?> {
  final ApiClient _apiClient;

  ReadingProgressNotifier(this._apiClient) : super(null);

  Future<void> fetchRecentProgress() async {
    try {
      final response = await _apiClient.dio.get('core/books/recent_reading/');
      state = ReadingProgressModel.fromJson(response.data);
    } catch (e) {
      state = null;
    }
  }

  Future<void> updateProgress(int bookId, int chapterIndex) async {
    try {
      await _apiClient.dio.post(
        'core/books/$bookId/update_progress/',
        data: {'chapter_index': chapterIndex},
      );
      // Refresh progress after update
      await fetchRecentProgress();
    } catch (e) {
      // Handle error silently or log
    }
  }
}
