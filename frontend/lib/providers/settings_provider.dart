import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

class SettingsState {
  final bool isPrivateAccount;
  final bool notifyNewFollower;
  final bool notifyLikes;
  final bool notifyComments;
  final bool notifyNewBooks;
  final bool audioAutoPlay;
  final bool audioDownloadWifiOnly;
  final bool audioBackgroundPlay;
  final double playbackSpeed;
  final double fontSize;
  final String readerTheme;

  SettingsState({
    this.isPrivateAccount = false,
    this.notifyNewFollower = true,
    this.notifyLikes = true,
    this.notifyComments = true,
    this.notifyNewBooks = true,
    this.audioAutoPlay = false,
    this.audioDownloadWifiOnly = true,
    this.audioBackgroundPlay = true,
    this.playbackSpeed = 1.0,
    this.fontSize = 16.0,
    this.readerTheme = 'Dark',
  });

  SettingsState copyWith({
    bool? isPrivateAccount,
    bool? notifyNewFollower,
    bool? notifyLikes,
    bool? notifyComments,
    bool? notifyNewBooks,
    bool? audioAutoPlay,
    bool? audioDownloadWifiOnly,
    bool? audioBackgroundPlay,
    double? playbackSpeed,
    double? fontSize,
    String? readerTheme,
  }) {
    return SettingsState(
      isPrivateAccount: isPrivateAccount ?? this.isPrivateAccount,
      notifyNewFollower: notifyNewFollower ?? this.notifyNewFollower,
      notifyLikes: notifyLikes ?? this.notifyLikes,
      notifyComments: notifyComments ?? this.notifyComments,
      notifyNewBooks: notifyNewBooks ?? this.notifyNewBooks,
      audioAutoPlay: audioAutoPlay ?? this.audioAutoPlay,
      audioDownloadWifiOnly: audioDownloadWifiOnly ?? this.audioDownloadWifiOnly,
      audioBackgroundPlay: audioBackgroundPlay ?? this.audioBackgroundPlay,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      fontSize: fontSize ?? this.fontSize,
      readerTheme: readerTheme ?? this.readerTheme,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = SettingsState(
      isPrivateAccount: prefs.getBool('isPrivateAccount') ?? false,
      notifyNewFollower: prefs.getBool('notifyNewFollower') ?? true,
      notifyLikes: prefs.getBool('notifyLikes') ?? true,
      notifyComments: prefs.getBool('notifyComments') ?? true,
      notifyNewBooks: prefs.getBool('notifyNewBooks') ?? true,
      audioAutoPlay: prefs.getBool('audioAutoPlay') ?? false,
      audioDownloadWifiOnly: prefs.getBool('audioDownloadWifiOnly') ?? true,
      audioBackgroundPlay: prefs.getBool('audioBackgroundPlay') ?? true,
      playbackSpeed: prefs.getDouble('playbackSpeed') ?? 1.0,
      fontSize: prefs.getDouble('fontSize') ?? 16.0,
      readerTheme: prefs.getString('readerTheme') ?? 'Dark',
    );
  }

  Future<void> updateSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }

    // Update local state
    switch (key) {
      case 'isPrivateAccount':
        state = state.copyWith(isPrivateAccount: value);
        break;
      case 'notifyNewFollower':
        state = state.copyWith(notifyNewFollower: value);
        break;
      case 'notifyLikes':
        state = state.copyWith(notifyLikes: value);
        break;
      case 'notifyComments':
        state = state.copyWith(notifyComments: value);
        break;
      case 'notifyNewBooks':
        state = state.copyWith(notifyNewBooks: value);
        break;
      case 'audioAutoPlay':
        state = state.copyWith(audioAutoPlay: value);
        break;
      case 'audioDownloadWifiOnly':
        state = state.copyWith(audioDownloadWifiOnly: value);
        break;
      case 'audioBackgroundPlay':
        state = state.copyWith(audioBackgroundPlay: value);
        break;
      case 'playbackSpeed':
        state = state.copyWith(playbackSpeed: value);
        break;
      case 'fontSize':
        state = state.copyWith(fontSize: value);
        break;
      case 'readerTheme':
        state = state.copyWith(readerTheme: value);
        break;
    }
  }
}
