import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../../providers/search_provider.dart';
import '../../widgets/book_card.dart';
import '../book/book_detail_screen.dart';
import '../audio/audio_player_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(searchProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchHeader(),
            _buildCategoryChips(),
            Expanded(
              child: searchResults.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final book = searchResults[index];
                        return BookCard(
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
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookDetailScreen(
                                  id: book.id,
                                  title: book.title,
                                  author: book.authorName,
                                  coverUrl: book.coverUrl,
                                  description: book.description,
                                  price: book.price,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 60,
        borderRadius: 20,
        blur: 20,
        alignment: Alignment.center,
        border: 1,
        linearGradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0.1), Colors.white.withValues(alpha: 0.05)]),
        borderGradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0.5), Colors.white.withValues(alpha: 0.2)]),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => ref.read(searchProvider.notifier).searchBooks(value),
          decoration: const InputDecoration(
            hintText: 'Search books, authors, or genres...',
            prefixIcon: Icon(Icons.search_rounded, color: Colors.white54),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    final categories = ['All', 'Romance', 'Mystery', 'Sci-Fi', 'Business', 'Fantasy'];
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(categories[index]),
              selected: index == 0,
              onSelected: (v) {},
              side: const BorderSide(color: Colors.white10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_stories_outlined, size: 80, color: Colors.white10),
          SizedBox(height: 15),
          Text('Discovery Awaits.', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white24)),
          Text('Try searching for a new adventure.', style: TextStyle(color: Colors.white10)),
        ],
      ),
    );
  }
}
