import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../../providers/search_provider.dart';
import '../../providers/book_provider.dart';
import '../../widgets/book_card.dart';
import '../book/book_detail_screen.dart';
import '../audio/audio_player_screen.dart';
import '../../models/book_model.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(searchProvider.notifier).fetchDiscovery();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final isSearching = _searchController.text.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchHeader(),
            Expanded(
              child: isSearching 
                ? _buildSearchResults(searchState)
                : _buildDiscoveryGrid(searchState),
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
        height: 55,
        borderRadius: 20,
        blur: 20,
        alignment: Alignment.center,
        border: 1,
        linearGradient: LinearGradient(
          colors: [Colors.white.withValues(alpha: 0.1), Colors.white.withValues(alpha: 0.05)]
        ),
        borderGradient: LinearGradient(
          colors: [Colors.white.withValues(alpha: 0.5), Colors.white.withValues(alpha: 0.2)]
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => ref.read(searchProvider.notifier).searchAll(value),
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Search books, authors...',
            hintStyle: TextStyle(color: Colors.white38),
            prefixIcon: Icon(Icons.search_rounded, color: Colors.white54),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildDiscoveryGrid(SearchState state) {
    if (state.isLoading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: () => ref.read(searchProvider.notifier).fetchDiscovery(),
      color: const Color(0xFF6C63FF),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          if (state.mostlyReadBooks.isNotEmpty) ...[
            _buildSectionHeader('Trending in ${state.mostlyReadCategoryName}'),
            const SizedBox(height: 15),
            _buildHorizontalBookList(state.mostlyReadBooks),
          ],
          const SizedBox(height: 30),
          if (state.localHits.isNotEmpty) ...[
            _buildSectionHeader('Popular Near You'),
            const SizedBox(height: 15),
            _buildVerticalGrid(state.localHits),
          ],
          const SizedBox(height: 100), // Bottom padding for nav bar
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.white38),
      ],
    );
  }

  Widget _buildHorizontalBookList(List<BookModel> books) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return GestureDetector(
            onTap: () => _navigateToDetail(book),
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(right: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.network(
                        book.coverUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[900]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    book.authorName,
                    style: const TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVerticalGrid(List<BookModel> books) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: books.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
        childAspectRatio: 0.7,
      ),
      itemBuilder: (context, index) {
        final book = books[index];
        return GestureDetector(
          onTap: () => _navigateToDetail(book),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      book.coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[900]),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      book.authorName,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchResults(SearchState state) {
    if (state.isLoading) return const Center(child: CircularProgressIndicator());
    if (state.books.isEmpty) return _buildEmptyState();

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: state.books.length,
      itemBuilder: (context, index) {
        final book = state.books[index];
        return BookCard(
          title: book.title,
          author: book.authorName,
          authorProfileId: book.authorProfileId,
          isAuthorFollowing: book.isAuthorFollowing,
          coverUrl: book.coverUrl,
          likes: book.likesCount,
          downloads: book.downloadsCount,
          onPlay: () {
            ref.read(bookProvider.notifier).recordRead(book.id);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AudioPlayerScreen(
                  bookId: book.id,
                  title: book.title,
                  author: book.authorName,
                  coverUrl: book.coverUrl,
                  chapters: book.chapters,
                ),
              ),
            );
          },
          onTap: () => _navigateToDetail(book),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded, size: 80, color: Colors.white10),
          const SizedBox(height: 15),
          const Text('No Results Found.', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white24)),
          const Text('Try searching for something else.', style: TextStyle(color: Colors.white10)),
        ],
      ),
    );
  }

  void _navigateToDetail(BookModel book) {
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => BookDetailScreen(
          id: book.id,
          title: book.title,
          author: book.authorName,
          coverUrl: book.coverUrl,
          description: book.description,
        ),
      ),
    );
  }
}
