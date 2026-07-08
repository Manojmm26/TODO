import 'package:chronos/src/core/theme/app_theme.dart';
import 'package:chronos/src/features/dashboard/presentation/dashboard_metrics.dart';
import 'package:chronos/src/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/local/app_database.dart';

class DailyDigestCard extends StatelessWidget {
  const DailyDigestCard({
    super.key,
    required this.tasksAsync,
    required this.sessionsAsync,
  });

  final AsyncValue<List<Task>> tasksAsync;
  final AsyncValue<List<FocusSession>> sessionsAsync;

  @override
  Widget build(BuildContext context) {
    final isLoading = tasksAsync.isLoading || sessionsAsync.isLoading;
    if (isLoading) {
      return const SectionCard(
        title: 'Daily Digest',
        subtitle: 'Snapshot of today & weekly goals',
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (tasksAsync.hasError || sessionsAsync.hasError) {
      final error = tasksAsync.error ?? sessionsAsync.error;
      return SectionCard(
        title: 'Daily Digest',
        subtitle: 'Snapshot of today & weekly goals',
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Unable to load digest: $error'),
        ),
      );
    }

    final tasks = tasksAsync.value ?? const [];
    final sessions = sessionsAsync.value ?? const [];

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    
    // Count tasks completed today
    final completedTasksToday = tasks.where((t) {
      return isTaskCompleted(t) && t.updatedAt.isAfter(todayStart);
    }).length;

    final focusMinutesTodayValue = focusMinutesToday(sessions);

    // Calculate weekly progress scoped to this week (Monday to Sunday)
    final startOfWeek = todayStart.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    final weeklyTasks = tasks.where((t) {
      final due = t.dueDate;
      if (due != null && due.isAfter(startOfWeek) && due.isBefore(endOfWeek)) {
        return true;
      }
      if (isTaskCompleted(t) && t.updatedAt.isAfter(startOfWeek) && t.updatedAt.isBefore(endOfWeek)) {
        return true;
      }
      return false;
    }).toList();
    final completedWeekly = weeklyTasks.where(isTaskCompleted).length;
    final weeklyProgressPercent = weeklyTasks.isNotEmpty
        ? (completedWeekly / weeklyTasks.length) * 100
        : 0.0;

    final upcomingDeadlinesCount = upcomingDeadlines(tasks);

    return SectionCard(
      title: 'Daily Digest',
      subtitle: 'Snapshot of today & weekly goals',
      child: Row(
        children: [
          Expanded(
            child: _DigestMetric(
              label: 'Completed Tasks',
              value: completedTasksToday.toString(),
              trend: '$upcomingDeadlinesCount deadlines soon',
              icon: Icons.check_circle_rounded,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _DigestMetric(
              label: 'Focus Minutes',
              value: '$focusMinutesTodayValue',
              trend: 'Sessions today: ${sessionsTodayCount(sessions)}',
              icon: Icons.timelapse_rounded,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _DigestMetric(
              label: 'Weekly Progress',
              value: '${weeklyProgressPercent.round()}%',
              trend: '${weeklyTasks.length} tasks this week',
              icon: Icons.flag_circle_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _DigestMetric extends StatelessWidget {
  const _DigestMetric({
    required this.label,
    required this.value,
    required this.trend,
    required this.icon,
  });

  final String label;
  final String value;
  final String trend;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Theme.of(
                  context,
                ).extension<CustomColors>()!.focusAccent!,
              ),
              const Spacer(),
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Text(trend, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}
