import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Toggles for state management
  bool isPrivateAccount = false;
  bool notifyNewFollower = true;
  bool notifyLikes = true;
  bool notifyComments = true;
  bool notifyNewBooks = true;
  bool notifyPayments = true;
  
  bool audioAutoPlay = false;
  bool audioDownloadWifiOnly = true;
  bool audioBackgroundPlay = true;

  bool readerAutoScroll = false;
  
  String audioSpeed = '1x';
  String readerTheme = 'Dark';
  
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isAuthor = authState.profile?.role == 'author';

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          children: [
            _buildSectionHeader('1. ACCOUNT SETTINGS', Icons.person_outline),
            _buildGlassCard(
              children: [
                _buildListTile('Edit Profile', subtitle: 'Name, bio, profile image', icon: Icons.edit),
                _buildListTile('Change Username', icon: Icons.alternate_email),
                _buildListTile('Change Email', icon: Icons.email_outlined),
                _buildListTile('Change Password', icon: Icons.lock_outline),
                if (!isAuthor)
                  _buildListTile('Switch to Author Account', icon: Icons.workspace_premium, iconColor: Colors.amber, textColor: Colors.amber),
              ],
            ),

            _buildSectionHeader('2. PRIVACY & SECURITY', Icons.security),
            _buildGlassCard(
              children: [
                _buildSwitchTile('Private account', isPrivateAccount, (val) => setState(() => isPrivateAccount = val)),
                _buildListTile('Who can comment', subtitle: 'Everyone', icon: Icons.comment_outlined),
                _buildListTile('Block users', icon: Icons.block),
                _buildListTile('Two-factor authentication', subtitle: 'Future upgrade', icon: Icons.verified_user_outlined),
                _buildListTile('Logout from all devices', icon: Icons.phonelink_erase, textColor: Colors.redAccent),
              ],
            ),

            _buildSectionHeader('3. NOTIFICATIONS', Icons.notifications_none),
            _buildGlassCard(
              children: [
                _buildSwitchTile('New follower', notifyNewFollower, (val) => setState(() => notifyNewFollower = val)),
                _buildSwitchTile('Likes', notifyLikes, (val) => setState(() => notifyLikes = val)),
                _buildSwitchTile('Comments', notifyComments, (val) => setState(() => notifyComments = val)),
                _buildSwitchTile('New books from followed authors', notifyNewBooks, (val) => setState(() => notifyNewBooks = val)),
                _buildSwitchTile('Payment / purchase updates', notifyPayments, (val) => setState(() => notifyPayments = val)),
              ],
            ),

            _buildSectionHeader('4. AUDIO SETTINGS', Icons.headset_mic_outlined),
            _buildGlassCard(
              children: [
                _buildListTile('Default playback speed', subtitle: audioSpeed, icon: Icons.speed),
                _buildSwitchTile('Auto-play next chapter', audioAutoPlay, (val) => setState(() => audioAutoPlay = val)),
                _buildSwitchTile('Download audio on WiFi only', audioDownloadWifiOnly, (val) => setState(() => audioDownloadWifiOnly = val)),
                _buildSwitchTile('Background play enabled', audioBackgroundPlay, (val) => setState(() => audioBackgroundPlay = val)),
              ],
            ),

            _buildSectionHeader('5. READING SETTINGS', Icons.menu_book),
            _buildGlassCard(
              children: [
                _buildListTile('Font size', subtitle: 'Manage slider', icon: Icons.format_size),
                _buildListTile('Font style', subtitle: 'Inter', icon: Icons.font_download_outlined),
                _buildListTile('Line spacing', icon: Icons.format_line_spacing),
                _buildListTile('Theme', subtitle: readerTheme, icon: Icons.palette_outlined),
                _buildSwitchTile('Auto-scroll', readerAutoScroll, (val) => setState(() => readerAutoScroll = val)),
              ],
            ),

            _buildSectionHeader('6. PAYMENTS & SUBSCRIPTIONS', Icons.payment),
            _buildGlassCard(
              children: [
                _buildListTile('My purchases', icon: Icons.shopping_bag_outlined),
                _buildListTile('Active subscriptions', icon: Icons.star_border),
                _buildListTile('Payment methods', icon: Icons.credit_card),
                _buildListTile('Transaction history', icon: Icons.history),
                _buildListTile('Refund request', icon: Icons.request_quote_outlined),
              ],
            ),

            _buildSectionHeader('7. DOWNLOADS / STORAGE', Icons.save_alt),
            _buildGlassCard(
              children: [
                _buildListTile('Downloaded books', icon: Icons.download_done),
                _buildListTile('Clear cache', icon: Icons.delete_sweep_outlined),
                _buildListTile('Storage usage', subtitle: '120 MB', icon: Icons.storage),
              ],
            ),

            _buildSectionHeader('8. LANGUAGE & REGION', Icons.language),
            _buildGlassCard(
              children: [
                _buildListTile('App language', subtitle: 'English (US)', icon: Icons.translate),
                _buildListTile('Content language', subtitle: 'Global', icon: Icons.public),
                _buildListTile('Currency settings', subtitle: 'USD (\$)', icon: Icons.attach_money),
              ],
            ),

            if (isAuthor) ...[
              _buildSectionHeader('9. AUTHOR SETTINGS', Icons.draw_outlined),
              _buildGlassCard(
                children: [
                  _buildListTile('Payment account', subtitle: 'UPI / Bank', icon: Icons.account_balance),
                  _buildListTile('Earnings dashboard', icon: Icons.bar_chart),
                  _buildListTile('Upload preferences', icon: Icons.cloud_upload_outlined),
                  _buildListTile('Content visibility', subtitle: 'Free/Paid Default', icon: Icons.visibility_outlined),
                ],
              ),
            ],

            _buildSectionHeader('10. HELP & SUPPORT', Icons.help_outline),
            _buildGlassCard(
              children: [
                _buildListTile('Help center', icon: Icons.support_agent),
                _buildListTile('Contact support', icon: Icons.mail_outline),
                _buildListTile('Report a problem', icon: Icons.report_problem_outlined),
                _buildListTile('FAQ', icon: Icons.question_answer_outlined),
              ],
            ),

            _buildSectionHeader('11. LEGAL', Icons.gavel),
            _buildGlassCard(
              children: [
                _buildListTile('Terms & Conditions', icon: Icons.description_outlined),
                _buildListTile('Privacy Policy', icon: Icons.privacy_tip_outlined),
                _buildListTile('Copyright policy', icon: Icons.copyright),
              ],
            ),

            _buildSectionHeader('12. LOGOUT & DELETE ACCOUNT', Icons.exit_to_app),
            _buildGlassCard(
              children: [
                _buildListTile(
                  'Logout', 
                  icon: Icons.logout,
                  textColor: Colors.redAccent,
                  iconColor: Colors.redAccent,
                  onTap: () async {
                    final nav = Navigator.of(context);
                    await ref.read(authProvider.notifier).logout();
                    if (mounted) nav.pop(); // Go back after logout
                  }
                ),
                _buildListTile(
                  'Delete account', 
                  subtitle: 'Permanent action', 
                  icon: Icons.delete_forever, 
                  textColor: Colors.redAccent,
                  iconColor: Colors.redAccent,
                ),
              ],
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0, left: 8.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6C63FF), size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required List<Widget> children}) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: children.length * 65.0, // Approximate height to fit tiles
      borderRadius: 16,
      blur: 20,
      alignment: Alignment.center,
      border: 1,
      linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFffffff).withValues(alpha: 0.1),
            const Color(0xFFffffff).withValues(alpha: 0.05),
          ]),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFffffff).withValues(alpha: 0.2),
          const Color(0xFFffffff).withValues(alpha: 0.0),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children.map((widget) => SizedBox(height: 65, child: widget)).toList(),
      ),
    );
  }

  Widget _buildListTile(String title, {String? subtitle, required IconData icon, Color? textColor, Color? iconColor, VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      leading: Icon(icon, color: iconColor ?? Colors.white70),
      title: Text(title, style: TextStyle(color: textColor ?? Colors.white, fontSize: 16)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)) : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.white24),
      minVerticalPadding: 0,
      onTap: onTap ?? () {
        // Dummy default handler
      },
    );
  }

  Widget _buildSwitchTile(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
      value: value,
      onChanged: onChanged,
      activeThumbColor: const Color(0xFF00D2FF),
      activeTrackColor: const Color(0xFF6C63FF).withValues(alpha: 0.5),
      inactiveThumbColor: Colors.white54,
      inactiveTrackColor: Colors.white10,
    );
  }
}
