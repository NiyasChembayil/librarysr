import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/post_provider.dart';
import '../../providers/social_provider.dart';
import 'widgets/post_card.dart';
import 'widgets/creator_card.dart';
import '../book/book_detail_screen.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {

  @override
  void initState() {
    super.initState();
    // Load feed
    Future.microtask(() {
      ref.read(postFeedProvider.notifier).loadFeed();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(postFeedProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A12),
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: const Color(0xFF0A0A12),
              elevation: 0,
              title: Row(
                children: [
                  const Icon(Icons.auto_stories, color: Color(0xFF6C63FF), size: 28),
                  const SizedBox(width: 10),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFFFF6584)],
                    ).createShader(bounds),
                    child: const Text(
                      'Krithi',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                  onPressed: () {
                    ref.read(postFeedProvider.notifier).loadFeed();
                  },
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: _buildFilterChips(state),
            ),
          ],
          body: _buildFeedTab(state),
        ),
      ),
    );
  }

  Widget _buildFeedTab(PostFeedState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
      );
    }
    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.signal_wifi_statusbar_connected_no_internet_4_rounded,
                color: Colors.grey, size: 60),
            const SizedBox(height: 16),
            Text(
              'Could not load feed',
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => ref.read(postFeedProvider.notifier).loadFeed(),
              icon: const Icon(Icons.refresh, color: Color(0xFF6C63FF)),
              label: const Text('Retry', style: TextStyle(color: Color(0xFF6C63FF))),
            ),
          ],
        ),
      );
    }
    if (state.feed.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📚', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            Text(
              'Your feed is empty!\nFollow writers to see their posts.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400], fontSize: 16, height: 1.5),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: const Color(0xFF6C63FF),
      onRefresh: () => ref.read(postFeedProvider.notifier).loadFeed(type: state.selectedFilter),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        itemCount: state.feed.length,
        itemBuilder: (context, index) => PostCard(post: state.feed[index]),
      ),
    );
  }

  Widget _buildFilterChips(PostFeedState state) {
    final filters = [
      {'label': 'All', 'value': null, 'icon': Icons.all_inclusive_rounded},
      {'label': 'Audio', 'value': 'AUDIO', 'icon': Icons.mic_rounded},
      {'label': 'Excerpts', 'value': 'QUOTE', 'icon': Icons.format_quote_rounded},
      {'label': 'Updates', 'value': 'UPDATE', 'icon': Icons.edit_note_rounded},
    ];

    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = state.selectedFilter == filter['value'];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              showCheckmark: false,
              avatar: Icon(
                filter['icon'] as IconData,
                size: 16,
                color: isSelected ? Colors.white : Colors.white54,
              ),
              label: Text(filter['label'] as String),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  ref.read(postFeedProvider.notifier).loadFeed(type: filter['value'] as String?);
                }
              },
              selectedColor: const Color(0xFF6C63FF),
              backgroundColor: const Color(0xFF1E1E2E),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              side: BorderSide(
                color: isSelected ? const Color(0xFF6C63FF) : Colors.white.withValues(alpha: 0.08),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        },
      ),
    );
  }
}
