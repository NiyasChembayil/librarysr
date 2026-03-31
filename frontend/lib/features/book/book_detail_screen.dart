import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../payment/checkout_screen.dart';
import '../audio/audio_player_screen.dart';
import 'reader_screen.dart';
import '../../providers/book_provider.dart';
import '../../core/api_client.dart';

class BookDetailScreen extends ConsumerWidget {
  final int id;
  final String title;
  final String author;
  final String coverUrl;
  final String description;
  final double price;

  const BookDetailScreen({
    super.key,
    required this.id,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.description,
    required this.price,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookAsync = ref.watch(currentBookProvider(id));
    final bool isOwned = price == 0.0; 

    return bookAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, stack) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (book) => Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 450,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'book-cover-$title',
                      child: CachedNetworkImage(
                        imageUrl: coverUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Theme.of(context).scaffoldBackgroundColor,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fadeIn(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.displayLarge,
                      ),
                    ),
                    const SizedBox(height: 5),
                    _fadeIn(
                      delay: 100,
                      child: Row(
                        children: [
                          Text(
                            'by $author',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(width: 15),
                          _FollowButton(bookId: id),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    _fadeIn(
                      delay: 200,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatColumn('4.8', 'Rating'),
                          _buildStatColumn('1.2k', 'Reads'),
                          _buildStatColumn('540', 'Likes'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    _fadeIn(
                      delay: 300,
                      child: Text(
                        'Description',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _fadeIn(
                      delay: 400,
                      child: Text(
                        description,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
                      ),
                    ),
                    const SizedBox(height: 150),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomSheet: Container(
          height: 100,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (isOwned) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReaderScreen(
                            bookId: id,
                            title: title,
                            chapters: book?.chapters ?? [],
                          ),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CheckoutScreen(
                            bookId: id,
                            title: title,
                            price: price,
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOwned ? const Color(0xFF6C63FF) : const Color(0xFF00D2FF),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(
                    isOwned ? 'Read Now' : 'Buy for \$${price.toStringAsFixed(2)}', 
                    style: const TextStyle(color: Colors.white, fontSize: 18)
                  ),
                ),
              ),
              const SizedBox(width: 15),
              GlassmorphicContainer(
                width: 70,
                height: 70,
                borderRadius: 20,
                blur: 10,
                alignment: Alignment.center,
                border: 1,
                linearGradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0.1), Colors.white.withValues(alpha: 0.05)]),
                borderGradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0.5), Colors.white.withValues(alpha: 0.2)]),
                child: IconButton(
                  onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AudioPlayerScreen(
                            title: title,
                            author: author,
                            coverUrl: coverUrl,
                          ),
                        ),
                      );
                  },
                  icon: const Icon(Icons.headphones_rounded, color: Colors.white, size: 30),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fadeIn({required Widget child, int delay = 0}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(opacity: value, child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child));
      },
      child: child,
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }
}

class _FollowButton extends ConsumerStatefulWidget {
  final int bookId;
  const _FollowButton({required this.bookId});

  @override
  ConsumerState<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends ConsumerState<_FollowButton> {
  bool isFollowing = false;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {
        setState(() => isFollowing = !isFollowing);
        // Call API in the background
        ref.read(apiClientProvider).dio.post('social/follows/', data: {'followed': widget.bookId});
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: isFollowing ? Colors.grey : const Color(0xFF6C63FF),
        side: BorderSide(color: isFollowing ? Colors.grey : const Color(0xFF6C63FF)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      ),
      child: Text(isFollowing ? 'Following' : 'Follow', style: const TextStyle(fontSize: 12)),
    );
  }
}
