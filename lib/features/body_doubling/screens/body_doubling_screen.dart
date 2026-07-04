import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../controllers/body_doubling_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/pro_gate.dart';
import '../../../shared/widgets/brain_mascot.dart';

class BodyDoublingScreen extends StatelessWidget {
  const BodyDoublingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BodyDoublingController>();

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: ProGate(
          featureName: 'Body Doubling',
          child: Column(
            children: [
              // Custom Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: context.colors.surface,
                          shape: BoxShape.circle,
                          boxShadow: context.colors.cardShadow,
                        ),
                        child: Icon(Icons.chevron_left_rounded, color: context.colors.text, size: 28),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: context.isDarkTheme ? const Color(0xFF16332A) : const Color(0xFFEAF8F1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.people_alt_outlined, color: context.colors.success, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Body doubling session',
                            style: TextStyle(
                              color: context.colors.success,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter',
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 44), // To balance the back button
                  ],
                ),
              ),
              
              Expanded(
                child: Obx(() {
                  if (!controller.isSessionActive.value && !controller.isPaused.value) {
                    return _buildSetupView(context, controller);
                  }
                  return _buildActiveSessionView(context, controller);
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSetupView(BuildContext context, BodyDoublingController controller) {
    final TextEditingController taskController = TextEditingController();
    int selectedMinutes = 25;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Start a focus session',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, fontFamily: 'Inter', color: context.colors.text),
          ),
          const SizedBox(height: 8),
          Text(
            'Working with others helps ADHD brains stay on track.',
            style: TextStyle(color: context.colors.textVariant, fontFamily: 'Inter', fontSize: 15),
          ),
          const SizedBox(height: 32),
          Text('What are you working on?', style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Inter', color: context.colors.text)),
          const SizedBox(height: 12),
          TextField(
            controller: taskController,
            style: TextStyle(color: context.colors.text),
            decoration: InputDecoration(
              hintText: 'e.g. Cleaning the kitchen',
              filled: true,
              fillColor: context.colors.surfaceContainer,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text('Session length', style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Inter', color: context.colors.text)),
          const SizedBox(height: 12),
          StatefulBuilder(builder: (context, setState) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [15, 25, 45, 60].map((mins) {
                final isSelected = selectedMinutes == mins;
                return GestureDetector(
                  onTap: () => setState(() => selectedMinutes = mins),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? context.colors.primary : context.colors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? context.colors.primary : context.colors.outlineVariant,
                      ),
                    ),
                    child: Text(
                      '$mins',
                      style: TextStyle(
                        color: isSelected ? Colors.white : context.colors.text,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          }),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                if (taskController.text.isNotEmpty) {
                  controller.startSession(taskController.text, selectedMinutes);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                elevation: 0,
              ),
              child: const Text('Start session', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSessionView(BuildContext context, BodyDoublingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Timer Display
          Column(
            children: [
              SizedBox(
                width: 280,
                height: 280,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 280,
                      height: 280,
                      child: CircularProgressIndicator(
                        value: 1 - controller.progress,
                        strokeWidth: 12,
                        backgroundColor: context.colors.primary.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(context.colors.primary),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          controller.formattedTime,
                          style: TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.w600,
                            color: context.colors.primary,
                            fontFamily: 'Inter',
                            letterSpacing: -2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'time remaining',
                          style: TextStyle(
                            color: context.colors.textVariant,
                            fontSize: 16,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().scale(begin: const Offset(0.9, 0.9), duration: 400.ms, curve: Curves.easeOutCubic),
              const SizedBox(height: 32),

              Text(
                'You\'re working on',
                style: TextStyle(color: context.colors.textVariant, fontSize: 16, fontFamily: 'Inter', fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                controller.taskName.value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: context.colors.text,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),

          Column(
            children: [
              // Stats
              Row(
                children: [
                  _buildStatCard(
                    context: context,
                    icon: Icons.people_outline,
                    value: '${controller.communityCount.value}',
                    label: 'people\nworking',
                  ),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    context: context,
                    icon: Icons.bar_chart_rounded,
                    value: '${controller.sessionsCompletedToday.value}',
                    label: 'sessions\ntoday',
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

              const SizedBox(height: 24),

              // Motivational Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.colors.iconBubble,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: context.colors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const BrainMascot(size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'You\'ve got this. Focus isn\'t about motivation — it\'s about showing up. We\'re here with you. 💜',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: context.colors.text,
                          fontFamily: 'Inter',
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
            ],
          ),

          // Controls
          Row(
            children: [
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: () => controller.pauseResumeSession(),
                    icon: Icon(
                      controller.isPaused.value ? Icons.play_arrow_rounded : Icons.pause_rounded,
                      color: context.colors.primary,
                    ),
                    label: Text(
                      controller.isPaused.value ? 'Resume' : 'Pause',
                      style: TextStyle(
                        color: context.colors.primary,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                        fontSize: 16,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: context.colors.outlineVariant, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => _showEndConfirmation(context, controller),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'End session', 
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
        ],
      ),
    );
  }

  Widget _buildStatCard({required BuildContext context, required IconData icon, required String value, required String label}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: context.colors.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.colors.iconBubble,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: context.colors.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: context.colors.primary,
                    fontFamily: 'Inter',
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.colors.textVariant,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Inter',
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEndConfirmation(BuildContext context, BodyDoublingController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End session?', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
        content: const Text('You\'re doing great. Are you sure you want to stop now?', style: TextStyle(fontFamily: 'Inter')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Keep going', style: TextStyle(color: context.colors.primary, fontFamily: 'Inter', fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () {
              controller.endSession();
              Navigator.pop(context);
            },
            child: Text('End now', style: TextStyle(color: context.colors.textVariant, fontFamily: 'Inter')),
          ),
        ],
      ),
    );
  }
}
