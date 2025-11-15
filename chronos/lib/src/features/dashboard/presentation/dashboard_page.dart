import 'dart:math' as math;

import 'package:chronos/src/shared/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'plan_task_dialog.dart';

import '../../../application/focus_session_controller.dart';
import '../../../application/providers.dart';
import '../../../application/sub_task_controller.dart';
import '../../../application/task_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/local/app_database.dart';
import '../../../shared/widgets/section_card.dart';
import '../data/dashboard_models.dart';
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
                width: isWide ? width * .55 : width - 48,
                child: _TimelineOverview(
                  tasksAsync: tasksAsync,
                  subTasksAsync: subTasksAsync,
                ),
              ),
                SizedBox(
                width: isWide ? width * .35 - 48 : width - 48,
                child: const _TimeLeftCard(),
              ),
              SizedBox(
                width: isWide ? width * .35 - 48 : width - 48,
                child: _GoalsProgress(goalsAsync: goalsAsync),
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

class _AddSubTaskField extends ConsumerStatefulWidget {
  const _AddSubTaskField({required this.taskId, required this.nextOrder});

  final String taskId;
  final int nextOrder;

  @override
  ConsumerState<_AddSubTaskField> createState() => _AddSubTaskFieldState();
}

class _AddSubTaskFieldState extends ConsumerState<_AddSubTaskField> {
  final _controller = TextEditingController();
  bool _isAdding = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdding) {
      return TextButton.icon(
        onPressed: () => setState(() => _isAdding = true),
        icon: const Icon(Icons.add_outlined, size: 18),
        label: const Text('Add sub-task'),
      );
    }

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            enabled: !_isSaving,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Sub-task title',
              isDense: true,
            ),
            onSubmitted: (_) => _submit(context),
          ),
        ),
        IconButton(
          tooltip: 'Save sub-task',
          onPressed: _isSaving ? null : () => _submit(context),
          icon: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_rounded),
        ),
        IconButton(
          tooltip: 'Cancel',
          onPressed: _isSaving
              ? null
              : () {
                  _controller.clear();
                  setState(() => _isAdding = false);
                },
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }

  Future<void> _submit(BuildContext context) async {
    final title = _controller.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sub-task title required')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final subTasks = ref.read(subTaskControllerProvider);
    try {
      await subTasks.create(taskId: widget.taskId, title: title, sortOrder: widget.nextOrder);
      _controller.clear();
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isAdding = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add sub-task: $error')),
        );
      }
    }
  }
}

class _SubTaskList extends StatelessWidget {
  const _SubTaskList({required this.subTasks});

  final List<SubTask> subTasks;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: subTasks
          .map((subTask) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: _SubTaskTile(subTask: subTask),
              ))
          .toList(),
    );
  }
}

class _SubTaskTile extends ConsumerStatefulWidget {
  const _SubTaskTile({required this.subTask});

  final SubTask subTask;

  @override
  ConsumerState<_SubTaskTile> createState() => _SubTaskTileState();
}

class _SubTaskTileState extends ConsumerState<_SubTaskTile> {
  bool _isEditing = false;
  bool _isSaving = false;
  late final TextEditingController _controller = TextEditingController(text: widget.subTask.title);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subTask = widget.subTask;
    final controller = ref.read(subTaskControllerProvider);

    return Row(
      children: [
        Checkbox(
          value: subTask.isCompleted,
          onChanged: (value) => controller.toggleCompletion(subTask.id, value ?? false),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: 4),
        if (_isEditing)
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: true,
              enabled: !_isSaving,
              decoration: const InputDecoration(isDense: true),
              onSubmitted: (_) => _save(context),
            ),
          )
        else
          Expanded(
            child: Text(
              subTask.title,
              style: theme.textTheme.bodyMedium?.copyWith(
                decoration: subTask.isCompleted ? TextDecoration.lineThrough : null,
                color: subTask.isCompleted ? theme.colorScheme.onSurfaceVariant : null,
              ),
            ),
          ),
        if (_isEditing)
          IconButton(
            tooltip: 'Save',
            onPressed: _isSaving ? null : () => _save(context),
            icon: _isSaving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check_rounded, size: 18),
          )
        else
          IconButton(
            tooltip: 'Edit',
            onPressed: () {
              setState(() {
                _controller.text = subTask.title;
                _isEditing = true;
              });
            },
            icon: const Icon(Icons.edit_outlined, size: 18),
          ),
        IconButton(
          tooltip: _isEditing ? 'Cancel' : 'Delete',
          onPressed: _isSaving
              ? null
              : () async {
                  if (_isEditing) {
                    setState(() => _isEditing = false);
                    _controller.text = subTask.title;
                    return;
                  }
                  await controller.delete(subTask.id);
                },
          icon: Icon(_isEditing ? Icons.close_rounded : Icons.delete_outline_rounded, size: 18),
        ),
      ],
    );
  }

  Future<void> _save(BuildContext context) async {
    final title = _controller.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title required')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      await ref.read(subTaskControllerProvider).rename(widget.subTask.id, title);
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isEditing = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to rename: $error')),
        );
      }
    }
  }
}

