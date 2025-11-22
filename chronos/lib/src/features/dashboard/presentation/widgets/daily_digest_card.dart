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
    final completedTasks = tasks.where(isTaskCompleted).length;
    final focusMinutesTodayValue = focusMinutesToday(sessions);
    final weeklyProgressPercent = weeklyProgress(tasks) * 100;
    final upcomingDeadlinesCount = upcomingDeadlines(tasks);

    return SectionCard(
      title: 'Daily Digest',
      subtitle: 'Snapshot of today & weekly goals',
      child: Row(
        children: [
          Expanded(
            child: _DigestMetric(
              label: 'Completed Tasks',
              value: completedTasks.toString(),
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
              trend: '${tasks.length} tasks tracked',
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
