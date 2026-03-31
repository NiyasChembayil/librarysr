import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final audioHandlerProvider = Provider<AudioHandler>((ref) {
  throw UnimplementedError("Initialize audioHandlerProvider in main()");
});

enum PlayerStatus { playing, paused, stopped, loading }

class PlayerState {
  final PlayerStatus status;
  final Duration position;
  final Duration totalDuration;
  final MediaItem? currentMediaItem;
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
    MediaItem? currentMediaItem,
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
  final AudioHandler _handler;

  PlayerNotifier(this._handler) : super(PlayerState()) {
    _listenToPlaybackState();
    _listenToMediaItem();
  }

  void _listenToPlaybackState() {
    _handler.playbackState.listen((state) {
      this.state = this.state.copyWith(
        status: state.playing ? PlayerStatus.playing : PlayerStatus.paused,
        position: state.updatePosition,
        playbackSpeed: state.speed,
      );
    });
  }

  void _listenToMediaItem() {
    _handler.mediaItem.listen((item) {
      state = state.copyWith(
        currentMediaItem: item,
        totalDuration: item?.duration ?? Duration.zero,
      );
    });
  }

  void play(MediaItem item) => _handler.playMediaItem(item);
  void togglePlay() {
    if (state.status == PlayerStatus.playing) {
      _handler.pause();
    } else {
      _handler.play();
    }
  }
  void seek(Duration pos) => _handler.seek(pos);
  void setSpeed(double speed) => _handler.setSpeed(speed);
}

final playerNotifierProvider = StateNotifierProvider<PlayerNotifier, PlayerState>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return PlayerNotifier(handler);
});
