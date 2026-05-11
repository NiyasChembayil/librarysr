import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:audio_service/audio_service.dart';
// import 'core/services/audio_handler.dart';
// import 'providers/audio_provider.dart';
import 'core/theme.dart';
import 'widgets/bottom_nav_shell.dart';
import 'features/auth/login_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/purchase_provider.dart';
import 'services/notification_service.dart';

// No longer needed: AudioHandler is managed via Riverpod provider now.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Use a manual container to allow background initialization after runApp
  final container = ProviderContainer();

  debugPrint('Main: AudioService initialization disabled for Web testing.');


  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const SrishtyApp(),
    ),
  );
}



class SrishtyApp extends ConsumerWidget {
  const SrishtyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    debugPrint('UI: authState.status = ${authState.status}');
    
    // Warm up purchase provider once authenticated so isOwned() works immediately
    if (authState.status == AuthStatus.authenticated) {
      ref.watch(purchaseProvider);
      // Initialize Real-time Notifications
      ref.read(notificationServiceProvider).init();
    } else {
      // Disconnect if no longer authenticated
      ref.read(notificationServiceProvider).disconnect();
    }

    return MaterialApp(
      title: 'Srishty',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        // FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
      ],
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
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Official Srishty Logo
            Image.asset(
              'assets/logo.png',
              width: 140,
              height: 140,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: Color(0xFF6C63FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.book, size: 50, color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'SRISHTY',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E1E2E),
                letterSpacing: 4.0,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
            ),
          ],
        ),
      ),
    );
  }
}
