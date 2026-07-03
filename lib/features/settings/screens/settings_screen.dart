import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/notifications/notification_service.dart';
import '../../habits/controllers/home_controller.dart';
import '../services/subscription_service.dart';
import '../../../shared/widgets/brain_mascot.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  bool _isPro = false;
  bool _isLoadingPro = true;
  String _appVersion = '1.0.0';
  String _userName = 'Friend';
  String _brainType = 'Not set';

  // Toggle states
  bool _sensorySafe = false;
  bool _noRedBadges = true;
  bool _offlineMode = true;
  bool _shareTherapist = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final isPro = await _subscriptionService.isPro();
    final packageInfo = await PackageInfo.fromPlatform();

    if (mounted) {
      setState(() {
        _isPro = isPro;
        _isLoadingPro = false;
        _appVersion = packageInfo.version;
        _userName = prefs.getString('user_name') ?? 'Friend';
        _brainType = prefs.getString('brain_type') ?? 'Not set';
        _sensorySafe = prefs.getBool('sensory_safe_ui') ?? false;
        _noRedBadges = prefs.getBool('no_red_badges') ?? true;
        _offlineMode = prefs.getBool('offline_mode') ?? true;
        _shareTherapist = prefs.getBool('share_therapist') ?? false;
      });
    }
  }

  Future<void> _saveToggle(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _exportData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'user_name': _userName,
        'brain_type': _brainType,
        'dopamine_points': prefs.getInt('dopamine_points') ?? 0,
        'settings': {
          'sensory_safe_ui': _sensorySafe,
          'no_red_badges': _noRedBadges,
          'offline_mode': _offlineMode,
          'share_therapist': _shareTherapist,
        },
        'exported_at': DateTime.now().toIso8601String(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(data);

      final tempPath = '${(await getTemporaryDirectory()).path}/nudge_export.json';
      final file = File(tempPath);
      await file.writeAsString(jsonString);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(tempPath)],
          subject: 'Nudge Data Export',
          text: 'Here is my Nudge app data export.',
        ),
      );
    } catch (e) {
      Get.snackbar(
        'Export failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F8),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          physics: const BouncingScrollPhysics(),
          children: [
            // Custom Header
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppTheme.textColor,
                fontFamily: 'Inter',
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Customize Nudge to work for your brain.',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppTheme.textVariantColor,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 32),

            // Pro Card
            _buildProCard(),
            const SizedBox(height: 32),

            // Preferences Section
            _buildSectionHeader('Preferences'),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  _buildPreferenceToggle(
                    title: 'Sensory-safe UI',
                    subtitle: 'Simpler visuals, calmer experience',
                    icon: Icons.auto_awesome_rounded,
                    value: _sensorySafe,
                    onChanged: (val) => setState(() { _sensorySafe = val; _saveToggle('sensory_safe_ui', val); }),
                  ),
                  const Divider(height: 1, indent: 72, endIndent: 24, color: Color(0xFFF0F0F0)),
                  _buildPreferenceToggle(
                    title: 'No red badges',
                    subtitle: 'Use amber instead of red',
                    icon: Icons.verified_user_rounded,
                    value: _noRedBadges,
                    onChanged: (val) => setState(() { _noRedBadges = val; _saveToggle('no_red_badges', val); }),
                  ),
                  const Divider(height: 1, indent: 72, endIndent: 24, color: Color(0xFFF0F0F0)),
                  _buildPreferenceToggle(
                    title: 'Offline mode',
                    subtitle: 'Use Nudge without internet',
                    icon: Icons.cloud_download_rounded,
                    value: _offlineMode,
                    onChanged: (val) => setState(() { _offlineMode = val; _saveToggle('offline_mode', val); }),
                  ),
                  const Divider(height: 1, indent: 72, endIndent: 24, color: Color(0xFFF0F0F0)),
                  _buildPreferenceToggle(
                    title: 'Share with therapist',
                    subtitle: 'Export data for your care team',
                    icon: Icons.people_alt_rounded,
                    value: _shareTherapist,
                    onChanged: (val) => setState(() { _shareTherapist = val; _saveToggle('share_therapist', val); }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Privacy & Data Section
            _buildSectionHeader('Privacy & data'),
            const SizedBox(height: 16),
            
            // On-device AI Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF4F1FC),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_rounded, color: AppTheme.primaryColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'On-device AI, no tracking',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, fontFamily: 'Inter', color: AppTheme.textColor),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Your data stays on your device.\nNo ads. No tracking. Ever.',
                          style: TextStyle(color: AppTheme.textVariantColor, fontSize: 13, fontFamily: 'Inter', height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppTheme.textVariantColor),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Links
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  _buildActionLink('Export my data', Icons.file_download_outlined, _exportData),
                  const Divider(height: 1, indent: 64, endIndent: 24, color: Color(0xFFF0F0F0)),
                  _buildActionLink('Backup & restore', Icons.cloud_outlined, () {}),
                  const Divider(height: 1, indent: 64, endIndent: 24, color: Color(0xFFF0F0F0)),
                  _buildActionLink('Help & support', Icons.help_outline_rounded, () {}),
                  const Divider(height: 1, indent: 64, endIndent: 24, color: Color(0xFFF0F0F0)),
                  _buildActionLink('About Nudge', Icons.info_outline_rounded, () {}),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppTheme.textColor,
        fontFamily: 'Inter',
      ),
    );
  }

  Widget _buildProCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7862E8), Color(0xFF574EB1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 48), // Mascot representation
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('✨', style: TextStyle(fontSize: 12)),
                      SizedBox(width: 4),
                      Text(
                        'Most popular',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'ADHD Pro — \$6.99/mo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Unlock advanced AI coaching, insights & unlimited habits',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontFamily: 'Inter',
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chevron_right_rounded, color: AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceToggle({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFF4F1FC),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, fontFamily: 'Inter', color: AppTheme.textColor),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textVariantColor, fontFamily: 'Inter'),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: AppTheme.checkGreen,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: AppTheme.outlineVariantColor,
          ),
        ],
      ),
    );
  }

  Widget _buildActionLink(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textVariantColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  fontFamily: 'Inter',
                  color: AppTheme.textColor,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textVariantColor),
          ],
        ),
      ),
    );
  }
}