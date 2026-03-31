import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';

final notificationProvider = StateNotifierProvider<NotificationNotifier, List<dynamic>>((ref) {
  return NotificationNotifier(ref.read(apiClientProvider));
});

class NotificationNotifier extends StateNotifier<List<dynamic>> {
  final ApiClient _apiClient;

  NotificationNotifier(this._apiClient) : super([]);

  Future<void> fetchNotifications() async {
    try {
      final response = await _apiClient.dio.get('social/notifications/');
      state = response.data;
    } catch (e) {
      // Handle error
    }
  }

  Future<void> markAllRead() async {
    try {
      await _apiClient.dio.post('social/notifications/mark_all_read/');
      await fetchNotifications();
    } catch (e) {
      // Handle error
    }
  }
}
