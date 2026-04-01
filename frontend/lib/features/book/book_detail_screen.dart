import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../payment/checkout_screen.dart';
import '../audio/audio_player_screen.dart';
import 'reader_screen.dart';
import '../../providers/book_provider.dart';
import '../../providers/purchase_provider.dart';
import '../../widgets/follow_button.dart';

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
    // Check if the user actually purchased this book OR if it's free
    final isPurchased = ref.watch(purchaseProvider.select((s) => s.contains(id)));
    final isFree = price == 0.0;
    final isOwned = isFree || isPurchased;

    return bookAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 60, color: Colors.white24),
              const SizedBox(height: 16),
              Text('Could not load book', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(currentBookProvider(id)),
                child: const Text('Retry', style: TextStyle(color: Color(0xFF6C63FF))),
              ),
            ],
          ),
        ),
      ),
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
                        placeholder: (_, _) => const ColoredBox(color: Color(0xFF1E1E2E)),
                        errorWidget: (_, _, _) => const ColoredBox(
                          color: Color(0xFF1E1E2E),
                          child: Icon(Icons.menu_book_rounded, size: 80, color: Colors.white24),
                        ),
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
                      child: Text(title, style: Theme.of(context).textTheme.displayLarge),
                    ),
                    const SizedBox(height: 10),
                    _fadeIn(
                      delay: 100,
                      child: Row(
                        children: [
                          Text(
                            'by $author',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(width: 15),
                          FollowButton(authorUsername: author),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Stat columns... (no change)
                    _fadeIn(
                      delay: 200,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatColumn('${book?.likesCount ?? 0}', 'Likes'),
                          _buildStatColumn('${book?.totalReads ?? 0}', 'Reads'),
                          _buildStatColumn('${book?.chapters.length ?? 0}', 'Chapters'),
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
                          builder: (_) => ReaderScreen(
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
                          builder: (_) => CheckoutScreen(
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
                    style: const TextStyle(color: Colors.white, fontSize: 18),
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
                        builder: (_) => AudioPlayerScreen(
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
        return Opacity(
          opacity: value,
          child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child),
        );
      },
      child: child,
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }
}
