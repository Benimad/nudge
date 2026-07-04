import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../controllers/home_controller.dart';
import '../widgets/habit_list_item.dart';
import '../widgets/progress_header.dart';
import '../widgets/add_habit_sheet.dart';
import '../../../core/theme/app_theme.dart';
import '../../stats/screens/stats_screen.dart';
import '../../ai_coach/screens/ai_coach_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../paralysis_mode/widgets/paralysis_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _screens = const [
    _HomeBody(),
    StatsScreen(),
    AiCoachScreen(),
    SettingsScreen(),
  ];

  static const _navItems = [
    (icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
    (icon: Icons.bar_chart_rounded, activeIcon: Icons.bar_chart_rounded, label: 'Stats'),
    (icon: Icons.mood_outlined, activeIcon: Icons.mood_rounded, label: 'AI Coach'),
    (icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      extendBody: true,
      floatingActionButton: _currentIndex == 0
          ? Padding(
              padding: const EdgeInsets.only(bottom: 78.0),
              child: SizedBox(
                width: 62,
                height: 62,
                child: FloatingActionButton(
                  onPressed: () => _showAddHabitSheet(context),
                  backgroundColor: context.colors.primary,
                  elevation: 0,
                  highlightElevation: 0,
                  shape: const CircleBorder(),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
                ),
              ).animate().scale(
                    begin: const Offset(0, 0),
                    end: const Offset(1, 1),
                    duration: 500.ms,
                    delay: 400.ms,
                    curve: Curves.easeOutBack,
                  ),
            )
          : null,
      bottomNavigationBar: _buildFloatingBottomNav(context),
    );
  }

  Widget _buildFloatingBottomNav(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: List.generate(_navItems.length, (i) => Expanded(child: _buildNavItem(context, i))),
      ),
    ).animate().slideY(begin: 1, end: 0, duration: 600.ms, curve: Curves.easeOutBack);
  }

  Widget _buildNavItem(BuildContext context, int index) {
    final item = _navItems[index];
    final isSelected = _currentIndex == index;
    final color = isSelected ? context.colors.primary : context.colors.inactiveGray;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            scale: isSelected ? 1.0 : 0.92,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            child: Icon(isSelected ? item.activeIcon : item.icon, color: color, size: 26),
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            style: TextStyle(
              color: color,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 12,
              fontFamily: 'Inter',
            ),
            child: Text(item.label),
          ),
        ],
      ),
    );
  }

  void _showAddHabitSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddHabitSheet(),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ProgressHeader(),

            Obx(() => AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: controller.showParalysisBanner.value
                      ? const ParalysisBanner()
                      : const SizedBox(width: double.infinity),
                )),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: Text(
                "Today's habits",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: context.colors.text,
                  letterSpacing: -0.3,
                  fontFamily: 'Inter',
                ),
              ).animate().fadeIn(duration: 450.ms, delay: 250.ms).slideY(begin: 0.2, end: 0),
            ),

            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return Center(child: CircularProgressIndicator(color: context.colors.primary));
                }

                if (controller.habits.isEmpty) {
                  return _buildEmptyState(context);
                }

                return RepaintBoundary(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 140),
                    physics: const BouncingScrollPhysics(),
                    itemCount: controller.habits.length,
                    itemBuilder: (context, index) {
                      return HabitListItem(habit: controller.habits[index], index: index);
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.spa_outlined, size: 64, color: context.colors.outlineVariant),
          const SizedBox(height: 16),
          Text(
            'Add your first habit',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: context.colors.text, fontFamily: 'Quicksand'),
          ),
          const SizedBox(height: 8),
          Text(
            'Start with just one small step',
            style: TextStyle(color: context.colors.textVariant, fontFamily: 'Quicksand'),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _showAddHabitSheet(context),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(160, 48),
              shape: const StadiumBorder(),
            ),
            child: const Text('Add habit'),
          ),
        ],
      ).animate().fadeIn(duration: 500.ms),
    );
  }

  void _showAddHabitSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddHabitSheet(),
    );
  }
}
