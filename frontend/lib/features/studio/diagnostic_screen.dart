import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/api_client.dart';
import '../../providers/auth_provider.dart';

class DiagnosticScreen extends ConsumerStatefulWidget {
  const DiagnosticScreen({super.key});

  @override
  ConsumerState<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends ConsumerState<DiagnosticScreen> {
  Map<String, dynamic>? _apiStatus;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkSystemHealth();
  }

  Future<void> _checkSystemHealth() async {
    setState(() => _isChecking = true);
    try {
      final startTime = DateTime.now();
      final response = await ref.read(apiClientProvider).dio.get('accounts/global_stats/');
      final latency = DateTime.now().difference(startTime).inMilliseconds;
      
      setState(() {
        _apiStatus = {
          'status': 'Online',
          'latency': '${latency}ms',
          'server_time': response.data['server_time'],
          'total_users': response.data['total_users'],
        };
        _isChecking = false;
      });
    } catch (e) {
      setState(() {
        _apiStatus = {
          'status': 'Offline / Error',
          'error': e.toString(),
        };
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A12),
      appBar: AppBar(
        title: Text('System Health', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(onPressed: _checkSystemHealth, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Network & API'),
            _buildStatusCard(
              title: 'Render Backend',
              value: _isChecking ? 'Checking...' : (_apiStatus?['status'] ?? 'Unknown'),
              icon: Icons.cloud_done_rounded,
              color: _apiStatus?['status'] == 'Online' ? Colors.greenAccent : Colors.redAccent,
              subtitle: _apiStatus?['latency'] != null ? 'Latency: ${_apiStatus!['latency']}' : null,
            ),
            const SizedBox(height: 20),
            
            _buildSectionTitle('Storage & Media'),
            _buildStatusCard(
              title: 'Cloudinary Integration',
              value: 'Active',
              icon: Icons.image_search_rounded,
              color: Colors.blueAccent,
              subtitle: 'Serving: avatars, covers, audio',
            ),
            const SizedBox(height: 20),
            
            _buildSectionTitle('Current Session'),
            _buildStatusCard(
              title: 'User Context',
              value: auth.user?.username ?? 'Guest',
              icon: Icons.person_rounded,
              color: const Color(0xFF6C63FF),
              subtitle: 'Role: ${auth.profile?.role ?? 'N/A'} | Verified: ${auth.profile?.is_verified == true ? 'Yes' : 'No'}',
            ),
            const SizedBox(height: 40),
            
            Center(
              child: Text(
                'Srishty Engine v1.0.4\nBuild #2026.05.09',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.white24, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(title, style: GoogleFonts.inter(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
    );
  }

  Widget _buildStatusCard({required String title, required String value, required IconData icon, required Color color, String? subtitle}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 4),
                Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle, style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
