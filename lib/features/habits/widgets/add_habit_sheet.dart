import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/habit_model.dart';
import '../controllers/home_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../shared/widgets/brain_mascot.dart';

class AddHabitSheet extends StatefulWidget {
  final HabitModel? habit;
  const AddHabitSheet({super.key, this.habit});

  @override
  State<AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends State<AddHabitSheet> {
  late TextEditingController _nameController;
  String _selectedEmoji = '🎯'; // Default
  String _selectedTimeOfDay = 'morning';
  String _selectedReminderStyle = 'soft';
  bool _aiBreakdownEnabled = true;
  String _selectedColor = '#7862E8'; // Default new purple

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.habit?.name ?? '');
    if (widget.habit != null) {
      _selectedEmoji = widget.habit!.emoji;
      _selectedTimeOfDay = widget.habit!.timeOfDay;
      _selectedReminderStyle = widget.habit!.reminderStyle;
      _aiBreakdownEnabled = widget.habit!.aiBreakdownEnabled;
      _selectedColor = widget.habit!.color;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveHabit() {
    final trimmedName = _nameController.text.trim();
    if (trimmedName.isEmpty) return;

    final habit = HabitModel(
      id: widget.habit?.id,
      name: trimmedName,
      timeOfDay: _selectedTimeOfDay,
      reminderStyle: _selectedReminderStyle,
      color: _selectedColor,
      emoji: _selectedEmoji,
      aiBreakdownEnabled: _aiBreakdownEnabled,
      isActive: widget.habit?.isActive ?? true,
      habitOrder: widget.habit?.habitOrder ?? 0,
    );

    final controller = Get.find<HomeController>();
    if (widget.habit == null) {
      controller.addHabit(habit);
    } else {
      controller.updateHabit(habit);
    }

    _scheduleReminderIfNeeded(habit);
    Navigator.pop(context);
  }

  Future<void> _scheduleReminderIfNeeded(HabitModel habit) async {
    if (habit.reminderStyle == 'none') return;

    final Map<String, int> timeMap = {
      'morning': 8 * 60,
      'afternoon': 14 * 60,
      'evening': 18 * 60,
      'anytime': 9 * 60,
    };

    final reminderTime = timeMap[habit.timeOfDay] ?? 9 * 60;
    try {
      await NotificationService().scheduleHabitReminders(
        habitId: habit.id,
        title: 'Nudge: ${habit.name}',
        body: 'Time for your ${habit.name} habit!',
        reminderTimes: [reminderTime],
        transitionWarningMinutes: 10,
      );
    } catch (e) {
      debugPrint('Failed to schedule reminder: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 16,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 48,
                height: 5,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppTheme.outlineVariantColor,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            
            // Header
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.outlineVariantColor, width: 1.5),
                    ),
                    child: const Icon(Icons.chevron_left_rounded, color: AppTheme.textColor, size: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  widget.habit == null ? 'Add habit' : 'Edit habit',
                  style: const TextStyle(
                    fontSize: 24, 
                    fontWeight: FontWeight.w700, 
                    color: AppTheme.textColor,
                    fontFamily: 'Inter',
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                if (widget.habit != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                    onPressed: () {
                      Get.find<HomeController>().deleteHabit(widget.habit!.id);
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Name Input
            const Text('What\'s the habit?', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, fontFamily: 'Inter')),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              autofocus: widget.habit == null,
              maxLength: 50,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 16),
              decoration: InputDecoration(
                hintText: 'e.g. Take medication',
                hintStyle: const TextStyle(color: AppTheme.textVariantColor, fontFamily: 'Inter'),
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE4DFFF), width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE4DFFF), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              ),
              onChanged: (val) => setState(() {}),
            ),
            const SizedBox(height: 32),
            
            // Time of Day
            const Text('When do you want to do it?', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, fontFamily: 'Inter')),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildTimeChip('morning', 'Morning', Icons.wb_sunny_rounded),
                  const SizedBox(width: 8),
                  _buildTimeChip('afternoon', 'Afternoon', Icons.wb_sunny_outlined),
                  const SizedBox(width: 8),
                  _buildTimeChip('evening', 'Evening', Icons.nightlight_round),
                  const SizedBox(width: 8),
                  _buildTimeChip('anytime', 'Anytime', Icons.schedule_rounded),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Reminders
            const Text('How should we remind you?', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, fontFamily: 'Inter')),
            const SizedBox(height: 16),
            _buildReminderCard(
              id: 'soft',
              title: 'Soft nudge (no badge)',
              subtitle: 'Gentle reminder, no streak pressure',
              icon: Icons.notifications_none_rounded,
            ),
            const SizedBox(height: 12),
            _buildReminderCard(
              id: 'vibrate',
              title: 'Vibrate only',
              subtitle: 'Discreet vibration, no notification',
              icon: Icons.vibration_rounded,
            ),
            const SizedBox(height: 32),
            
            // AI Breakdown
            const Text('Want AI help breaking this down?', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, fontFamily: 'Inter')),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.outlineVariantColor, width: 1.5),
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
                    child: const BrainMascot(size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('AI task breakdown help', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, fontFamily: 'Inter')),
                        SizedBox(height: 2),
                        Text('Get micro-steps when you feel stuck', style: TextStyle(color: AppTheme.textVariantColor, fontSize: 13, fontFamily: 'Inter')),
                      ],
                    ),
                  ),
                  Switch(
                    value: _aiBreakdownEnabled,
                    onChanged: (val) => setState(() => _aiBreakdownEnabled = val),
                    activeColor: Colors.white,
                    activeTrackColor: AppTheme.primaryColor,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: AppTheme.outlineVariantColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _nameController.text.trim().isEmpty ? null : _saveHabit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  disabledBackgroundColor: AppTheme.primaryColor.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
                child: Text(
                  widget.habit == null ? 'Save habit' : 'Update habit',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
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

  Widget _buildTimeChip(String id, String label, IconData icon) {
    final isSelected = _selectedTimeOfDay == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedTimeOfDay = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.outlineVariantColor,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppTheme.textVariantColor,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textVariantColor,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderCard({required String id, required String title, required String subtitle, required IconData icon}) {
    final isSelected = _selectedReminderStyle == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedReminderStyle = id),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF9F8FF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.outlineVariantColor,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : const Color(0xFFF4F1FC),
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? const Color(0xFFE4DFFF) : Colors.transparent),
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      fontFamily: 'Inter',
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textVariantColor,
                      fontSize: 13,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textVariantColor.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
            ),
          ],
        ),
      ),
    );
  }
}
