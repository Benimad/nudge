import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/notifications/notification_service.dart';

/// Editable morning/evening reminder times — the onboarding values were
/// previously write-once with no way to change them. Rescheduling happens on
/// save so a new time takes effect immediately.
class ReminderSettingsSheet extends StatefulWidget {
  const ReminderSettingsSheet({super.key});

  @override
  State<ReminderSettingsSheet> createState() => _ReminderSettingsSheetState();
}

class _ReminderSettingsSheetState extends State<ReminderSettingsSheet> {
  TimeOfDay _morning = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _evening = const TimeOfDay(hour: 20, minute: 0);
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _morning = _parse(prefs.getString('morning_reminder')) ?? _morning;
      _evening = _parse(prefs.getString('evening_reminder')) ?? _evening;
      _loaded = true;
    });
  }

  TimeOfDay? _parse(String? raw) {
    if (raw == null) return null;
    final parts = raw.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  Future<void> _pick(bool morning) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: morning ? _morning : _evening,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: context.colors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => morning ? _morning = picked : _evening = picked);
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('morning_reminder', '${_morning.hour}:${_morning.minute}');
    await prefs.setString('evening_reminder', '${_evening.hour}:${_evening.minute}');

    final svc = NotificationService();
    await svc.scheduleHabitReminders(
      habitId: 'morning_nudge',
      title: 'Good morning!',
      body: 'Start your day with one small win.',
      reminderTimes: [_morning.hour * 60 + _morning.minute],
      transitionWarningMinutes: 10,
    );
    await svc.scheduleHabitReminders(
      habitId: 'evening_nudge',
      title: 'Evening review',
      body: 'Take a moment to check in with your habits.',
      reminderTimes: [_evening.hour * 60 + _evening.minute],
      transitionWarningMinutes: 10,
    );

    if (mounted) {
      Navigator.pop(context);
      Get.snackbar('Reminders updated', 'Your nudge times are saved.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 16,
        left: 24,
        right: 24,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 5,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: context.colors.outlineVariant,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          Text(
            'Reminder times',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
              color: context.colors.text,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Gentle nudges — never red, never shaming.',
            style: TextStyle(fontSize: 14, color: context.colors.textVariant, fontFamily: 'Inter'),
          ),
          const SizedBox(height: 24),
          if (!_loaded)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else ...[
            _row(context, 'Morning reminder', Icons.wb_sunny_outlined, _morning, () => _pick(true)),
            const SizedBox(height: 12),
            _row(context, 'Evening review', Icons.nightlight_round, _evening, () => _pick(false)),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 0,
                ),
                child: const Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, IconData icon, TimeOfDay time, VoidCallback onTap) {
    return Semantics(
      button: true,
      label: '$label, currently ${time.format(context)}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(icon, color: context.colors.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, fontFamily: 'Inter', color: context.colors.text)),
              ),
              Text(time.format(context),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.colors.text, fontFamily: 'Inter')),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: context.colors.textVariant, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
