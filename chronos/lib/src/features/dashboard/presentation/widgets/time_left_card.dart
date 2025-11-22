import 'package:chronos/src/core/theme/app_theme.dart';
import 'package:chronos/src/features/dashboard/presentation/dashboard_metrics.dart';
import 'package:chronos/src/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';

class TimeLeftCard extends StatelessWidget {
  const TimeLeftCard({super.key});

  static const _dotCount = 108;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final todayFrac = timeLeftFractionToday();
    final weekFrac = timeLeftFractionWeek();
    final monthFrac = timeLeftFractionMonth();

    int todayDots = (todayFrac * _dotCount).round();
    int weekDots = (weekFrac * _dotCount).round();
    int monthDots = (monthFrac * _dotCount).round();

    String fmtMinutes(int minutes) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      if (h > 0) return '${h}h ${m}m';
      return '${m}m';
    }

    final now = DateTime.now();
    final endOfDay = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));
    final endOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1)).add(const Duration(days: 7));
    final endOfMonth = (now.month < 12)
        ? DateTime(now.year, now.month + 1, 1)
        : DateTime(now.year + 1, 1, 1);

    final minutesTodayLeft = endOfDay
        .difference(now)
        .inMinutes
        .clamp(0, 24 * 60);
    final minutesWeekLeft = endOfWeek
        .difference(now)
        .inMinutes
        .clamp(0, 7 * 24 * 60);
    final minutesMonthLeft = endOfMonth
        .difference(now)
        .inMinutes
        .clamp(0, 31 * 24 * 60);

    String fmtDaysHours(int minutes) {
      final days = minutes ~/ (60 * 24);
      final hours = (minutes % (60 * 24)) ~/ 60;
      if (days > 0) return '${days}d ${hours}h';
      return '${hours}h';
    }

    Widget buildRow(
      String label,
      int filled,
      int total,
      String subtitle, {
      bool wrap = false,
    }) {
      final color = Theme.of(context).extension<CustomColors>()!.focusAccent!;
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(subtitle, style: theme.textTheme.labelMedium),
              ],
            ),
            const SizedBox(height: 8),
            if (!wrap)
              Row(
                children: List.generate(total, (index) {
                  final isFilled = index < filled;
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: isFilled
                            ? color
                            : theme.colorScheme.onSurface.withValues(
                                alpha: .12,
                              ),
                      ),
                    ),
                  );
                }),
              )
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(total, (index) {
                  final isFilled = index < filled;
                  return Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: isFilled
                          ? color
                          : theme.colorScheme.onSurface.withValues(alpha: .12),
                    ),
                  );
                }),
              ),
          ],
        ),
      );
    }

    return SectionCard(
      title: 'Time Left',
      subtitle: 'Remaining time for today, this week and this month',
      child: Column(
        children: [
          buildRow(
            'Today',
            todayDots,
            _dotCount,
            fmtMinutes(minutesTodayLeft),
            wrap: true,
          ),
          buildRow(
            'Week',
            weekDots,
            _dotCount,
            fmtDaysHours(minutesWeekLeft),
            wrap: true,
          ),
          buildRow(
            'Month',
            monthDots,
            _dotCount,
            fmtDaysHours(minutesMonthLeft),
            wrap: true,
          ),
        ],
      ),
    );
  }
}
