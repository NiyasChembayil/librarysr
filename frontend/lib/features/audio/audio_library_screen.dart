import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/my_books_provider.dart';
import '../../widgets/book_card.dart';
import '../book/book_detail_screen.dart';
import '../audio/audio_player_screen.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/book_provider.dart';
import '../../providers/library_stats_provider.dart';
import '../library/widgets/stats_view.dart';
import '../../models/book_model.dart';

class AudioLibraryScreen extends ConsumerStatefulWidget {
  const AudioLibraryScreen({super.key});

  @override
  ConsumerState<AudioLibraryScreen> createState() => _AudioLibraryScreenState();
}

class _AudioLibraryScreenState extends ConsumerState<AudioLibraryScreen> {
  int _selectedTab = 0; // 0 = Books, 1 = Stats
  String _selectedShelf = 'ALL'; // ALL, TO_READ, READING, FINISHED, FAVORITES

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(myBooksProvider.notifier).fetchMyBooks();
      ref.read(libraryStatsProvider.notifier).fetchStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myBooksProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => ref.read(navigationProvider.notifier).state = 0, // Go to Home
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'My Library',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            // Tab Toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Container(
                height: 45,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2E),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    Expanded(child: _buildTab(0, 'Books')),
                    Expanded(child: _buildTab(1, 'Stats')),
                  ],
                ),
              ),
            ),

            Expanded(
              child: _selectedTab == 0 ? _buildBooksView(state) : const StatsView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBooksView(MyBooksState state) {
    if (state.isLoading && state.books.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
    }

    if (state.books.isEmpty) {
      return _buildEmptyState();
    }

    // Filter books based on selected shelf
    final filteredBooks = state.books.where((book) {
      if (_selectedShelf == 'ALL') return true;
      if (_selectedShelf == 'FAVORITES') return book.isFavorite;
      return book.shelfStatus == _selectedShelf;
    }).toList();

    return Column(
      children: [
        _buildShelfFilter(),
        Expanded(
          child: filteredBooks.isEmpty 
            ? _buildNoBooksInShelf()
            : RefreshIndicator(
                onRefresh: () => ref.read(myBooksProvider.notifier).fetchMyBooks(),
                color: const Color(0xFF6C63FF),
                backgroundColor: const Color(0xFF1E1E2E),
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 120),
                  itemCount: filteredBooks.length,
                  itemBuilder: (context, index) {
                    final book = filteredBooks[index];
                    return Stack(
                      children: [
                        BookCard(
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
                            
                            // Update shelf to READING automatically
                            if (book.shelfStatus == 'TO_READ') {
                              ref.read(myBooksProvider.notifier).updateShelf(book.id, status: 'READING');
                            }

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
                        ),
                        // Shelf Menu Button
                        Positioned(
                          top: 15,
                          right: 15,
                          child: _buildShelfMenu(book),
                        ),
                        // Favorite Indicator
                        if (book.isFavorite)
                          const Positioned(
                            top: 15,
                            right: 50,
                            child: Icon(Icons.star_rounded, color: Colors.amber, size: 24),
                          ),
                      ],
                    );
                  },
                ),
              ),
        ),
      ],
    );
  }

  Widget _buildShelfFilter() {
    final shelves = [
      {'id': 'ALL', 'label': 'All'},
      {'id': 'READING', 'label': 'Reading'},
      {'id': 'TO_READ', 'label': 'To-Read'},
      {'id': 'FINISHED', 'label': 'Finished'},
      {'id': 'FAVORITES', 'label': 'Favorites'},
    ];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: shelves.length,
        itemBuilder: (context, index) {
          final shelf = shelves[index];
          final isSelected = _selectedShelf == shelf['id'];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: ChoiceChip(
              label: Text(shelf['label']!),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedShelf = shelf['id']!);
                }
              },
              selectedColor: const Color(0xFF6C63FF).withValues(alpha: 0.2),
              backgroundColor: Colors.transparent,
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF6C63FF) : Colors.white60,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isSelected ? const Color(0xFF6C63FF) : Colors.white10),
              ),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Widget _buildShelfMenu(BookModel book) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: Colors.white70),
      color: const Color(0xFF1E1E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      onSelected: (value) {
        if (value == 'TOGGLE_FAVORITE') {
          ref.read(myBooksProvider.notifier).updateShelf(book.id, isFavorite: !book.isFavorite);
        } else {
          ref.read(myBooksProvider.notifier).updateShelf(book.id, status: value);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'TOGGLE_FAVORITE',
          child: Row(
            children: [
              Icon(book.isFavorite ? Icons.star_border_rounded : Icons.star_rounded, color: Colors.amber),
              const SizedBox(width: 10),
              Text(book.isFavorite ? 'Remove Favorite' : 'Mark as Favorite'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'READING', child: Text('Currently Reading')),
        const PopupMenuItem(value: 'TO_READ', child: Text('Move to To-Read')),
        const PopupMenuItem(value: 'FINISHED', child: Text('Mark as Finished')),
      ],
    );
  }

  Widget _buildNoBooksInShelf() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_stories_rounded, size: 60, color: Colors.white10),
          const SizedBox(height: 16),
          Text(
            'No books in this shelf',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.library_books_rounded, size: 80, color: Colors.white24),
            const SizedBox(height: 20),
            const Text('Your library is empty', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white70)),
            const SizedBox(height: 10),
            const Text(
              'Purchase stories or publish your own to see them here.', 
              style: TextStyle(color: Colors.white38), 
              textAlign: TextAlign.center
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => ref.read(navigationProvider.notifier).state = 0, // Go to Home (Store)
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Browse Stories', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(int index, String title) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedTab = index);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6C63FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white54,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
