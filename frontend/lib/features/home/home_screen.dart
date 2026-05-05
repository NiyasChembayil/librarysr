import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animations/animations.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/mini_book_card.dart';
import '../book/book_detail_screen.dart';
import '../audio/audio_player_screen.dart';
import '../../providers/book_provider.dart';
import '../notifications/notification_screen.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reading_progress_provider.dart';
import '../../models/book_model.dart';
import '../../providers/social_discovery_provider.dart';
import 'widgets/author_spotlight.dart';
import 'widgets/friend_activity_row.dart';
import 'widgets/hero_section.dart';
import 'widgets/category_chips.dart';
import 'widgets/continue_reading_card.dart';
import '../feed/widgets/post_card.dart';
import '../search/search_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      ref.read(bookProvider.notifier).fetchBooks();
      ref.read(notificationProvider.notifier).fetchNotifications();
      ref.read(socialDiscoveryProvider.notifier).fetchAll();
      ref.read(readingProgressProvider.notifier).fetchRecentProgress();
      final count = await ref.read(notificationProvider.notifier).fetchUnreadCount();
      ref.read(unreadNotificationCountProvider.notifier).state = count;
    });
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(bookProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App bar row
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Text(
                        'Srishty',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
                        },
                        icon: const Icon(Icons.search_rounded, size: 28, color: Colors.white70),
                      ),
                      Stack(
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
                            },
                            icon: const Icon(Icons.notifications_none_rounded, size: 28),
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                child: Text(
                                  '$unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Body — switches based on feed state
            Expanded(
              child: _buildBody(feedState),
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    final username = ref.watch(authProvider).profile?.username ?? '';
    final namePart = username.isNotEmpty ? ', $username' : '';
    
    if (hour < 12) return 'Good Morning$namePart';
    if (hour < 17) return 'Good Afternoon$namePart';
    return 'Good Evening$namePart';
  }

  Widget _buildBody(BookFeedState feedState) {
    switch (feedState.status) {
      case BookFeedStatus.initial:
      case BookFeedStatus.loading:
        return _buildShimmerLoading();

      case BookFeedStatus.empty:
        return _buildEmptyState();

      case BookFeedStatus.error:
        return _buildErrorState(feedState.error);

      case BookFeedStatus.loaded:
        final allBooks = List.of(feedState.books);
        final socialState = ref.watch(socialDiscoveryProvider);
        final recentProgress = ref.watch(readingProgressProvider);
        
        // Pick a featured book for Hero (highest liked or just first)
        final featuredBook = allBooks.isNotEmpty ? allBooks.first : null;
        
        // 1. Top Picks
        final topPicks = allBooks.take(10).toList();
        
        // 2. Top 10 in India (Sorted by likes)
        final top10Books = List.of(allBooks)
          ..sort((a, b) => b.likesCount.compareTo(a.likesCount));
        final top10 = top10Books.take(10).toList();
        
        // 3+. Categorized Books
        final Map<String, List<BookModel>> categorizedBooks = {};
        for (var book in allBooks) {
          final cat = book.categoryName;
          categorizedBooks.putIfAbsent(cat, () => []).add(book);
        }

        return RefreshIndicator(
          color: const Color(0xFF6C63FF),
          backgroundColor: const Color(0xFF1E1E2E),
          onRefresh: () async {
            HapticFeedback.mediumImpact();
            await ref.read(bookProvider.notifier).fetchBooks();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 120, top: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (featuredBook != null) ...[
                  HeroSection(book: featuredBook),
                  const SizedBox(height: 10),
                ],

                if (recentProgress != null)
                  ContinueReadingCard(progress: recentProgress),
                
                CategoryChips(
                  categories: categorizedBooks.keys.toList(),
                  onCategorySelected: (cat) {
                    // Logic to filter or jump to section could go here
                  },
                ),
                const SizedBox(height: 10),

                if (socialState.isLoading) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: ShimmerLoading(width: 150, height: 20, borderRadius: 8),
                  ),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      itemCount: 5,
                      itemBuilder: (context, index) => const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: ShimmerLoading(width: 60, height: 60, borderRadius: 30),
                      ),
                    ),
                  ),
                ] else
                  AuthorSpotlight(authors: socialState.topCreators),
                const SizedBox(height: 10),
                _buildHorizontalSection(
                  context,
                  title: 'Top picks for you',
                  books: topPicks,
                ),
                const SizedBox(height: 30),
                _buildHorizontalSection(
                  context,
                  title: 'Top 10 in India',
                  books: top10,
                  showRank: true,
                ),
                const SizedBox(height: 10),
                if (socialState.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: ShimmerLoading(width: double.infinity, height: 80, borderRadius: 15),
                  )
                else
                  FriendActivityRow(activities: socialState.friendActivity),
                const SizedBox(height: 20),
                if (socialState.pollOfTheDay != null) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text(
                      'Poll of the Day',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  PostCard(post: socialState.pollOfTheDay!),
                  const SizedBox(height: 20),
                ],
                const SizedBox(height: 30),
                
                // Dynamically add category sections
                ...categorizedBooks.entries.map((entry) {
                  return Column(
                    children: [
                      _buildHorizontalSection(
                        context,
                        title: entry.key,
                        books: entry.value,
                      ),
                      const SizedBox(height: 30),
                    ],
                  );
                }),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildHorizontalSection(
    BuildContext context, {
    required String title,
    String? subtitle,
    required List books,
    bool showRank = false,
  }) {
    if (books.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(
          height: 270, // To comfortably fit image + number shadow + text row
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return OpenContainer(
                closedColor: Colors.transparent,
                openColor: Theme.of(context).scaffoldBackgroundColor,
                closedElevation: 0,
                transitionType: ContainerTransitionType.fadeThrough,
                openBuilder: (context, _) => BookDetailScreen(
                  id: book.id,
                  title: book.title,
                  author: book.authorName,
                  coverUrl: book.coverUrl,
                  description: book.description,
                ),
                closedBuilder: (context, openContainer) => MiniBookCard(
                  title: book.title,
                  coverUrl: book.coverUrl,
                  categoryName: book.categoryName,
                  views: book.totalReads > 0 ? book.totalReads : book.likesCount,
                  rank: showRank ? (index + 1) : null,
                  onTap: openContainer,
                  onPlay: () {
                    // Record a read event for the stats
                    ref.read(bookProvider.notifier).recordRead(book.id);
                    
                    // Find first chapter with audio
                    final firstAudioChapter = book.chapters.firstWhere(
                      (c) => c.audioUrl != null && c.audioUrl!.isNotEmpty,
                      orElse: () => book.chapters.first,
                    );

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AudioPlayerScreen(
                          bookId: book.id,
                          title: book.title,
                          author: book.authorName,
                          coverUrl: book.coverUrl,
                          chapters: book.chapters,
                          audioUrl: firstAudioChapter.audioUrl,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildShimmerSection(),
          const SizedBox(height: 30),
          _buildShimmerSection(),
          const SizedBox(height: 30),
          _buildShimmerSection(),
        ],
      ),
    );
  }

  Widget _buildShimmerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: ShimmerLoading(width: 150, height: 24, borderRadius: 8),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 270,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 5,
            itemBuilder: (context, index) => const ShimmerBookCard(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.menu_book_rounded, size: 80, color: Colors.white24),
          const SizedBox(height: 20),
          const Text('No Books Yet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white70)),
          const SizedBox(height: 10),
          const Text('Check back soon — stories are on their way!', style: TextStyle(color: Colors.white38)),
          const SizedBox(height: 30),
          TextButton.icon(
            onPressed: () => ref.read(bookProvider.notifier).fetchBooks(),
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF6C63FF)),
            label: const Text('Refresh', style: TextStyle(color: Color(0xFF6C63FF), fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 80, color: Colors.white24),
            const SizedBox(height: 20),
            const Text('No Connection', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white70)),
            const SizedBox(height: 10),
            const Text(
              'Could not reach the server.\nCheck your internet connection and try again.',
              style: TextStyle(color: Colors.white38),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => ref.read(bookProvider.notifier).fetchBooks(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: const Text('Try Again', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
