import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/app_settings.dart';
import '../../../core/services/firestore_service.dart';
import '../services/subscription_service.dart';
import 'reminder_settings_sheet.dart';

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
  bool _largeText = false;
  bool _offlineMode = false;
  bool _analyticsOn = true;

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
        _largeText = prefs.getBool('large_text') ?? false;
        _offlineMode = prefs.getBool('offline_mode') ?? false;
        _analyticsOn = !(prefs.getBool('analytics_opt_out') ?? false);
      });
    }
  }

  Future<void> _saveToggle(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  void _notifyAppSettingsChanged() {
    // Push accessibility changes to the live widget tree (no restart).
    AppSettings.instance.reload();
  }

  void _openReminderSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ReminderSettingsSheet(),
    );
  }

  Future<void> _confirmDeleteAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete all data?'),
        content: const Text(
          'This permanently removes every habit, completion, focus session, and preference from this device. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete everything', style: TextStyle(color: context.colors.warning)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteAllData();
    }
  }

  Future<void> _openHelpAndSupport() async {
    // Same support address the published privacy policy lists.
    final uri = Uri(
      scheme: 'mailto',
      path: 'adamlaalami72@gmail.com',
      query: 'subject=${Uri.encodeComponent('Nudge Feedback')}',
    );
    if (!await launchUrl(uri)) {
      if (mounted) {
        Get.snackbar(
          'Couldn\'t open email',
          'Reach us at adamlaalami72@gmail.com',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  void _showBackupInfo() {
    final signedIn = FirebaseAuth.instance.currentUser?.isAnonymous == false;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup & restore'),
        content: Text(
          signedIn
              ? 'Your habits and progress sync automatically to the cloud as you use the app. Reinstalling and signing in with the same account restores your data.'
              : 'Sign in with Google to back up your habits and progress automatically, so you can restore them on a new device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Nudge',
      applicationVersion: _appVersion,
      applicationIcon: Icon(Icons.psychology_rounded, color: context.colors.primary, size: 40),
      children: const [
        SizedBox(height: 12),
        Text('An ADHD-friendly habit tracker and focus companion.'),
      ],
    );
  }

  Future<void> _deleteAllData() async {
    try {
      // Cloud first (best-effort), so we honor the promise that "Delete all
      // data" removes the cloud mirror too — even if the local wipe races ahead.
      try {
        await FirestoreService().deleteAllCloudData();
      } catch (_) {
        // Offline / no account — local wipe below still proceeds.
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await DatabaseHelper.instance.deleteAllData();
      await NotificationService().cancelAll();
      if (mounted) {
        Get.offAllNamed('/onboarding/welcome');
      }
    } catch (e) {
      Get.snackbar(
        'Delete failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.warningColor,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _exportData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final db = await DatabaseHelper.instance.database;

      // Full, portable snapshot — every row that is the user's, per the GDPR
      // access right the privacy policy promises.
      final habits = await db.query('habits');
      final completions = await db.query('completions');
      final focusSessions = await db.query('focus_sessions');
      final moods = await db.query('moods');

      final data = {
        'user_name': _userName,
        'brain_type': _brainType,
        'goals': _decodeGoals(prefs.getString('user_goals')),
        'dopamine_points': prefs.getInt('dopamine_points') ?? 0,
        'habits': habits,
        'completions': completions,
        'focus_sessions': focusSessions,
        'moods': moods,
        'settings': {
          'sensory_safe_ui': _sensorySafe,
          'large_text': _largeText,
          'offline_mode': _offlineMode,
          'analytics_enabled': _analyticsOn,
        },
        'exported_at': DateTime.now().toIso8601String(),
        'schema_version': 1,
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      final tempPath = '${(await getTemporaryDirectory()).path}/nudge_export.json';
      await File(tempPath).writeAsString(jsonString);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(tempPath)],
          subject: 'Nudge Data Export',
          text: 'My complete Nudge data export.',
        ),
      );
    } catch (e) {
      _errorSnack('Export failed', e);
    }
  }

  List<String> _decodeGoals(String? raw) {
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List).cast<String>();
    } catch (_) {
      return const [];
    }
  }

  /// A human-readable 30-day summary the user can hand to a therapist or coach —
  /// completion rate, focus time, and per-habit consistency. No raw internals.
  Future<void> _shareProgressReport() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now();
      final since = now.subtract(const Duration(days: 30));

      final habits = await db.query('habits', where: 'isActive = 1');
      final comps = await db.query(
        'completions',
        where: 'completedAt >= ?',
        whereArgs: [since.toIso8601String()],
      );
      final focusMin = await DatabaseHelper.instance.getTotalFocusMinutesSince(since);

      final byHabit = <String, int>{};
      for (final c in comps) {
        final id = c['habitId'] as String;
        byHabit[id] = (byHabit[id] ?? 0) + 1;
      }

      final buf = StringBuffer()
        ..writeln('Nudge — 30-day progress report')
        ..writeln('For: $_userName')
        ..writeln('Generated: ${now.toIso8601String().substring(0, 10)}')
        ..writeln('')
        ..writeln('Total check-ins: ${comps.length}')
        ..writeln('Focus time: $focusMin minutes')
        ..writeln('Active habits: ${habits.length}')
        ..writeln('')
        ..writeln('Per habit (check-ins in last 30 days):');
      for (final h in habits) {
        final id = h['id'] as String;
        buf.writeln('  • ${h['name']}: ${byHabit[id] ?? 0}');
      }
      buf
        ..writeln('')
        ..writeln('Shared voluntarily by the user. Not a medical record.');

      await SharePlus.instance.share(
        ShareParams(text: buf.toString(), subject: 'My Nudge progress report'),
      );
    } catch (e) {
      _errorSnack('Report failed', e);
    }
  }

  void _errorSnack(String title, Object e) {
    Get.snackbar(
      title,
      e.toString(),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppTheme.warningColor,
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          physics: const BouncingScrollPhysics(),
          children: [
            // Custom Header
            Text(
              'Settings',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: context.colors.text,
                fontFamily: 'Inter',
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Customize Nudge to work for your brain.',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: context.colors.textVariant,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 32),

            // Pro Card
            if (!_isLoadingPro)
              _isPro
                  ? _buildProStatusCard(context)
                  : GestureDetector(
                      onTap: () async {
                        await Get.toNamed('/paywall');
                        _loadData();
                      },
                      child: _buildProCard(context),
                    ),
            const SizedBox(height: 32),

            // Preferences Section
            _buildSectionHeader(context, 'Preferences'),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  _buildPreferenceToggle(
                    context: context,
                    title: 'Sensory-safe UI',
                    subtitle: 'Reduce motion & skip full-screen celebrations',
                    icon: Icons.auto_awesome_rounded,
                    value: _sensorySafe,
                    onChanged: (val) {
                      setState(() => _sensorySafe = val);
                      _saveToggle('sensory_safe_ui', val);
                      _notifyAppSettingsChanged();
                    },
                  ),
                  Divider(height: 1, indent: 72, endIndent: 24, color: context.colors.divider),
                  _buildPreferenceToggle(
                    context: context,
                    title: 'Larger text',
                    subtitle: 'Bump up type size across the app',
                    icon: Icons.format_size_rounded,
                    value: _largeText,
                    onChanged: (val) {
                      setState(() => _largeText = val);
                      _saveToggle('large_text', val);
                      _notifyAppSettingsChanged();
                    },
                  ),
                  Divider(height: 1, indent: 72, endIndent: 24, color: context.colors.divider),
                  _buildPreferenceToggle(
                    context: context,
                    title: 'Offline mode',
                    subtitle: 'Keep everything on this device — no sync, AI, or analytics',
                    icon: Icons.cloud_off_rounded,
                    value: _offlineMode,
                    onChanged: (val) async {
                      setState(() => _offlineMode = val);
                      await _saveToggle('offline_mode', val);
                      // Take effect immediately — no restart.
                      await AnalyticsService.refreshPrivacyPrefs();
                      await NotificationService().applyOfflinePreference();
                    },
                  ),
                  Divider(height: 1, indent: 72, endIndent: 24, color: context.colors.divider),
                  _buildPreferenceToggle(
                    context: context,
                    title: 'Anonymous analytics',
                    subtitle: 'Share content-free usage counts to improve Nudge',
                    icon: Icons.insights_rounded,
                    value: _analyticsOn,
                    onChanged: (val) async {
                      setState(() => _analyticsOn = val);
                      await _saveToggle('analytics_opt_out', !val);
                      await AnalyticsService.refreshPrivacyPrefs();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Reminders section
            _buildSectionHeader(context, 'Reminders'),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: _buildActionLink(
                context,
                'Reminder times',
                Icons.schedule_rounded,
                _openReminderSettings,
              ),
            ),
            const SizedBox(height: 32),

            // Privacy & Data Section
            _buildSectionHeader(context, 'Privacy & data'),
            const SizedBox(height: 16),

            // On-device AI Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: context.colors.iconBubble,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.lock_rounded, color: context.colors.primary, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Local-first & private',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, fontFamily: 'Inter', color: context.colors.text),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Your habits live on your device. AI replies are processed by Google Gemini; anonymous, content-free analytics can be turned off above. No ads, ever. Offline mode keeps everything local.',
                          style: TextStyle(color: context.colors.textVariant, fontSize: 13, fontFamily: 'Inter', height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: context.colors.textVariant),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Links
            Container(
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  _buildActionLink(context, 'Export my data', Icons.file_download_outlined, _exportData),
                  Divider(height: 1, indent: 64, endIndent: 24, color: context.colors.divider),
                  _buildActionLink(context, 'Share progress report', Icons.summarize_outlined, _shareProgressReport),
                  Divider(height: 1, indent: 64, endIndent: 24, color: context.colors.divider),
                  _buildActionLink(context, 'Backup & restore', Icons.cloud_outlined, _showBackupInfo),
                  Divider(height: 1, indent: 64, endIndent: 24, color: context.colors.divider),
                  _buildActionLink(context, 'Help & support', Icons.help_outline_rounded, _openHelpAndSupport),
                  Divider(height: 1, indent: 64, endIndent: 24, color: context.colors.divider),
                  _buildActionLink(context, 'About Nudge', Icons.info_outline_rounded, _showAboutDialog),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: _buildActionLink(
                context,
                'Delete all data',
                Icons.delete_outline_rounded,
                _confirmDeleteAllData,
                color: context.colors.warning,
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: context.colors.text,
        fontFamily: 'Inter',
      ),
    );
  }

  Widget _buildProCard(BuildContext context) {
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
            color: context.colors.primary.withValues(alpha: 0.3),
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
            child: Icon(Icons.chevron_right_rounded, color: context.colors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildProStatusCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.isDarkTheme ? const Color(0xFF16332A) : const Color(0xFFEAF8F1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: context.colors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ADHD Pro — active',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, fontFamily: 'Inter', color: context.colors.text),
                ),
                const SizedBox(height: 2),
                Text(
                  'Advanced AI coaching, insights & unlimited habits unlocked',
                  style: TextStyle(fontSize: 13, color: context.colors.textVariant, fontFamily: 'Inter'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceToggle({
    required BuildContext context,
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
            decoration: BoxDecoration(
              color: context.colors.iconBubble,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: context.colors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, fontFamily: 'Inter', color: context.colors.text),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: context.colors.textVariant, fontFamily: 'Inter'),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: context.colors.success,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: context.colors.outlineVariant,
          ),
        ],
      ),
    );
  }

  Widget _buildActionLink(BuildContext context, String title, IconData icon, VoidCallback onTap, {Color? color}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          children: [
            Icon(icon, color: color ?? context.colors.textVariant, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  fontFamily: 'Inter',
                  color: color ?? context.colors.text,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color ?? context.colors.textVariant),
          ],
        ),
      ),
    );
  }
}