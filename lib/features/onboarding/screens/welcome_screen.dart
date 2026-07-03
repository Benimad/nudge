import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/widgets/brain_mascot.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final AuthService _authService = AuthService();
  String? _selectedBrainType;

  static const List<Map<String, dynamic>> _brainTypes = [
    {'label': 'ADHD', 'icon': Icons.bolt_rounded},
    {'label': 'Autism', 'icon': Icons.all_inclusive_rounded},
    {'label': 'Anxiety', 'icon': Icons.cloud_outlined},
    {'label': 'Neurotypical', 'icon': Icons.person_outline_rounded},
    {'label': 'Not sure', 'icon': Icons.help_outline_rounded},
  ];

  Future<void> _onGetStarted() async {
    if (_selectedBrainType == null) {
      Get.snackbar(
        'Select your brain type',
        'This helps Nudge personalize your experience.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.warningColor,
        colorText: Colors.white,
      );
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('brain_type', _selectedBrainType!);
    if (mounted) {
      Get.toNamed('/onboarding/goals');
    }
  }

  Future<void> _onSignIn() async {
    try {
      await _authService.signInWithGoogle();
      if (mounted) {
        Get.offAllNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Sign In Failed',
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppTheme.warningContainerColor,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 28),

                      // Brain mascot — pops in, then floats gently.
                      const BrainMascot(size: 168)
                          .animate()
                          .scale(
                            begin: const Offset(0.6, 0.6),
                            end: const Offset(1, 1),
                            duration: 700.ms,
                            curve: Curves.elasticOut,
                          )
                          .then()
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .moveY(begin: 0, end: -6, duration: 2200.ms, curve: Curves.easeInOut),
                      const SizedBox(height: 24),

                      Text(
                        'Nudge',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                          fontFamily: 'Inter',
                          height: 1.1,
                        ),
                      ).animate().fadeIn(duration: 500.ms, delay: 150.ms).slideY(begin: 0.25, end: 0, curve: Curves.easeOutCubic),
                      const SizedBox(height: 8),
                      const Text(
                        'Gentle habits for real brains',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textVariantColor,
                          fontFamily: 'Inter',
                        ),
                      ).animate().fadeIn(duration: 500.ms, delay: 280.ms).slideY(begin: 0.25, end: 0, curve: Curves.easeOutCubic),
                      const SizedBox(height: 28),

                      // Brain type selector — stadium pills, staggered entrance.
                      ...List.generate(_brainTypes.length, (i) {
                        final label = _brainTypes[i]['label'] as String;
                        final icon = _brainTypes[i]['icon'] as IconData;
                        final isSelected = _selectedBrainType == label;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _BrainTypePill(
                            label: label,
                            icon: icon,
                            isSelected: isSelected,
                            onTap: () => setState(() => _selectedBrainType = label),
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 400.ms, delay: (380 + i * 80).ms)
                            .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic);
                      }),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton(
                          onPressed: _onGetStarted,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Get started',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ).animate().fadeIn(duration: 400.ms, delay: 850.ms).slideY(begin: 0.4, end: 0, curve: Curves.easeOutCubic),
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: _onSignIn,
                        child: const Text(
                          'Sign in',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 17,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ).animate().fadeIn(duration: 400.ms, delay: 950.ms),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Full-width stadium pill. Selected: solid purple with a white circle holding
/// a purple check. Unselected: white with a purple type icon and soft shadow.
class _BrainTypePill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _BrainTypePill({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        height: 62,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(31),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
              child: isSelected
                  ? Container(
                      key: const ValueKey('check'),
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded, color: AppTheme.primaryColor, size: 20),
                    )
                  : SizedBox(
                      key: const ValueKey('icon'),
                      width: 30,
                      height: 30,
                      child: Icon(icon, color: AppTheme.primaryColor, size: 26),
                    ),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textColor,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
