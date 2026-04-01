import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/book_provider.dart';
import '../../models/book_model.dart';
import '../../widgets/book_card.dart';
import '../settings/settings_screen.dart';
import '../book/book_detail_screen.dart';
import 'user_list_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final profile = authState.profile;
    final bookState = ref.watch(bookProvider);

    // Filter books by this author
    final myBooks = bookState.books.where((b) => b.authorName == profile?.username).toList();

    if (authState.status == AuthStatus.loading || authState.status == AuthStatus.initial) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 50),
            // Header with Settings button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                  icon: const Icon(Icons.settings_outlined, color: Colors.white70, size: 28),
                ),
              ],
            ),

            // Avatar
            CircleAvatar(
              radius: 60,
              backgroundColor: const Color(0xFF1E1E2E),
              backgroundImage: profile?.avatar != null
                  ? NetworkImage(profile!.avatar!)
                  : null,
              child: profile?.avatar == null
                  ? Text(
                      (profile?.username ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFF6C63FF)),
                    )
                  : null,
            ),
            const SizedBox(height: 15),

            // Username
            Text(
              profile?.username ?? 'User',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),

            // Role badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.5),
                ),
              ),
              child: const Text(
                'CREATOR',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6C63FF),
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Bio
            if (profile?.bio != null && profile!.bio.isNotEmpty)
              Text(profile.bio, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54)),

            const SizedBox(height: 30),

            // Stats row
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem('Total Reads', '0'),
                  _buildVerticalDivider(),
                  _buildStatItem(
                    'Followers',
                    '${profile?.followersCount ?? 0}',
                    onTap: () {
                      if (profile != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserListScreen(
                              title: 'Followers',
                              endpoint: 'accounts/profile/${profile.id}/followers/',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  _buildVerticalDivider(),
                  _buildStatItem(
                    'Following',
                    '${profile?.followingCount ?? 0}',
                    onTap: () {
                      if (profile != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserListScreen(
                              title: 'Following',
                              endpoint: 'accounts/profile/${profile.id}/following/',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Analytics Chart
            _buildChartSection(),
            const SizedBox(height: 30),

            // My Books section — now visible for everyone to encourage creation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('My Published Works', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                if (myBooks.isNotEmpty)
                  TextButton(onPressed: () {}, child: const Text('View All', style: TextStyle(color: Color(0xFF6C63FF)))),
              ],
            ),
            myBooks.isEmpty ? _buildNoBooksPlaceholder() : _buildBooksList(context, myBooks),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildBooksList(BuildContext context, List<BookModel> books) {
    return SizedBox(
      height: 320,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return SizedBox(
            width: 250,
            child: Transform.scale(
              scale: 0.7,
              alignment: Alignment.topLeft,
              child: BookCard(
                title: book.title,
                author: book.authorName,
                coverUrl: book.coverUrl,
                likes: book.likesCount,
                onPlay: () {},
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
                        price: book.price,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF6C63FF))),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalDivider() => Container(height: 35, width: 1, color: Colors.white10);

  Widget _buildChartSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900]?.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Reading Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('Last 7 days', style: TextStyle(color: Color(0xFF6C63FF), fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Connect backend ReadStats to see real activity here.',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2,
                  getDrawingHorizontalLine: (_) => FlLine(color: Colors.white10, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        final idx = value.toInt();
                        if (idx < 0 || idx >= days.length) return const SizedBox.shrink();
                        return Text(days[idx], style: const TextStyle(color: Colors.white38, fontSize: 11));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    // Placeholder data — replace with real ReadStats from backend
                    spots: const [
                      FlSpot(0, 0),
                      FlSpot(1, 0),
                      FlSpot(2, 0),
                      FlSpot(3, 0),
                      FlSpot(4, 0),
                      FlSpot(5, 0),
                      FlSpot(6, 0),
                    ],
                    isCurved: true,
                    color: const Color(0xFF6C63FF),
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                    ),
                  ),
                ],
                minY: 0,
                maxY: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoBooksPlaceholder() {
    return Container(
      margin: const EdgeInsets.only(top: 15),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.grey[900]?.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: const Column(
        children: [
          Icon(Icons.auto_stories_rounded, size: 48, color: Colors.white24),
          SizedBox(height: 12),
          Text("You haven't published any books yet.", style: TextStyle(color: Colors.white54)),
          SizedBox(height: 6),
          Text('Tap the + tab to start creating!', style: TextStyle(color: Colors.white38, fontSize: 13)),
        ],
      ),
    );
  }
}
