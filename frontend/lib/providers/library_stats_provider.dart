import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../models/library_stats_model.dart';

final libraryStatsProvider = StateNotifierProvider<LibraryStatsNotifier, LibraryStatsState>((ref) {
  return LibraryStatsNotifier(ref.read(apiClientProvider));
});

class LibraryStatsState {
  final LibraryStatsModel? stats;
  final bool isLoading;

  LibraryStatsState({this.stats, this.isLoading = false});

  LibraryStatsState copyWith({LibraryStatsModel? stats, bool? isLoading}) {
    return LibraryStatsState(
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class LibraryStatsNotifier extends StateNotifier<LibraryStatsState> {
  final ApiClient _apiClient;

  LibraryStatsNotifier(this._apiClient) : super(LibraryStatsState());

  Future<void> fetchStats() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _apiClient.dio.get('core/books/library_stats/');
      state = LibraryStatsState(stats: LibraryStatsModel.fromJson(response.data), isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }
}
