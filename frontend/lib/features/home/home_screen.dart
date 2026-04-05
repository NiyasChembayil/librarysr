import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animations/animations.dart';
import '../../widgets/book_card.dart';
import '../book/book_detail_screen.dart';
import '../audio/audio_player_screen.dart';
import '../../providers/book_provider.dart';
import '../notifications/notification_screen.dart';
import '../../providers/notification_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(bookProvider.notifier).fetchBooks();
      ref.read(notificationProvider.notifier).fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(bookProvider);
    final notifications = ref.watch(notificationProvider);
    final unreadCount = notifications.where((n) => n['is_read'] == false).length;

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
                  const Text(
                    'Srishty',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Row(
                    children: [
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
        return RefreshIndicator(
          color: const Color(0xFF6C63FF),
          backgroundColor: const Color(0xFF1E1E2E),
          onRefresh: () => ref.read(bookProvider.notifier).fetchBooks(),
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 120),
            itemCount: feedState.books.length,
            itemBuilder: (context, index) {
              final book = feedState.books[index];
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
                closedBuilder: (context, openContainer) => BookCard(
                  title: book.title,
                  author: book.authorName,
                  authorProfileId: book.authorProfileId,
                  isAuthorFollowing: book.isAuthorFollowing,
                  coverUrl: book.coverUrl,
                  likes: book.likesCount,
                  downloads: book.downloadsCount,
                  onPlay: () {
                    // Record a read event for the stats
                    ref.read(bookProvider.notifier).recordRead(book.id);
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AudioPlayerScreen(
                          bookId: book.id,
                          title: book.title,
                          author: book.authorName,
                          coverUrl: book.coverUrl,
                          chapters: book.chapters,
                        ),
                      ),
                    );
                  },
                  onTap: openContainer,
                ),
              );
            },
          ),
        );
    }
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 3,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[900]!,
        highlightColor: Colors.grey[800]!,
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          height: 400,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white10),
          ),
        ),
      ),
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
