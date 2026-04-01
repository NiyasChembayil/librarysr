import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'core/services/audio_handler.dart';
import 'providers/audio_provider.dart';
import 'core/theme.dart';
import 'widgets/bottom_nav_shell.dart';
import 'features/auth/login_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/purchase_provider.dart';

// No longer needed: AudioHandler is managed via Riverpod provider now.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Use a manual container to allow background initialization after runApp
  final container = ProviderContainer();

  debugPrint('Main: Starting background AudioService initialization...');
  _initAudioService(container);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const BookifyApp(),
    ),
  );
}

Future<void> _initAudioService(ProviderContainer container) async {
  try {
    final handler = await AudioService.init(
      builder: () => BookifyAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.booksrishty.audio',
        androidNotificationChannelName: 'Srishty Playback',
        androidStopForegroundOnPause: true,
      ),
    );
    // Update the provider state once ready
    container.read(audioHandlerProvider.notifier).state = handler;
    debugPrint('Main: AudioService background initialization complete.');
  } catch (e) {
    debugPrint('Main: AudioService background error: $e');
  }
}

class BookifyApp extends ConsumerWidget {
  const BookifyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    debugPrint('UI: authState.status = ${authState.status}');
    
    // Warm up purchase provider once authenticated so isOwned() works immediately
    if (authState.status == AuthStatus.authenticated) {
      ref.watch(purchaseProvider);
    }

    return MaterialApp(
      title: 'Srishty',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: _getHome(authState.status),
    );
  }

  Widget _getHome(AuthStatus status) {
    debugPrint('UI: Selecting home for status: $status');
    switch (status) {
      case AuthStatus.initial:
      case AuthStatus.loading:
        return const SplashScreen();
      case AuthStatus.authenticated:
        return const BottomNavShell();
      case AuthStatus.unauthenticated:
      case AuthStatus.error:
        return const LoginScreen();
    }
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkTheme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Placeholder/Image for logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.book, size: 50, color: Colors.blue),
            ),
            const SizedBox(height: 24),
            const Text(
              'SRISHTY',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ],
        ),
      ),
    );
  }
}
