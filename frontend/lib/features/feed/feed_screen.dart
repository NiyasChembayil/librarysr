import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/post_model.dart';
import '../../providers/post_provider.dart';
import '../../providers/social_provider.dart';
import '../../core/theme.dart';
import 'widgets/post_card.dart';
import 'widgets/creator_card.dart';
import '../../widgets/book_card.dart';
import '../book/book_detail_screen.dart';
import 'create_post_screen.dart';

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
                      'Feed',
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
          ],
          body: _buildFeedTab(state),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreatePostScreen()),
          );
          ref.read(postFeedProvider.notifier).loadFeed();
        },
        backgroundColor: const Color(0xFF6C63FF),
        icon: const Icon(Icons.edit_rounded, color: Colors.white),
        label: const Text('Post', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      onRefresh: () => ref.read(postFeedProvider.notifier).loadFeed(),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        itemCount: state.feed.length,
        itemBuilder: (context, index) => PostCard(post: state.feed[index]),
      ),
    );
  }

  Widget _buildTrendingTab(PostFeedState state) {
    if (state.isTrendingLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
      );
    }
    
    return RefreshIndicator(
      color: const Color(0xFF6C63FF),
      onRefresh: () => ref.read(postFeedProvider.notifier).loadTrending(),
      child: CustomScrollView(
        slivers: [
          // Top Creators Section
          if (state.topCreators.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Row(
                  children: [
                    Text('✨', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 8),
                    Text(
                      'Top Creators',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: state.topCreators.length,
                  itemBuilder: (context, index) {
                    final creatorProfile = state.topCreators[index];
                    return CreatorCard(
                      profile: creatorProfile,
                      onFollow: () async {
                        // Use the notifier to trigger the action and pass both username and id
                        await ref.read(socialProvider.notifier).toggleFollow(
                          creatorProfile.username, 
                          creatorProfile.id
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Success! You updated your connection.'),
                              backgroundColor: const Color(0xFF6C63FF),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ),
          ],

          // Popular Books Section
          if (state.popularBooks.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 30, 16, 12),
                child: Row(
                  children: [
                    Text('📚', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 8),
                    Text(
                      'Trending Books',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: state.popularBooks.length,
                  itemBuilder: (context, index) {
                    final book = state.popularBooks[index];
                    return Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BookDetailScreen(
                                      id: book.id,
                                      title: book.title,
                                      author: book.authorName,
                                      coverUrl: book.coverUrl,
                                      description: book.description,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: book.coverUrl != null
                                      ? DecorationImage(
                                          image: NetworkImage(book.coverUrl!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                  color: Colors.white.withOpacity(0.05),
                                ),
                                child: book.coverUrl == null
                                    ? const Center(child: Icon(Icons.book, color: Colors.white24))
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            book.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            book.authorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],

          // Trending Posts Section
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 30, 16, 12),
              child: Row(
                children: [
                  Text('🔥', style: TextStyle(fontSize: 18)),
                  SizedBox(width: 8),
                  Text(
                    'Trending Posts',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (state.trending.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 60)),
                    const SizedBox(height: 16),
                    Text(
                      'No trending posts yet.',
                      style: TextStyle(color: Colors.grey[400], fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final post = state.trending[index];
                  return Stack(
                    children: [
                      PostCard(post: post),
                      Positioned(
                        top: 12,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF6584), Color(0xFFFF9F45)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '#${index + 1}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  );
                },
                childCount: state.trending.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
