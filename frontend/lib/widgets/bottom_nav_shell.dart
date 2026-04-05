import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../features/home/home_screen.dart';
import '../features/audio/audio_library_screen.dart';
import '../features/search/search_screen.dart';
import '../features/profile/profile_screen.dart';

import '../providers/navigation_provider.dart';

class BottomNavShell extends StatefulWidget {
  const BottomNavShell({super.key});

  @override
  State<BottomNavShell> createState() => _BottomNavShellState();
}

class _BottomNavShellState extends State<BottomNavShell> {
  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const AudioLibraryScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final selectedIndex = ref.watch(navigationProvider);
        return Scaffold(
          body: Stack(
            children: [
              _screens[selectedIndex],
              // Always show nav bar now
              Positioned(
                  left: 20,
                  right: 20,
                  bottom: 25,
                  child: GlassmorphicContainer(
                    width: MediaQuery.of(context).size.width - 40,
                    height: 70,
                    borderRadius: 35,
                    blur: 20,
                    alignment: Alignment.center,
                    border: 2,
                    linearGradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.1),
                        Colors.white.withValues(alpha: 0.05),
                      ],
                    ),
                    borderGradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.5),
                        Colors.white.withValues(alpha: 0.2),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNavItem(ref, selectedIndex, 0, Icons.home_rounded, 'Home'),
                          _buildNavItem(ref, selectedIndex, 1, Icons.explore_rounded, 'Search'),
                          _buildNavItem(ref, selectedIndex, 2, Icons.headphones_rounded, 'Audio'),
                          _buildNavItem(ref, selectedIndex, 3, Icons.person_rounded, 'Profile'),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavItem(WidgetRef ref, int selectedIndex, int index, IconData icon, String label) {
    bool isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => ref.read(navigationProvider.notifier).state = index,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF6C63FF) : Colors.grey,
            size: isSelected ? 28 : 24,
          ),
          const SizedBox(height: 6),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isSelected ? 1.0 : 0.0,
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: Color(0xFF6C63FF),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
