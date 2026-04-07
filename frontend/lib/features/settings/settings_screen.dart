import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../profile/edit_profile_screen.dart';

final cacheSizeProvider = FutureProvider.autoDispose<String>((ref) async {
  try {
    final tempDir = await getTemporaryDirectory();
    int totalSize = 0;
    if (tempDir.existsSync()) {
      tempDir.listSync(recursive: true, followLinks: false).forEach((FileSystemEntity entity) {
        if (entity is File) {
          totalSize += entity.lengthSync();
        }
      });
    }
    final sizeInMb = totalSize / (1024 * 1024);
    return '${sizeInMb.toStringAsFixed(2)} MB';
  } catch (e) {
    return '0.00 MB';
  }
});

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
                _buildListTile(
                  'Change Username', 
                  icon: Icons.alternate_email, 
                  subtitle: 'Currently: ${authState.profile?.username ?? ""}',
                  onTap: () => _showUpdateDialog(context, ref, 'username', 'Change Username', authState.profile?.username ?? ''),
                ),
                _buildListTile(
                  'Change Email', 
                  icon: Icons.email_outlined,
                  onTap: () => _showUpdateDialog(context, ref, 'email', 'Change Email', ''),
                ),
                _buildListTile(
                  'Change Password', 
                  icon: Icons.lock_outline,
                  onTap: () => _showUpdateDialog(context, ref, 'password', 'Change Password', '', isPassword: true),
                ),
                if (!isAuthor)
                  _buildListTile(
                    'Switch to Author Account', 
                    icon: Icons.workspace_premium, 
                    iconColor: Colors.amber, 
                    textColor: Colors.amber,
                    onTap: () async {
                      final success = await ref.read(authProvider.notifier).upgradeToAuthor();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(success ? 'Welcome to the Creator Program!' : 'Failed to upgrade account.')),
                        );
                      }
                    }
                  ),
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
                  onTap: () async {
                    try {
                      final tempDir = await getTemporaryDirectory();
                      if (tempDir.existsSync()) {
                        tempDir.listSync().forEach((entity) {
                          if (entity is File) entity.deleteSync();
                        });
                      }
                      ref.invalidate(cacheSizeProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Device cache cleared!')));
                      }
                    } catch (e) {
                      if (context.mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to clear cache.')));
                      }
                    }
                  }
                ),
                Consumer(
                  builder: (context, ref, child) {
                    final cacheSize = ref.watch(cacheSizeProvider);
                    return _buildListTile('Storage usage', subtitle: cacheSize.value ?? 'Loading...', icon: Icons.storage);
                  },
                ),
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
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                    }
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

  void _showUpdateDialog(BuildContext context, WidgetRef ref, String key, String title, String initialValue, {bool isPassword = false}) {
    final controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GlassmorphicContainer(
            width: double.infinity,
            height: 220,
            borderRadius: 20,
            blur: 20,
            alignment: Alignment.center,
            border: 1,
            linearGradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0.1), Colors.white.withValues(alpha: 0.05)]),
            borderGradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0.2), Colors.white.withValues(alpha: 0)]),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  TextField(
                    controller: controller,
                    obscureText: isPassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      hintText: 'Enter new $key...',
                      hintStyle: const TextStyle(color: Colors.white38),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          if (controller.text.trim().isEmpty) return;
                          final nav = Navigator.of(context);
                          final scaffoldMsg = ScaffoldMessenger.of(context);
                          final success = await ref.read(authProvider.notifier).updateAccount(key, controller.text.trim());
                          nav.pop();
                          scaffoldMsg.showSnackBar(
                            SnackBar(content: Text(success ? '$title updated successfully!' : 'Failed to update $key. Please try again.')),
                          );
                        },
                        child: const Text('Save', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
