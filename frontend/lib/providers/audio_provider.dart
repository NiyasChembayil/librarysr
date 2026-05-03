import 'package:just_audio/just_audio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

enum PlayerStatus { playing, paused, stopped, loading }

class PlayerState {
  final PlayerStatus status;
  final Duration position;
  final Duration totalDuration;
  final String? currentUrl;
  final double playbackSpeed;

  PlayerState({
    this.status = PlayerStatus.stopped,
    this.position = Duration.zero,
    this.totalDuration = Duration.zero,
    this.currentUrl,
    this.playbackSpeed = 1.0,
  });

  PlayerState copyWith({
    PlayerStatus? status,
    Duration? position,
    Duration? totalDuration,
    String? currentUrl,
    double? playbackSpeed,
  }) {
    return PlayerState(
      status: status ?? this.status,
      position: position ?? this.position,
      totalDuration: totalDuration ?? this.totalDuration,
      currentUrl: currentUrl ?? this.currentUrl,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
    );
  }
}

class PlayerNotifier extends StateNotifier<PlayerState> {
  final AudioPlayer _player = AudioPlayer();

  PlayerNotifier() : super(PlayerState()) {
    _init();
  }

  void _init() {
    _player.positionStream.listen((pos) {
      state = state.copyWith(position: pos);
    });
    _player.durationStream.listen((dur) {
      if (dur != null) state = state.copyWith(totalDuration: dur);
    });
    _player.playerStateStream.listen((ps) {
      if (ps.processingState == ProcessingState.loading ||
          ps.processingState == ProcessingState.buffering) {
        state = state.copyWith(status: PlayerStatus.loading);
      } else if (ps.playing) {
        state = state.copyWith(status: PlayerStatus.playing);
      } else {
        state = state.copyWith(status: PlayerStatus.paused);
      }
    });
  }

  Future<void> play(String url) async {
    if (state.currentUrl == url && state.status != PlayerStatus.stopped) {
      _player.play();
      return;
    }

    try {
      state = state.copyWith(status: PlayerStatus.loading, currentUrl: url);
      await _player.setUrl(url);
      _player.play();
    } catch (e) {
      debugPrint('Error playing audio: $e');
      state = state.copyWith(status: PlayerStatus.stopped);
    }
  }

  void togglePlay() {
    if (_player.playing) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  void seek(Duration pos) {
    _player.seek(pos);
  }

  void setSpeed(double speed) {
    _player.setSpeed(speed);
    state = state.copyWith(playbackSpeed: speed);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

final playerNotifierProvider = StateNotifierProvider<PlayerNotifier, PlayerState>((ref) {
  return PlayerNotifier();
});

