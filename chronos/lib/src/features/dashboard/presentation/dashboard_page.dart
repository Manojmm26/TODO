import 'dart:math' as math;
import 'package:chronos/src/features/dashboard/data/dashboard_models.dart';
import 'package:chronos/src/shared/widgets/task_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'plan_task_dialog.dart';

import '../../../application/focus_session_controller.dart';
import '../../../application/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/local/app_database.dart';
import '../../../shared/widgets/section_card.dart';
import 'dashboard_metrics.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksStreamProvider);
    final goalsAsync = ref.watch(goalsStreamProvider);
    final sessionsAsync = ref.watch(focusSessionsStreamProvider);
    final subTasksAsync = ref.watch(subTasksStreamProvider);
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
                width: isWide ? width * .35 - 48 : width - 48,
                child: const _TimeLeftCard(),
              ),
              SizedBox(
                width: isWide ? width * .35 - 48 : width - 48,
                child: _GoalsProgress(goalsAsync: goalsAsync),
              ),
              SizedBox(
                width: isWide ? width * .55 : width - 48,
                child: _TimelineOverview(
                  tasksAsync: tasksAsync,
                  subTasksAsync: subTasksAsync,
                ),
              ),

              SizedBox(
                width: isWide ? width * .4 : width - 48,
                child: _FocusClockCard(sessionsAsync: sessionsAsync),
              ),
              SizedBox(
                width: isWide ? width * .5 - 48 : width - 48,
                child: _DailyDigestCard(
                  tasksAsync: tasksAsync,
                  sessionsAsync: sessionsAsync,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimelineOverview extends StatelessWidget {
  const _TimelineOverview({
    required this.tasksAsync,
    required this.subTasksAsync,
  });

  final AsyncValue<List<Task>> tasksAsync;
  final AsyncValue<List<SubTask>> subTasksAsync;

  @override
  Widget build(BuildContext context) {
    return tasksAsync.when(
      data: (tasks) {
        return subTasksAsync.when(
          data: (subTasks) {
            final grouped = groupTasksByBucket(tasks);
            final subTasksByTask = groupSubTasksByTask(subTasks);
            return SectionCard(
              title: 'Timeline Buckets',
              subtitle: 'Upcoming, planned, and someday items',
              trailing: FilledButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => const PlanTaskDialog(),
                ),
                icon: const Icon(Icons.add_task_rounded),
                label: const Text('Plan Task'),
              ),
              child: Column(
                children: TimelineBucket.values
                    .map(
                      (bucket) => _BucketGroup(
                        bucket: bucket,
                        tasks: grouped[bucket] ?? const [],
                        subTasksByTask: subTasksByTask,
                      ),
                    )
                    .toList(),
              ),
            );
          },
          loading: () => const Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (error, stackTrace) => Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Unable to load sub-tasks: $error'),
            ),
          ),
        );
      },
      loading: () => const Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stackTrace) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Unable to load tasks: $error'),
        ),
      ),
    );
  }
}

class _BucketGroup extends StatefulWidget {
  const _BucketGroup({
    required this.bucket,
    required this.tasks,
    required this.subTasksByTask,
  });

  final TimelineBucket bucket;
  final List<Task> tasks;
  final Map<String, List<SubTask>> subTasksByTask;

  @override
  State<_BucketGroup> createState() => _BucketGroupState();
}

class _BucketGroupState extends State<_BucketGroup> {
  bool _showCompleted = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final incompleteTasks = widget.tasks
        .where((t) => !isTaskCompleted(t))
        .toList();
    final displayTasks = _showCompleted ? widget.tasks : incompleteTasks;
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
                  color: widget.bucket.color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.bucket.label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${incompleteTasks.length} / ${widget.tasks.length} items',
                style: theme.textTheme.labelSmall,
              ),
              const SizedBox(width: 8),
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(1, 1),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () =>
                    setState(() => _showCompleted = !_showCompleted),
                child: Text(
                  _showCompleted
                      ? 'Hide completed'
                      : 'Show completed (${widget.tasks.length - incompleteTasks.length})',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (displayTasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  if (widget.tasks.isEmpty)
                    Icon(
                      Icons.inbox_outlined,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant,
                    )
                  else
                    Icon(
                      Icons.check_circle_outline,
                      size: 48,
                      color: ChronosTheme.focusAccent,
                    ),
                  const SizedBox(height: 8),
                  Text(
                    widget.tasks.isEmpty
                        ? 'No tasks in ${widget.bucket.label.toLowerCase()} yet'
                        : 'All tasks completed!',
                    style: theme.textTheme.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  if (widget.tasks.isEmpty)
                    FilledButton.icon(
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => const PlanTaskDialog(),
                      ),
                      icon: const Icon(Icons.add_task_rounded, size: 16),
                      label: const Text('Plan a task'),
                    )
                  else
                    TextButton.icon(
                      onPressed: () => setState(() => _showCompleted = true),
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                      label: const Text('Show completed'),
                    ),
                ],
              ),
            )
          else
            ...displayTasks.map(
              (task) => TaskTile(task: task, bucket: widget.bucket),
            ),
        ],
      ),
    );
  }
}

