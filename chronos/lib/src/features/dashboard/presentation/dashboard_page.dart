import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/section_card.dart';
import '../data/dashboard_models.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final bool isWide = width > 1200;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today • ${DateFormat.yMMMMEEEEd().format(DateTime.now())}',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            children: [
              SizedBox(
                width: isWide ? width * .55 : width - 48,
                child: const _TimelineOverview(),
              ),
              SizedBox(
                width: isWide ? width * .35 - 48 : width - 48,
                child: const _GoalsProgress(),
              ),
              SizedBox(
                width: isWide ? width * .4 : width - 48,
                child: const _FocusClockCard(),
              ),
              SizedBox(
                width: isWide ? width * .5 - 48 : width - 48,
                child: const _DailyDigestCard(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimelineOverview extends StatelessWidget {
  const _TimelineOverview();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Timeline Buckets',
      subtitle: 'Upcoming, planned, and someday items',
      trailing: FilledButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('Plan Task'),
      ),
      child: Column(
        children: TimelineBucket.values.map((bucket) {
          final tasks = mockTimelineTasks
              .where((task) => task.bucket == bucket)
              .toList();
          return _BucketGroup(bucket: bucket, tasks: tasks);
        }).toList(),
      ),
    );
  }
}

class _BucketGroup extends StatelessWidget {
  const _BucketGroup({required this.bucket, required this.tasks});

  final TimelineBucket bucket;
  final List<TimelineTask> tasks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: bucket.color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                bucket.label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text('${tasks.length} items', style: theme.textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: 12),
          ...tasks.map((task) => _TimelineTile(task: task)),
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.task});

  final TimelineTask task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dueText = DateFormat('MMM d · h:mm a').format(task.due);
    final bucketColor = task.bucket.color;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surfaceVariant.withOpacity(.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _PriorityChip(priority: task.priority),
            ],
          ),
          if (task.project != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(task.project!, style: theme.textTheme.labelMedium),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(
              value: task.progress,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surface,
              valueColor: AlwaysStoppedAnimation(bucketColor),
            ),
          ),
          Text(
            dueText,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.priority});

  final TaskPriority priority;

  Color _chipColor(TaskPriority priority) {
    return switch (priority) {
      TaskPriority.high => const Color(0xFFE53935),
      TaskPriority.medium => const Color(0xFFFFA000),
      TaskPriority.low => const Color(0xFF43A047),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _chipColor(priority);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withOpacity(.15),
      ),
      child: Text(
        priority.label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _GoalsProgress extends StatelessWidget {
  const _GoalsProgress();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Goal Progress',
      subtitle: 'Visual tracker for major goals',
      trailing: IconButton(
        onPressed: () {},
        icon: const Icon(Icons.analytics_rounded),
      ),
      child: Column(
        children: mockGoals.map((goal) => _GoalTile(goal: goal)).toList(),
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({required this.goal});

  final GoalProgress goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: goal.color.withOpacity(.12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${(goal.progress * 100).round()}%',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(.4),
              valueColor: AlwaysStoppedAnimation(goal.color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Due ${DateFormat.MMMd().format(goal.deadline)}',
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _FocusClockCard extends StatelessWidget {
  const _FocusClockCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = 0.65;
    return SectionCard(
      title: 'Time Clock',
      subtitle: 'Current focus session',
      trailing: OutlinedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.more_horiz),
        label: const Text('History'),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 200,
              child: CustomPaint(
                painter: _FocusClockPainter(progress: progress),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Deep Work', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text(
                        '18:24',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('of 30 mins', style: theme.textTheme.labelMedium),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start Session'),
                ),
                const SizedBox(height: 16),
                ...mockFocusSummary.map(
                  (session) => _FocusSummaryTile(summary: session),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusClockPainter extends CustomPainter {
  _FocusClockPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final strokeWidth = 16.0;
    final radius = (size.shortestSide - strokeWidth) / 2;
    final backgroundPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = Colors.white.withOpacity(.15)
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = ChronosTheme.focusAccent
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _FocusClockPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _FocusSummaryTile extends StatelessWidget {
  const _FocusSummaryTile({required this.summary});

  final FocusSessionSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: theme.colorScheme.surfaceVariant.withOpacity(.4),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt_rounded, color: ChronosTheme.focusAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              summary.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text('${summary.minutes} mins', style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _DailyDigestCard extends StatelessWidget {
  const _DailyDigestCard();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Daily Digest',
      subtitle: 'Snapshot of today & weekly goals',
      child: Row(
        children: [
          Expanded(
            child: _DigestMetric(
              label: 'Completed Tasks',
              value: mockDigest.completedTasks.toString(),
              trend: '+2 vs yesterday',
              icon: Icons.check_circle_rounded,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _DigestMetric(
              label: 'Focus Minutes',
              value: '${mockDigest.totalFocusMinutes}',
              trend: 'Pomodoro streak 3',
              icon: Icons.timelapse_rounded,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _DigestMetric(
              label: 'Weekly Progress',
              value: '${(mockDigest.weeklyGoalCompletion * 100).round()}%',
              trend: '${mockDigest.upcomingDeadlines} deadlines soon',
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
        borderRadius: BorderRadius.circular(18),
        color: theme.colorScheme.surfaceVariant.withOpacity(.35),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: ChronosTheme.focusAccent),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
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
