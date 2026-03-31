import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'core/services/audio_handler.dart';
import 'providers/audio_provider.dart';
import 'core/theme.dart';
import 'widgets/bottom_nav_shell.dart';
import 'features/auth/login_screen.dart';
import 'providers/auth_provider.dart';

late AudioHandler _audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  _audioHandler = await AudioService.init(
    builder: () => BookifyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.booksrishty.audio',
      androidNotificationChannelName: 'Srishty Playback',
      androidStopForegroundOnPause: true,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        audioHandlerProvider.overrideWithValue(_audioHandler),
      ],
      child: const BookifyApp(),
    ),
  );
}

class BookifyApp extends ConsumerWidget {
  const BookifyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'Srishty',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: authState.status == AuthStatus.authenticated
          ? const BottomNavShell()
          : const LoginScreen(),
    );
  }
}
