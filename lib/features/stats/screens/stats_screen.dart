import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/stats_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/brain_mascot.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final StatsController controller = Get.put(StatsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Obx(() {
            final totalWins = controller.totalWins.value;
            final bestStreak = controller.bestStreak.value;
            final weekCompletion = controller.weekCompletion.value;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Custom Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.bar_chart_rounded, color: context.colors.primary, size: 28),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your progress',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: context.colors.text,
                                  fontFamily: 'Inter',
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                'See how you\'re doing',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: context.colors.textVariant,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: context.colors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: context.colors.outlineVariant, width: 1.5),
                        ),
                        child: Icon(Icons.filter_alt_outlined, color: context.colors.text, size: 22),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Top Metric Cards
                  Row(
                    children: [
                      _buildMetricCard(
                        context: context,
                        value: '${(weekCompletion * 100).toInt()}%',
                        label1: 'this week',
                        label2: 'completion rate',
                        icon: Icons.track_changes_rounded,
                        color: context.colors.primary,
                        bgColor: context.colors.iconBubble,
                      ),
                      const SizedBox(width: 12),
                      _buildMetricCard(
                        context: context,
                        value: '$bestStreak',
                        label1: 'best streak',
                        label2: 'days in a row',
                        icon: Icons.local_fire_department_rounded,
                        color: context.colors.success,
                        bgColor: context.isDarkTheme ? const Color(0xFF16332A) : const Color(0xFFEAF8F1),
                      ),
                      const SizedBox(width: 12),
                      _buildMetricCard(
                        context: context,
                        value: '$totalWins',
                        label1: 'total wins',
                        label2: 'all-time',
                        icon: Icons.emoji_events_rounded,
                        color: context.colors.warning,
                        bgColor: context.isDarkTheme ? const Color(0xFF3A2E12) : const Color(0xFFFFF6E5),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Chart Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: context.colors.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Habits completed — ${controller.selectedTimeRange.value}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                            color: context.colors.text,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Builder(builder: (context) {
                          final data = controller.chartData;
                          final labels = controller.chartLabels;
                          if (data.isEmpty) {
                            return const SizedBox(height: 180);
                          }
                          return _buildWeeklyChart(context, data, labels);
                        }),
                        const SizedBox(height: 16),

                        // Legend
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLegendItem(context, 'Peak days', context.colors.primary),
                            const SizedBox(width: 24),
                            _buildLegendItem(context, 'Other days', const Color(0xFF98E2BB)),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Time range toggle
                        Row(
                          children: ['Week', 'Month', '3 Months', 'Year'].map((range) {
                            final isSelected = range == controller.selectedTimeRange.value;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => controller.setTimeRange(range),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? context.colors.primary : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    range,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                      color: isSelected ? Colors.white : context.colors.textVariant,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // AI Insight Card
                  _buildAiInsightCard(context),

                  const SizedBox(height: 24),
                ],
              ),
            );
        }),
      ),
    );
  }

  Widget _buildMetricCard({
    required BuildContext context,
    required String value,
    required String label1,
    required String label2,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: context.colors.cardShadow,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
                color: color,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label1,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.colors.text,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label2,
              style: TextStyle(
                fontSize: 12,
                color: context.colors.textVariant,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: context.colors.textVariant,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart(BuildContext context, List<double> data, List<String> labels) {
    final displayData = data;
    final maxValue = displayData.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 1.0,
          minY: 0,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 0.25,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: context.colors.outlineVariant.withValues(alpha: 0.5),
                strokeWidth: 1,
                dashArray: [4, 4],
              );
            },
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (value % 0.25 != 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      '${(value * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 11,
                        color: context.colors.textVariant,
                        fontFamily: 'Inter',
                      ),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= labels.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      labels[idx],
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colors.textVariant,
                        fontFamily: 'Inter',
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(displayData.length, (index) {
            final isPeak = maxValue > 0 && displayData[index] == maxValue;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: displayData[index],
                  color: isPeak ? context.colors.primary : const Color(0xFF98E2BB),
                  width: 18,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildAiInsightCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.iconBubble,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.colors.primary,
                  shape: BoxShape.circle,
                ),
                child: const BrainMascot(size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'AI insight',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  fontFamily: 'Inter',
                  color: context.colors.primary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: controller.refreshInsight,
                child: Icon(Icons.refresh_rounded, color: context.colors.primary, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            controller.aiInsight.value.isNotEmpty
                ? controller.aiInsight.value
                // Honest empty state — never invent a pattern that isn't in the data.
                : "Not enough data yet. Keep checking habits off for a few days and I'll spot your patterns — like which day of the week is your superpower.",
            style: TextStyle(
              fontSize: 15,
              color: context.colors.text,
              fontFamily: 'Inter',
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