class _TimelineOverview extends StatelessWidget {
  const _TimelineOverview({required this.tasksAsync, required this.subTasksAsync});

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

class _BucketGroup extends StatelessWidget {
  const _BucketGroup({required this.bucket, required this.tasks, required this.subTasksByTask});

  final TimelineBucket bucket;
  final List<Task> tasks;
  final Map<String, List<SubTask>> subTasksByTask;

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
          if (tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No tasks in this bucket yet',
                style: theme.textTheme.labelMedium,
              ),
            )
          else
            ...tasks.map(
              (task) => _TimelineTile(
                task: task,
                bucket: bucket,
                subTasks: subTasksByTask[task.id] ?? const <SubTask>[],
              ),
            ),
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.task, required this.bucket, required this.subTasks});

  final Task task;
  final TimelineBucket bucket;
  final List<SubTask> subTasks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dueText = task.dueDate != null
        ? DateFormat('MMM d · h:mm a').format(task.dueDate!)
        : 'No due date';
    final bucketColor = bucket.color;
    final progress = subTasks.isNotEmpty ? subTaskCompletionProgress(subTasks) : taskProgress(task);
    final priority = priorityFromInt(task.priority);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(.4),
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
              if (task.isRecurring)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Tooltip(
                    message: 'Recurring task',
                    child: Icon(Icons.autorenew_rounded, size: 18, color: bucketColor),
                  ),
                ),
              _PriorityChip(priority: priority),
              const SizedBox(width: 8),
              Consumer(builder: (context, ref, _) {
                final taskController = ref.read(taskControllerProvider);
                final isCompleted = task.status >= taskStatusCompleted;
                return IconButton(
                  tooltip: isCompleted ? 'Completed' : 'Mark complete',
                  onPressed: isCompleted ? null : () => taskController.completeTask(task),
                  icon: Icon(isCompleted ? Icons.check_circle : Icons.radio_button_unchecked, color: isCompleted ? bucketColor : null),
                );
              }),
            ],
          ),
          if (task.projectId != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Project: ${task.projectId}',
                style: theme.textTheme.labelMedium,
              ),
            )
          else if (task.goalId != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Goal: ${task.goalId}',
                style: theme.textTheme.labelMedium,
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surface,
              valueColor: AlwaysStoppedAnimation(bucketColor),
            ),
          ),
          if (subTasks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SubTaskList(subTasks: subTasks),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _AddSubTaskField(
              taskId: task.id,
              nextOrder: subTasks.length,
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
  const _GoalsProgress({required this.goalsAsync});

  final AsyncValue<List<Goal>> goalsAsync;

  @override
  Widget build(BuildContext context) {
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
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No goals yet. Create one to start tracking progress.'),
                )
              : Column(
                  children: goals
                      .map((goal) => _GoalTile(goal: goal))
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
    final progress = ((goal.progressOverride ?? 0.0).clamp(0.0, 1.0)).toDouble();
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
        final focusController = ref.read(focusSessionControllerProvider.notifier);

        return SectionCard(
          title: 'Time Clock',
          subtitle: activeSession != null ? 'In focus now' : 'Current focus session',
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
                          Text(displayLabel, style: theme.textTheme.titleMedium),
                          const SizedBox(height: 6),
                          Text(
                            displayDuration,
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            targetMinutes != null ? 'of $targetMinutes mins' : 'No target',
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
                      icon: Icon(activeSession != null ? Icons.pause_rounded : Icons.play_arrow_rounded),
                      label: Text(activeSession != null ? 'Pause Session' : 'Start Session'),
                    ),
                    const SizedBox(height: 16),
                    if (recentSessions.isEmpty)
                      Text('No focus sessions logged yet.', style: theme.textTheme.bodySmall)
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
          Text('${durationMinutes} mins', style: theme.textTheme.labelMedium),
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

  static const _dotCount = 99;

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
    final endOfDay = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final endOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1))
        .add(const Duration(days: 7));
    final endOfMonth = (now.month < 12)
        ? DateTime(now.year, now.month + 1, 1)
        : DateTime(now.year + 1, 1, 1);

    final minutesTodayLeft = endOfDay.difference(now).inMinutes.clamp(0, 24 * 60);
    final minutesWeekLeft = endOfWeek.difference(now).inMinutes.clamp(0, 7 * 24 * 60);
    final minutesMonthLeft = endOfMonth.difference(now).inMinutes.clamp(0, 31 * 24 * 60);

    String fmtDaysHours(int minutes) {
      final days = minutes ~/ (60 * 24);
      final hours = (minutes % (60 * 24)) ~/ 60;
      if (days > 0) return '${days}d ${hours}h';
      if (hours > 0) return '${hours}h';
      return '${minutes}m';
    }

  Widget buildRow(String label, int filled, int total, String subtitle, {bool wrap = true}) {
      final color = ChronosTheme.focusAccent;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(label, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
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
                        color: isFilled ? color : theme.colorScheme.onSurface.withOpacity(.12),
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
                      color: isFilled ? color : theme.colorScheme.onSurface.withOpacity(.12),
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
          buildRow('Week', weekDots, _dotCount, fmtDaysHours(minutesWeekLeft), wrap: true),
          buildRow('Month', monthDots, _dotCount, fmtDaysHours(minutesMonthLeft), wrap: true),
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
