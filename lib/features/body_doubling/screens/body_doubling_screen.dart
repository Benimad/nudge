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
    final controller = Get.put(BodyDoublingController());

    return Scaffold(
      backgroundColor: Colors.white,
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
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: const Icon(Icons.chevron_left_rounded, color: AppTheme.textColor, size: 28),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF8F1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.people_alt_outlined, color: AppTheme.checkGreen, size: 16),
                          const SizedBox(width: 8),
                          const Text(
                            'Body doubling session',
                            style: TextStyle(
                              color: AppTheme.checkGreen,
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
          const Text(
            'Start a focus session',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, fontFamily: 'Inter'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Working with others helps ADHD brains stay on track.',
            style: TextStyle(color: AppTheme.textVariantColor, fontFamily: 'Inter', fontSize: 15),
          ),
          const SizedBox(height: 32),
          const Text('What are you working on?', style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Inter')),
          const SizedBox(height: 12),
          TextField(
            controller: taskController,
            decoration: InputDecoration(
              hintText: 'e.g. Cleaning the kitchen',
              filled: true,
              fillColor: AppTheme.surfaceContainerColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text('Session length', style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Inter')),
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
                      color: isSelected ? AppTheme.primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryColor : AppTheme.outlineVariantColor,
                      ),
                    ),
                    child: Text(
                      '$mins',
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textColor,
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
                backgroundColor: AppTheme.primaryColor,
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
                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          controller.formattedTime,
                          style: const TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                            fontFamily: 'Inter',
                            letterSpacing: -2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'time remaining',
                          style: TextStyle(
                            color: AppTheme.textVariantColor,
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
              
              const Text(
                'You\'re working on',
                style: TextStyle(color: AppTheme.textVariantColor, fontSize: 16, fontFamily: 'Inter', fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                controller.taskName.value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textColor,
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
                    icon: Icons.people_outline,
                    value: '${controller.communityCount.value}',
                    label: 'people\nworking',
                  ),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    icon: Icons.bar_chart_rounded,
                    value: '${controller.sessionsCompletedToday.value}', // Fake data for sessions today based on controller
                    label: 'sessions\ntoday',
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
              
              const SizedBox(height: 24),
              
              // Motivational Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F1FC),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const BrainMascot(size: 32),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'You\'ve got this. Focus isn\'t about motivation — it\'s about showing up. We\'re here with you. 💜',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textColor,
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
                      color: AppTheme.primaryColor,
                    ),
                    label: Text(
                      controller.isPaused.value ? 'Resume' : 'Pause',
                      style: const TextStyle(
                        color: AppTheme.primaryColor, 
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                        fontSize: 16,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.outlineVariantColor, width: 1.5),
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
                      backgroundColor: AppTheme.primaryColor,
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

  Widget _buildStatCard({required IconData icon, required String value, required String label}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F1FC),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value, 
                  style: const TextStyle(
                    fontSize: 28, 
                    fontWeight: FontWeight.w700, 
                    color: AppTheme.primaryColor,
                    fontFamily: 'Inter',
                  ),
                ),
                Text(
                  label, 
                  style: const TextStyle(
                    fontSize: 12, 
                    color: AppTheme.textVariantColor,
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
            child: const Text('Keep going', style: TextStyle(color: AppTheme.primaryColor, fontFamily: 'Inter', fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () {
              controller.endSession();
              Navigator.pop(context);
            },
            child: const Text('End now', style: TextStyle(color: AppTheme.textVariantColor, fontFamily: 'Inter')),
          ),
        ],
      ),
    );
  }
}
