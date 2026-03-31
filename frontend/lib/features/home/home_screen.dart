import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animations/animations.dart';
import '../../widgets/book_card.dart';
import '../book/book_detail_screen.dart';
import '../audio/audio_player_screen.dart';
import '../../providers/book_provider.dart';
import '../search/search_screen.dart';
import '../notifications/notification_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(bookProvider.notifier).fetchBooks());
  }

  @override
  Widget build(BuildContext context) {
    final books = ref.watch(bookProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SearchScreen()),
                      );
                    },
                    icon: const Icon(Icons.search_rounded, size: 30),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NotificationScreen()),
                      );
                    },
                    icon: const Icon(Icons.notifications_none_rounded, size: 30),
                  ),
                ],
              ),
            ),
            Expanded(
              child: books.isEmpty
                  ? _buildShimmerLoading()
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 120),
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
                            price: book.price,
                          ),
                          closedBuilder: (context, openContainer) => BookCard(
                            title: book.title,
                            author: book.authorName,
                            coverUrl: book.coverUrl,
                            likes: book.likesCount,
                            onPlay: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AudioPlayerScreen(
                                    title: book.title,
                                    author: book.authorName,
                                    coverUrl: book.coverUrl,
                                  ),
                                ),
                              );
                            },
                            onTap: openContainer,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
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
}
