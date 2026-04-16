// import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final audioHandlerProvider = StateProvider<dynamic>((ref) {
  return null;
});

enum PlayerStatus { playing, paused, stopped, loading }

class PlayerState {
  final PlayerStatus status;
  final Duration position;
  final Duration totalDuration;
  final dynamic currentMediaItem;
  final double playbackSpeed;

  PlayerState({
    this.status = PlayerStatus.stopped,
    this.position = Duration.zero,
    this.totalDuration = Duration.zero,
    this.currentMediaItem,
    this.playbackSpeed = 1.0,
  });

  PlayerState copyWith({
    PlayerStatus? status,
    Duration? position,
    Duration? totalDuration,
    dynamic currentMediaItem,
    double? playbackSpeed,
  }) {
    return PlayerState(
      status: status ?? this.status,
      position: position ?? this.position,
      totalDuration: totalDuration ?? this.totalDuration,
      currentMediaItem: currentMediaItem ?? this.currentMediaItem,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
    );
  }
}

class PlayerNotifier extends StateNotifier<PlayerState> {
  PlayerNotifier() : super(PlayerState());

  void play(dynamic item) {}
  void togglePlay() {}
  void seek(Duration pos) {}
  void setSpeed(double speed) {}
}

final playerNotifierProvider = StateNotifierProvider<PlayerNotifier, PlayerState>((ref) {
  return PlayerNotifier();
});

