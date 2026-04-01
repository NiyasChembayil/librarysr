import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../../providers/search_provider.dart';
import '../../widgets/book_card.dart';
import '../book/book_detail_screen.dart';
import '../audio/audio_player_screen.dart';
import '../../models/profile_model.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _buildSearchHeader(),
              const TabBar(
                indicatorColor: Color(0xFF6C63FF),
                labelColor: Color(0xFF6C63FF),
                unselectedLabelColor: Colors.white54,
                tabs: [
                  Tab(text: 'Books'),
                  Tab(text: 'Authors'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildBooksTab(searchState),
                    _buildAuthorsTab(searchState),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBooksTab(SearchState state) {
    if (state.isLoading) return const Center(child: CircularProgressIndicator());
    if (state.books.isEmpty) return _buildEmptyState('discovery');

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 20),
      itemCount: state.books.length,
      itemBuilder: (context, index) {
        final book = state.books[index];
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
    );
  }

  Widget _buildAuthorsTab(SearchState state) {
    if (state.isLoading) return const Center(child: CircularProgressIndicator());
    if (state.profiles.isEmpty) return _buildEmptyState('people');

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: state.profiles.length,
      itemBuilder: (context, index) {
        final profile = state.profiles[index];
        return _buildProfileItem(profile);
      },
    );
  }

  Widget _buildProfileItem(ProfileModel profile) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[900]?.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: profile.avatar != null ? NetworkImage(profile.avatar!) : null,
            child: profile.avatar == null ? Text(profile.username[0].toUpperCase()) : null,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.username, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(profile.role.toUpperCase(), style: const TextStyle(fontSize: 12, color: Color(0xFF6C63FF), fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Column(
            children: [
              Text('${profile.followersCount}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const Text('Followers', style: TextStyle(fontSize: 10, color: Colors.white54)),
            ],
          ),
        ],
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
          onChanged: (value) => ref.read(searchProvider.notifier).searchAll(value),
          decoration: const InputDecoration(
            hintText: 'Search books, authors...',
            prefixIcon: Icon(Icons.search_rounded, color: Colors.white54),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            type == 'discovery' ? Icons.auto_stories_outlined : Icons.people_outline_rounded,
            size: 80,
            color: Colors.white10,
          ),
          const SizedBox(height: 15),
          const Text('Keep Searching.', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white24)),
          Text('Try searching for ${type == 'discovery' ? 'a new adventure' : 'an incredible author'}.', style: const TextStyle(color: Colors.white10)),
        ],
      ),
    );
  }
}
