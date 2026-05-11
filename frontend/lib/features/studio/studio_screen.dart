import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/api_client.dart';
import '../../providers/auth_provider.dart';
import '../../providers/my_books_provider.dart';
import '../studio/book_management_screen.dart';
import '../studio/create_book_screen.dart';

class AuthorStudioScreen extends ConsumerStatefulWidget {
  const AuthorStudioScreen({super.key});

  @override
  ConsumerState<AuthorStudioScreen> createState() => _AuthorStudioScreenState();
}

class _AuthorStudioScreenState extends ConsumerState<AuthorStudioScreen> {
  Map<String, dynamic>? stats;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final response = await ref.read(apiClientProvider).dio.get('core/books/author_stats/');
      if (mounted) {
        setState(() {
          stats = response.data;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final myProfile = authState.profile;
    final myBooksState = ref.watch(myBooksProvider);
    final myBooks = myBooksState.books;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A12),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
          : CustomScrollView(
              slivers: [
                _buildSliverAppBar(myProfile?.username ?? 'Author'),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatsGrid(stats),
                        const SizedBox(height: 30),
                        _buildQuickActions(context),
                        const SizedBox(height: 40),
                        _buildSectionTitle('Performance Insights'),
                        const SizedBox(height: 20),
                        _buildInsightsCard(stats),
                        const SizedBox(height: 40),
                        _buildSectionTitle('My Masterpieces'),
                        const SizedBox(height: 20),
                        if (myBooks.isEmpty)
                          _buildEmptyState()
                        else
                          _buildMyBooksList(myBooks),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSliverAppBar(String name) {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF0A0A12),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Srishty Studio',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Welcome back, $name',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFFFF6584)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              right: -30,
              top: -30,
              child: Icon(Icons.auto_awesome_rounded, size: 200, color: Colors.white.withValues(alpha: 0.1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic>? data) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('Total Reads', '${data?['total_reads'] ?? 0}', Icons.trending_up_rounded, const Color(0xFF6C63FF)),
        _buildStatCard('Followers', '${data?['followers_count'] ?? 0}', Icons.people_alt_rounded, const Color(0xFFFF6584)),
        _buildStatCard('Published', '${data?['published_count'] ?? 0}', Icons.book_rounded, const Color(0xFFFFD700)),
        _buildStatCard('Streak', '${data?['writing_streak'] ?? 0}d', Icons.edit_calendar_rounded, const Color(0xFF43E97B)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: double.infinity,
      borderRadius: 20,
      blur: 15,
      alignment: Alignment.center,
      border: 1,
      linearGradient: LinearGradient(
        colors: [Colors.white.withValues(alpha: 0.05), Colors.white.withValues(alpha: 0.02)],
      ),
      borderGradient: LinearGradient(
        colors: [color.withValues(alpha: 0.5), color.withValues(alpha: 0.1)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Text(label, style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            'Create New Book',
            Icons.add_box_rounded,
            const Color(0xFF6C63FF),
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateBookScreen())),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildActionButton(
            'Manage Audio',
            Icons.mic_external_on_rounded,
            const Color(0xFFFF6584),
            () => _showComingSoon(context),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 10),
            Text(label, style: GoogleFonts.inter(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsCard(Map<String, dynamic>? data) {
    final List<dynamic> genreData = data?['genre_dna'] ?? [];
    final colors = [const Color(0xFF6C63FF), const Color(0xFFFF6584), const Color(0xFFFFD700), const Color(0xFF43E97B)];
    
    return GlassmorphicContainer(
      width: double.infinity,
      height: 220,
      borderRadius: 25,
      blur: 20,
      alignment: Alignment.center,
      border: 1,
      linearGradient: LinearGradient(
        colors: [Colors.white.withValues(alpha: 0.05), Colors.white.withValues(alpha: 0.02)],
      ),
      borderGradient: LinearGradient(
        colors: [Colors.white.withValues(alpha: 0.2), Colors.white.withValues(alpha: 0.05)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Genre DNA', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    genreData.isNotEmpty 
                      ? 'You specialize in ${genreData[0]['genre']}.' 
                      : 'Publish more to see insights.', 
                    style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)
                  ),
                  const SizedBox(height: 20),
                  ...genreData.take(3).toList().asMap().entries.map((entry) {
                    return _buildLegendItem(entry.value['genre'], colors[entry.key % colors.length]);
                  }),
                ],
              ),
            ),
            if (genreData.isNotEmpty)
              Expanded(
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 5,
                    centerSpaceRadius: 30,
                    sections: genreData.toList().asMap().entries.map((entry) {
                      final val = (entry.value['count'] as int).toDouble();
                      return PieChartSectionData(
                        value: val, 
                        color: colors[entry.key % colors.length], 
                        radius: 15, 
                        showTitle: false
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildMyBooksList(List myBooks) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: myBooks.length,
      itemBuilder: (context, index) {
        final book = myBooks[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 15.0),
          child: InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookManagementScreen(
              bookId: book.id,
              bookTitle: book.title,
            ))),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(book.coverUrl ?? '', width: 50, height: 70, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.white10)),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(book.title, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('${book.totalReads} Reads • Published', style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          const Icon(Icons.edit_note_rounded, color: Colors.white24, size: 50),
          const SizedBox(height: 15),
          Text('No books yet', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text('Start your journey today!', style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This feature is coming soon to the Author Studio!')),
    );
  }
}
