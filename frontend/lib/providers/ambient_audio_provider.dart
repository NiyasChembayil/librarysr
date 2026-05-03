import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:dio/dio.dart';
import '../core/api_client.dart';

final ambientAudioProvider = StateNotifierProvider<AmbientAudioNotifier, AmbientAudioState>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return AmbientAudioNotifier(apiClient);
});

class AmbientSoundModel {
  final int id;
  final String name;
  final String emoji;
  final String audioUrl;
  final bool isSystem;

  AmbientSoundModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.audioUrl,
    this.isSystem = true,
  });

  factory AmbientSoundModel.fromJson(Map<String, dynamic> json) {
    return AmbientSoundModel(
      id: json['id'],
      name: json['name'],
      emoji: json['emoji'],
      audioUrl: json['audio_url'],
      isSystem: json['is_system'] ?? true,
    );
  }
}

class AmbientAudioState {
  final String? currentMoodId;
  final bool isPlaying;
  final double volume;
  final List<AmbientSoundModel> availableSounds;
  final bool isLoading;

  AmbientAudioState({
    this.currentMoodId,
    this.isPlaying = false,
    this.volume = 0.5,
    this.availableSounds = const [],
    this.isLoading = false,
  });

  AmbientAudioState copyWith({
    String? currentMoodId,
    bool? isPlaying,
    double? volume,
    List<AmbientSoundModel>? availableSounds,
    bool? isLoading,
  }) {
    return AmbientAudioState(
      currentMoodId: currentMoodId ?? this.currentMoodId,
      isPlaying: isPlaying ?? this.isPlaying,
      volume: volume ?? this.volume,
      availableSounds: availableSounds ?? this.availableSounds,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  AmbientSoundModel? get currentMood {
    if (currentMoodId == null) return null;
    return availableSounds.firstWhere((s) => s.name == currentMoodId, orElse: () => availableSounds.first);
  }
}

class AmbientAudioNotifier extends StateNotifier<AmbientAudioState> {
  final AudioPlayer _player = AudioPlayer();
  final ApiClient _apiClient;

  AmbientAudioNotifier(this._apiClient) : super(AmbientAudioState()) {
    fetchSounds();
  }

  Future<void> fetchSounds() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _apiClient.dio.get('core/ambient-sounds/');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final sounds = data.map((json) => AmbientSoundModel.fromJson(json)).toList();
        
        if (sounds.isEmpty) {
          _useFallback();
        } else {
          state = state.copyWith(availableSounds: sounds, isLoading: false);
        }
      } else {
        _useFallback();
      }
    } catch (e) {
      _useFallback();
    }
  }

  void _useFallback() {
    state = state.copyWith(
      isLoading: false,
      availableSounds: [
        AmbientSoundModel(id: -1, name: 'Rain', emoji: '🌧️', audioUrl: 'https://www.soundjay.com/nature/rain-01.mp3'),
        AmbientSoundModel(id: -2, name: 'Forest', emoji: '🌲', audioUrl: 'https://www.soundjay.com/nature/forest-wind-01.mp3'),
        AmbientSoundModel(id: -3, name: 'Cafe', emoji: '☕', audioUrl: 'https://www.soundjay.com/misc/sounds/coffee-shop-1.mp3'),
        AmbientSoundModel(id: -4, name: 'Waves', emoji: '🌊', audioUrl: 'https://www.soundjay.com/nature/ocean-waves-1.mp3'),
      ],
    );
  }

  Future<void> addCustomSound(String name, String emoji, String filePath) async {
    try {
      final formData = FormData.fromMap({
        'name': name,
        'emoji': emoji,
        'audio_url': await MultipartFile.fromFile(filePath, filename: filePath.split('/').last),
      });

      final response = await _apiClient.dio.post(
        'core/user-sounds/', 
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      
      if (response.statusCode == 201) {
        await fetchSounds();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCustomSound(int id) async {
    try {
      final response = await _apiClient.dio.delete('core/user-sounds/$id/');
      if (response.statusCode == 204) {
        await fetchSounds();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> setMood(String? moodId) async {
    if (moodId == null) {
      await _player.stop();
      state = state.copyWith(currentMoodId: null, isPlaying: false);
      return;
    }

    final sound = state.availableSounds.firstWhere((s) => s.name == moodId, orElse: () => state.availableSounds.first);
    
    try {
      state = state.copyWith(currentMoodId: moodId, isPlaying: true);
      await _player.setUrl(sound.audioUrl);
      await _player.setLoopMode(LoopMode.one);
      await _player.setVolume(state.volume);
      _player.play();
    } catch (e) {
      state = state.copyWith(isPlaying: false);
    }
  }

  Future<void> togglePlay() async {
    if (state.isPlaying) {
      await _player.pause();
    } else {
      if (state.currentMoodId != null) {
        _player.play();
      }
    }
    state = state.copyWith(isPlaying: !state.isPlaying);
  }

  void setVolume(double volume) {
    _player.setVolume(volume);
    state = state.copyWith(volume: volume);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