class _FocusClockCard extends ConsumerWidget {
  const _FocusClockCard({required this.sessionsAsync});

  final AsyncValue<List<FocusSession>> sessionsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return sessionsAsync.when(
      data: (sessions) {
        final sorted = [...sessions]
          ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
        final activeSession = findActiveSession(sorted);
        final latestSession = sorted.isNotEmpty ? sorted.first : null;
        final referenceSession = activeSession ?? latestSession;
        final progress = sessionProgress(referenceSession);
        final displayDuration = sessionDurationDisplay(referenceSession);
        final displayLabel = sessionLabel(referenceSession);
        final targetMinutes = sessionTargetMinutes(referenceSession);
        final recentSessions = sorted.take(3).toList();
        final focusController = ref.read(
          focusSessionControllerProvider.notifier,
        );

        return SectionCard(
          title: 'Time Clock',
          subtitle: activeSession != null
              ? 'In focus now'
              : 'Current focus session',
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
                          Text(
                            displayLabel,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            displayDuration,
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            targetMinutes != null
                                ? 'of $targetMinutes mins'
                                : 'No target',
                            style: theme.textTheme.labelMedium,
                          ),
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
                      onPressed: () {
                        if (activeSession != null) {
                          focusController.pauseSession();
                        } else {
                          focusController.startSession();
                        }
                      },
                      icon: Icon(
                        activeSession != null
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                      label: Text(
                        activeSession != null
                            ? 'Pause Session'
                            : 'Start Session',
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (recentSessions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          children: [
                            Icon(
                              Icons.access_time_outlined,
                              size: 48,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No focus sessions logged yet.',
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () => focusController.startSession(),
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: const Text('Start your first'),
                            ),
                          ],
                        ),
                      )
                    else
                      ...recentSessions.map(
                        (session) => _FocusSummaryTile(session: session),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stackTrace) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Unable to load focus sessions: $error'),
        ),
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
  const _FocusSummaryTile({required this.session});

  final FocusSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = session.endedAt == null;
    final durationMinutes = sessionDisplayMinutes(session);
    final label = session.notes?.isNotEmpty == true
        ? session.notes!
        : (isActive ? 'Active session' : 'Focus session');
    final timestamp = DateFormat.MMMd().add_jm().format(session.startedAt);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(.4),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt_rounded, color: ChronosTheme.focusAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$label • $timestamp',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text('$durationMinutes mins', style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _DailyDigestCard extends StatelessWidget {
  const _DailyDigestCard({
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

class _TimeLeftCard extends StatelessWidget {
  const _TimeLeftCard();

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
      if (hours > 0) return '${hours}h';
      return '${minutes}m';
    }

    Widget buildRow(
      String label,
      int filled,
      int total,
      String subtitle, {
      bool wrap = true,
    }) {
      final color = ChronosTheme.focusAccent;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
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
                            : theme.colorScheme.onSurface.withOpacity(.12),
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
                          : theme.colorScheme.onSurface.withOpacity(.12),
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
          buildRow('Today', todayDots, _dotCount, fmtMinutes(minutesTodayLeft)),
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
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(.35),
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

class _GoalsProgress extends StatelessWidget {
  const _GoalsProgress({required this.goalsAsync});

  final AsyncValue<List<Goal>> goalsAsync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return goalsAsync.when(
      data: (goals) {
        return SectionCard(
          title: 'Goal Progress',
          subtitle: 'Visual tracker for major goals',
          trailing: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.analytics_rounded),
          ),
          child: goals.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.flag_outlined,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'No goals yet. Create one to start tracking progress.',
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.flag_rounded),
                        label: const Text('Create goal'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: goals.map((goal) => _GoalTile(goal: goal)).toList(),
                ),
        );
      },
      loading: () => const Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stackTrace) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Unable to load goals: $error'),
        ),
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(goal.colorHex);
    final progress = ((goal.progressOverride ?? 0.0).clamp(
      0.0,
      1.0,
    )).toDouble();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: color.withOpacity(.12),
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
                '${(progress * 100).round()}%',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(.4),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            goal.targetDate != null
                ? 'Due ${DateFormat.MMMd().format(goal.targetDate!)}'
                : 'No deadline',
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
