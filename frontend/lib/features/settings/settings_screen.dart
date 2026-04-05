import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../profile/edit_profile_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
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
                _buildListTile(
                  'Edit Profile', 
                  subtitle: 'Name, bio, profile image', 
                  icon: Icons.edit,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                ),
                _buildListTile('Change Username', icon: Icons.alternate_email, subtitle: 'Currently: ${authState.profile?.username ?? ""}'),
                _buildListTile('Change Email', icon: Icons.email_outlined),
                _buildListTile('Change Password', icon: Icons.lock_outline),
                if (!isAuthor)
                  _buildListTile('Switch to Author Account', icon: Icons.workspace_premium, iconColor: Colors.amber, textColor: Colors.amber),
              ],
            ),

            _buildSectionHeader('2. PRIVACY & SECURITY', Icons.security),
            _buildGlassCard(
              children: [
                _buildSwitchTile(
                  'Private account', 
                  settings.isPrivateAccount, 
                  (val) => settingsNotifier.updateSetting('isPrivateAccount', val),
                ),
                _buildListTile('Who can comment', subtitle: 'Everyone', icon: Icons.comment_outlined),
                _buildListTile('Block users', icon: Icons.block),
                _buildListTile('Two-factor authentication', subtitle: 'Coming soon', icon: Icons.verified_user_outlined),
              ],
            ),

            _buildSectionHeader('3. NOTIFICATIONS', Icons.notifications_none),
            _buildGlassCard(
              children: [
                _buildSwitchTile(
                  'New follower', 
                  settings.notifyNewFollower, 
                  (val) => settingsNotifier.updateSetting('notifyNewFollower', val),
                ),
                _buildSwitchTile(
                  'Likes', 
                  settings.notifyLikes, 
                  (val) => settingsNotifier.updateSetting('notifyLikes', val),
                ),
                _buildSwitchTile(
                  'Comments', 
                  settings.notifyComments, 
                  (val) => settingsNotifier.updateSetting('notifyComments', val),
                ),
                _buildSwitchTile(
                  'New books from followed authors', 
                  settings.notifyNewBooks, 
                  (val) => settingsNotifier.updateSetting('notifyNewBooks', val),
                ),
              ],
            ),

            _buildSectionHeader('4. AUDIO SETTINGS', Icons.headset_mic_outlined),
            _buildGlassCard(
              children: [
                _buildListTile('Default playback speed', subtitle: '${settings.playbackSpeed}x', icon: Icons.speed),
                _buildSwitchTile(
                  'Auto-play next chapter', 
                  settings.audioAutoPlay, 
                  (val) => settingsNotifier.updateSetting('audioAutoPlay', val),
                ),
                _buildSwitchTile(
                  'Download audio on WiFi only', 
                  settings.audioDownloadWifiOnly, 
                  (val) => settingsNotifier.updateSetting('audioDownloadWifiOnly', val),
                ),
                _buildSwitchTile(
                  'Background play enabled', 
                  settings.audioBackgroundPlay, 
                  (val) => settingsNotifier.updateSetting('audioBackgroundPlay', val),
                ),
              ],
            ),

            _buildSectionHeader('5. READING SETTINGS', Icons.menu_book),
            _buildGlassCard(
              children: [
                _buildListTile('Font size', subtitle: '${settings.fontSize.toInt()} px', icon: Icons.format_size),
                _buildListTile('Font style', subtitle: 'Inter', icon: Icons.font_download_outlined),
                _buildListTile('Theme', subtitle: settings.readerTheme, icon: Icons.palette_outlined),
              ],
            ),

            _buildSectionHeader('6. DOWNLOADS / STORAGE', Icons.save_alt),
            _buildGlassCard(
              children: [
                _buildListTile('Downloaded books', icon: Icons.download_done),
                _buildListTile(
                  'Clear cache', 
                  icon: Icons.delete_sweep_outlined,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cache cleared locally.')));
                  }
                ),
                _buildListTile('Storage usage', subtitle: '0 MB', icon: Icons.storage),
              ],
            ),

            _buildSectionHeader('7. LANGUAGE & REGION', Icons.language),
            _buildGlassCard(
              children: [
                _buildListTile('App language', subtitle: 'English (US)', icon: Icons.translate),
                _buildListTile('Content language', subtitle: 'Global', icon: Icons.public),
              ],
            ),

            if (isAuthor) ...[
              _buildSectionHeader('8. AUTHOR SETTINGS', Icons.draw_outlined),
              _buildGlassCard(
                children: [
                  _buildListTile('Payment account', subtitle: 'UPI / Bank', icon: Icons.account_balance),
                  _buildListTile('Earnings dashboard', icon: Icons.bar_chart),
                  _buildListTile('Upload preferences', icon: Icons.cloud_upload_outlined),
                ],
              ),
            ],

            _buildSectionHeader('9. HELP & SUPPORT', Icons.help_outline),
            _buildGlassCard(
              children: [
                _buildListTile('Help center', icon: Icons.support_agent),
                _buildListTile('Contact support', icon: Icons.mail_outline),
                _buildListTile('FAQ', icon: Icons.question_answer_outlined),
              ],
            ),

            _buildSectionHeader('10. LOGOUT & DELETE ACCOUNT', Icons.exit_to_app),
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
                    if (nav.canPop()) nav.pop(); 
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
          Icon(icon, color: const Color(0xFF6C63FF), size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required List<Widget> children}) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: children.length * 60.0, 
      borderRadius: 16,
      blur: 20,
      alignment: Alignment.center,
      border: 1,
      linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFffffff).withValues(alpha: 0.08),
            const Color(0xFFffffff).withValues(alpha: 0.03),
          ]),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFffffff).withValues(alpha: 0.15),
          const Color(0xFFffffff).withValues(alpha: 0.0),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children.map((widget) => SizedBox(height: 60, child: widget)).toList(),
      ),
    );
  }

  Widget _buildListTile(String title, {String? subtitle, required IconData icon, Color? textColor, Color? iconColor, VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      leading: Icon(icon, color: iconColor ?? Colors.white70, size: 22),
      title: Text(title, style: TextStyle(color: textColor ?? Colors.white, fontSize: 15)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)) : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
      value: value,
      onChanged: onChanged,
      activeThumbColor: const Color(0xFF00D2FF),
    );
  }
}
