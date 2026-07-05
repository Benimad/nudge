import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../habits/controllers/home_controller.dart';
import '../../habits/models/habit_model.dart';
import '../../ai_coach/services/ai_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/brain_mascot.dart';
import '../../../shared/widgets/skeleton_loader.dart';

class ParalysisModeScreen extends StatefulWidget {
  const ParalysisModeScreen({super.key});

  @override
  State<ParalysisModeScreen> createState() => _ParalysisModeScreenState();
}

class _ParalysisModeScreenState extends State<ParalysisModeScreen> {
  List<Map<String, String>>? _microSteps;
  List<bool> _stepChecked = [];
  bool _isLoadingAi = false;
  HabitModel? _selectedHabit;

  Future<void> _breakdownTask(HabitModel habit) async {
    setState(() {
      _isLoadingAi = true;
      _selectedHabit = habit;
    });

    final aiService = AiCoachService();
    await Future.delayed(const Duration(milliseconds: 500));
    final rawSteps = aiService.getTaskBreakdown(habit.name);
    
    // Convert to map with title and dummy time
    final times = ['30 sec', '2 min', '5 min', '1 min'];
    final steps = rawSteps.asMap().entries.map((e) {
      return {
        'title': e.value,
        'time': times[e.key % times.length],
      };
    }).toList();

    setState(() {
      _microSteps = steps;
      _stepChecked = List.filled(steps.length, false);
      _isLoadingAi = false;
    });
  }

  void _toggleStep(int index) {
    setState(() {
      _stepChecked[index] = !_stepChecked[index];
    });
    if (_stepChecked.every((c) => c) && _selectedHabit != null) {
      Get.find<HomeController>().toggleHabit(_selectedHabit!);
      Get.snackbar(
        'All steps done!',
        'Your "${_selectedHabit!.name}" habit is complete 🎉',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: context.colors.success,
        colorText: Colors.white,
      );
      setState(() {
        _microSteps = null;
        _stepChecked = [];
      });
    }
  }

  void _showTaskSelector() {
    final habits = Get.find<HomeController>().habits;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Which habit are you stuck on?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
            const SizedBox(height: 16),
            ...habits.map((h) => ListTile(
              title: Text(h.name, style: const TextStyle(fontFamily: 'Inter')),
              onTap: () {
                Navigator.pop(context);
                _breakdownTask(h);
              },
            )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: context.colors.surface,
                          shape: BoxShape.circle,
                          boxShadow: context.colors.cardShadow,
                        ),
                        child: Icon(Icons.chevron_left_rounded, color: context.colors.text, size: 30),
                      ),
                    ).animate().fadeIn(duration: 350.ms).scale(begin: const Offset(0.7, 0.7), curve: Curves.easeOutBack),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [Color(0xFFFFA000), Color(0xFFFFD54F)],
                          center: Alignment.topLeft,
                          radius: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFA000).withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                    ).animate().scale(begin: const Offset(0.6, 0.6), duration: 550.ms, curve: Curves.elasticOut),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            const Text(
              'Paralysis mode',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFFA000),
                fontFamily: 'Inter',
                letterSpacing: -0.5,
              ),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),
            
            const SizedBox(height: 12),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'It\'s okay — let\'s make this easier.\nFind one tiny task to get momentum.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: context.colors.textVariant,
                  fontFamily: 'Inter',
                  height: 1.4,
                ),
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
            
            const SizedBox(height: 32),
            
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                physics: const BouncingScrollPhysics(),
                children: [
                  // Chat Bubble
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const BrainMascot(size: 56),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: context.colors.iconBubble,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(20),
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                          ),
                          child: Text(
                            'I notice you\'ve been inactive for 40 min.\n\nWant me to break your task into micro-steps?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: context.colors.text,
                              fontFamily: 'Inter',
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1, end: 0),
                  
                  const SizedBox(height: 24),
                  
                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _showTaskSelector,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Yes, help me start',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
                  
                  const SizedBox(height: 32),
                  
                  if (_isLoadingAi) ...[
                    Text(
                      'Breaking it down into tiny steps…',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: context.colors.textVariant,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 14),
                    const SkeletonList(count: 3, padding: EdgeInsets.zero),
                  ] else if (_microSteps != null) ...[
                    Text(
                      'Try one of these micro-steps',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.colors.text,
                        fontFamily: 'Inter',
                      ),
                    ).animate().fadeIn(),
                    
                    const SizedBox(height: 16),
                    
                    ...List.generate(_microSteps!.length, (index) {
                      final step = _microSteps![index];
                      final isChecked = _stepChecked[index];
                      
                      return GestureDetector(
                        onTap: () => _toggleStep(index),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: context.colors.surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: context.colors.cardShadow,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isChecked ? Icons.check_circle_rounded : Icons.schedule_rounded,
                                color: context.colors.primary,
                                size: 32,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      step['title']!,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isChecked ? context.colors.outline : context.colors.text,
                                        decoration: isChecked ? TextDecoration.lineThrough : null,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      step['time']!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: isChecked ? context.colors.outline : context.colors.primary,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, color: context.colors.outlineVariant, size: 24),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: (500 + index * 100).ms).slideY(begin: 0.1, end: 0);
                    }),
                    
                    const SizedBox(height: 16),
                    
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: context.colors.iconBubble,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome, color: context.colors.primary, size: 28),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Small steps build momentum.\nYou\'ve got this.',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: context.colors.textVariant,
                                fontFamily: 'Inter',
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 32),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
