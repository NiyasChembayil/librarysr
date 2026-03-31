import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final profile = authState.profile;

    if (authState.status == AuthStatus.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 50),
            // Header with Settings Button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                  },
                  icon: const Icon(Icons.settings_outlined, color: Colors.white70, size: 28),
                ),
              ],
            ),
            // Profile Header
            CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(profile?.avatar ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&q=80&w=200'),
            ),
            const SizedBox(height: 15),
            Text(authState.status == AuthStatus.authenticated ? 'Welcome' : 'Guest', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(profile?.bio ?? 'No bio available', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54)),
            const SizedBox(height: 30),
            
            // Stats Grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('Total Reads', '0'),
                _buildVerticalDivider(),
                _buildStatItem('Followers', '${profile?.followersCount ?? 0}'),
                _buildVerticalDivider(),
                _buildStatItem('Role', profile?.role.toUpperCase() ?? 'READER'),
              ],
            ),
            const SizedBox(height: 40),
            
            // Analytics Chart
            _buildChartSection(context),
            const SizedBox(height: 40),
            
            // My Books Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('My Published Works', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                TextButton(onPressed: () {}, child: const Text('View All')),
              ],
            ),
            _buildMyBooksList(),
            const SizedBox(height: 100), // Space for navigation
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF6C63FF))),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ],
    );
  }

  Widget _buildVerticalDivider() => Container(height: 30, width: 1, color: Colors.white10);

  Widget _buildChartSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.grey[900]?.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Reading Analytics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      const FlSpot(0, 3),
                      const FlSpot(2, 2),
                      const FlSpot(4, 5),
                      const FlSpot(6, 3.1),
                      const FlSpot(8, 4),
                      const FlSpot(10, 3),
                    ],
                    isCurved: true,
                    color: const Color(0xFF6C63FF),
                    barWidth: 4,
                    belowBarData: BarAreaData(show: true, color: const Color(0xFF6C63FF).withValues(alpha: 0.1)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyBooksList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 2,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(top: 15),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                index == 0 ? 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1582135294i/52578297.jpg' : 'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1597695864i/54495368.jpg',
                width: 50,
                height: 70,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(index == 0 ? 'The Midnight Library' : 'Project Hail Mary', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(index == 0 ? '2,400 reads' : '1,850 reads', style: const TextStyle(color: Colors.grey)),
            trailing: const Icon(Icons.show_chart_rounded, color: Color(0xFF00D2FF)),
          ),
        );
      },
    );
  }
}
