import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/post_provider.dart';

final notificationServiceProvider = Provider((ref) {
  final service = NotificationService(ref);
  
  // React to token changes
  ref.listen(authProvider.select((s) => s.token), (prev, next) {
    if (next != prev) {
      debugPrint('🔔 NotificationService: Token changed, re-initializing...');
      service.disconnect();
      if (next != null) {
        service.init();
      }
    }
  });

  return service;
});

class NotificationService {
  final Ref _ref;
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  bool _isDisposed = false;

  NotificationService(this._ref);

  void init() {
    if (_isDisposed) return;
    
    final token = _ref.read(authProvider).token;
    if (token == null) {
      debugPrint('🔔 NotificationService: No token, skipping init.');
      return;
    }

    // Using localhost for local development
    final wsUrl = 'ws://127.0.0.1:8000/ws/notifications/';
    
    try {
      debugPrint('🔔 NotificationService: Connecting to $wsUrl');
      _channel = WebSocketChannel.connect(
        Uri.parse('$wsUrl?token=$token'),
      );

      _channel!.stream.listen(
        (message) {
          final data = jsonDecode(message);
          debugPrint('🔔 NotificationService: Received: ${data['type']}');
          
          if (data['type'] == 'notification') {
            _ref.read(notificationProvider.notifier).addNotification(data['notification']);
          } else if (data['type'] == 'social_update') {
            final postData = data['data'];
            _ref.read(postFeedProvider.notifier).updatePostActivity(
              postData['post_id'],
              postData['likes_count'],
              postData['comments_count'],
            );
          }
        },
        onError: (error) {
          debugPrint('🔔 NotificationService Error: $error');
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint('🔔 NotificationService: Connection closed.');
          _scheduleReconnect();
        },
      );
    } catch (e) {
      debugPrint('🔔 NotificationService Exception: $e');
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_isDisposed) return;
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      debugPrint('🔔 NotificationService: Attempting to reconnect...');
      init();
    });
  }

  void disconnect() {
    debugPrint('🔔 NotificationService: Disconnecting...');
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    _isDisposed = true;
    disconnect();
  }
}
