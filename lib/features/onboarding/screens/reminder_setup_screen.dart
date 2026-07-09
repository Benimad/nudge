import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/notifications/notification_service.dart';

class ReminderSetupScreen extends StatefulWidget {
  const ReminderSetupScreen({super.key});

  @override
  State<ReminderSetupScreen> createState() => _ReminderSetupScreenState();
}

class _ReminderSetupScreenState extends State<ReminderSetupScreen> {
  TimeOfDay _morningTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _eveningTime = const TimeOfDay(hour: 20, minute: 0);
  bool _snoozeFriendly = true;

  Future<void> _pickTime(bool isMorning) async {
    final initial = isMorning ? _morningTime : _eveningTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: context.colors.primary,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isMorning) {
          _morningTime = picked;
        } else {
          _eveningTime = picked;
        }
      });
    }
  }

  Future<void> _onContinue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('morning_reminder', '${_morningTime.hour}:${_morningTime.minute}');
    await prefs.setString('evening_reminder', '${_eveningTime.hour}:${_eveningTime.minute}');
    await prefs.setBool('snooze_friendly', _snoozeFriendly);
    await prefs.setBool('onboarding_complete', true);

    // Schedule morning and evening nudges. Notification scheduling is a
    // nice-to-have — never let it block onboarding completion.
    try {
      await NotificationService().scheduleHabitReminders(
        habitId: 'morning_nudge',
        title: 'Good morning!',
        body: 'Start your day with one small win.',
        reminderTimes: [_morningTime.hour * 60 + _morningTime.minute],
        transitionWarningMinutes: 10,
      );
      await NotificationService().scheduleHabitReminders(
        habitId: 'evening_nudge',
        title: 'Evening review',
        body: 'Take a moment to check in with your habits.',
        reminderTimes: [_eveningTime.hour * 60 + _eveningTime.minute],
        transitionWarningMinutes: 10,
      );
      await NotificationService().requestPermission();
      if (!await NotificationService().canScheduleExactAlarms()) {
        await NotificationService().requestExactAlarmPermission();
      }
    } catch (e) {
      debugPrint('Failed to schedule onboarding reminders: $e');
    }

    if (mounted) Get.offNamed('/home');
  }

  Future<void> _skip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    Get.offNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set gentle reminders',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: context.colors.text,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No red badges. Soft nudges only.',
              style: TextStyle(
                fontSize: 14,
                color: context.colors.textVariant,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 40),

            // Morning reminder
            _buildTimePicker(
              context: context,
              label: 'Morning reminder',
              icon: Icons.wb_sunny_outlined,
              time: _morningTime,
              onTap: () => _pickTime(true),
            ),
            const SizedBox(height: 24),

            // Evening review
            _buildTimePicker(
              context: context,
              label: 'Evening review',
              icon: Icons.nightlight_round,
              time: _eveningTime,
              onTap: () => _pickTime(false),
            ),
            const SizedBox(height: 24),

            // Snooze-friendly toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: context.colors.cardShadow,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Snooze-friendly reminders',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            fontFamily: 'Inter',
                            color: context.colors.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Never disappear until you check them',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.colors.textVariant,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _snoozeFriendly,
                    onChanged: (val) => setState(() => _snoozeFriendly = val),
                    activeTrackColor: context.colors.primary.withValues(alpha: 0.5),
                    activeThumbColor: context.colors.primary,
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Allow notifications button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Allow notifications',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: _skip,
                child: Text(
                  'Set up later',
                  style: TextStyle(
                    color: context.colors.textVariant,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker({
    required BuildContext context,
    required String label,
    required IconData icon,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: context.colors.cardShadow,
        ),
        child: Row(
          children: [
            Icon(icon, color: context.colors.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  fontFamily: 'Inter',
                  color: context.colors.text,
                ),
              ),
            ),
            Text(
              time.format(context),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: context.colors.text,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: context.colors.textVariant, size: 20),
          ],
        ),
      ),
    );
  }
}