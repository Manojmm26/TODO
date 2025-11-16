import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;

import '../../../application/providers.dart';
import '../../../data/local/app_database.dart' hide chronosDatabaseProvider;
import '../../../shared/widgets/section_card.dart';
import '../../dashboard/data/dashboard_models.dart';
import '../../dashboard/presentation/dashboard_metrics.dart';
import '../application/timeline_filter_controller.dart';
import 'package:chronos/src/application/task_controller.dart';
import 'package:chronos/src/shared/constants.dart';

class TimelinePage extends ConsumerWidget {
  const TimelinePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksStreamProvider);
    final filters = ref.watch(timelineFilterProvider);
    return tasksAsync.when(
      data: (tasks) {
        // Filter by date range first
        final filteredTasks = _filterTasksByDateRange(tasks, filters.dateRange);
        final grouped = groupTasksByBucket(filteredTasks);
        final visibleBuckets = filters.buckets.isEmpty
            ? TimelineBucket.values
            : TimelineBucket.values.where(filters.buckets.contains).toList();
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const CalendarView(),
            // Date Range Filter
            SectionCard(
              title: 'Date Range',
              subtitle: filters.dateRange == null
                  ? 'All dates'
                  : '${DateFormat('MMM d').format(filters.dateRange!.start)} - ${DateFormat('MMM d').format(filters.dateRange!.end)}',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _showDateRangePicker(context, ref),
                    icon: const Icon(Icons.date_range),
                    tooltip: 'Select date range',
                  ),
                  if (filters.dateRange != null)
                    IconButton(
                      onPressed: () => ref
                          .read(timelineFilterProvider.notifier)
                          .clearDateRange(),
                      icon: const Icon(Icons.clear),
                      tooltip: 'Clear date filter',
                    ),
                ],
              ),
              child: const SizedBox(),
            ),
            // Bucket Filters
            SectionCard(
              title: 'Bucket Filters',
              subtitle: 'Toggle which horizons appear below',
              trailing: OverflowBar(
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: () => ref
                        .read(timelineFilterProvider.notifier)
                        .selectAllBuckets(),
                    child: const Text('Select all'),
                  ),
                  TextButton(
                    onPressed: () => ref
                        .read(timelineFilterProvider.notifier)
                        .clearBuckets(),
                    child: const Text('Clear'),
                  ),
                ],
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: TimelineBucket.values
                    .map(
                      (bucket) => FilterChip(
                        label: Text(bucket.label),
                        selected: filters.buckets.contains(bucket),
                        onSelected: (_) => ref
                            .read(timelineFilterProvider.notifier)
                            .toggleBucket(bucket),
                        avatar: Icon(
                          Icons.label_rounded,
                          size: 18,
                          color: bucket.color,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 24),
            ...TimelineBucket.values
                .where(visibleBuckets.contains)
                .map(
                  (bucket) => Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: SectionCard(
                      title: bucket.label,
                      subtitle: _bucketSubtitle(bucket),
                      trailing: IconButton(
                        tooltip: 'Toggle ${bucket.label}',
                        onPressed: () => ref
                            .read(timelineFilterProvider.notifier)
                            .toggleBucket(bucket),
                        icon: Icon(
                          filters.buckets.contains(bucket)
                              ? Icons.filter_alt_off_rounded
                              : Icons.filter_list_rounded,
                        ),
                      ),
                      child: DragTarget<Task>(
                        onWillAcceptWithDetails: (_) => true,
                        onAcceptWithDetails: (droppedTask) {
                          final db = ref.read(chronosDatabaseProvider);
                          final now = DateTime.now();
                          DateTime? newDue;
                          TasksCompanion companion = TasksCompanion(
                            updatedAt: drift.Value(now),
                          );
                          switch (bucket) {
                            case TimelineBucket.immediate:
                              companion = companion.copyWith(
                                flagImmediate: const drift.Value(true),
                              );
                              break;
                            case TimelineBucket.today:
                              final endToday = DateTime(
                                now.year,
                                now.month,
                                now.day,
                                23,
                                59,
                              );
                              newDue = endToday;
                              companion = companion.copyWith(
                                flagToday: const drift.Value(true),
                                dueDate: drift.Value(newDue),
                              );
                              break;
                            case TimelineBucket.upcoming:
                              final nextWeek = now.add(const Duration(days: 7));
                              newDue = DateTime(
                                nextWeek.year,
                                nextWeek.month,
                                nextWeek.day,
                                9,
                                0,
                              );
                              companion = companion.copyWith(
                                dueDate: drift.Value(newDue),
                              );
                              break;
                            case TimelineBucket.backlog:
                              companion = companion.copyWith(
                                flagImmediate: const drift.Value(false),
                                flagToday: const drift.Value(false),
                                dueDate: drift.Value(null),
                              );
                              break;
                          }
                          db.taskDao.updateTask(droppedTask.data.id, companion);
                        },
                        builder: (context, candidateData, rejectedData) {
                          final isDraggingOver = candidateData.isNotEmpty;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isDraggingOver
                                  ? bucket.color.withOpacity(0.1)
                                  : null,
                              borderRadius: BorderRadius.circular(12),
                              border: isDraggingOver
                                  ? Border.all(
                                      color: bucket.color.withOpacity(0.3),
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: Builder(
                              builder: (_) {
                                final bucketTasks =
                                    grouped[bucket] ?? const <Task>[];
                                if (bucketTasks.isEmpty) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text('No tasks in this bucket.'),
                                  );
                                }
                                return Column(
                                  children: bucketTasks
                                      .map(
                                        (task) => _TimelineRow(
                                          task: task,
                                          bucket: bucket,
                                        ),
                                      )
                                      .toList(),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                )
                .toList(),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Unable to load tasks: $error')),
    );
  }

  Future<void> _showDateRangePicker(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final initialRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0),
    );
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange:
          ref.read(timelineFilterProvider).dateRange ?? initialRange,
    );
    if (picked != null) {
      ref.read(timelineFilterProvider.notifier).setDateRange(picked);
    }
  }

  static List<Task> _filterTasksByDateRange(
    List<Task> tasks,
    DateTimeRange? range,
  ) {
    if (range == null) return tasks;
    return tasks.where((task) {
      final due = task.dueDate;
      return due != null &&
          !due.isBefore(range.start) &&
          !due.isAfter(range.end);
    }).toList();
  }

  String _bucketSubtitle(TimelineBucket bucket) => switch (bucket) {
    TimelineBucket.immediate => 'Critical tasks flagged for now',
    TimelineBucket.today => 'Planned for the next 24h',
    TimelineBucket.upcoming => 'Scheduled later this week',
    TimelineBucket.backlog => 'Someday / backlog ideas',
  };
}

class _TimelineRow extends ConsumerWidget {
  const _TimelineRow({required this.task, required this.bucket});

  final Task task;
  final TimelineBucket bucket;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dueText = task.dueDate != null
        ? DateFormat('EEE · h:mm a').format(task.dueDate!)
        : 'No due date';
    final progress = taskProgress(task);
    final priority = priorityFromInt(task.priority);
    final taskController = ref.read(taskControllerProvider);
    final isCompleted = task.status >= taskStatusCompleted;

    return Draggable<Task>(
      data: task,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(.3),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    isCompleted
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isCompleted ? bucket.color : theme.hintColor,
                  ),
                  onPressed: () async {
                    if (isCompleted) {
                      await taskController.reopenTask(task);
                    } else {
                      await taskController.completeTask(task);
                    }
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: isCompleted
                      ? 'Mark as incomplete'
                      : 'Mark as complete',
                ),
                const SizedBox(width: 8),
                Expanded(
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
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: isCompleted ? theme.hintColor : null,
                              ),
                            ),
                          ),
                          if (task.isRecurring)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Tooltip(
                                message: 'Recurring task',
                                child: Icon(
                                  Icons.autorenew_rounded,
                                  size: 16,
                                  color: bucket.color,
                                ),
                              ),
                            ),
                          _PriorityChip(priority: priority),
                        ],
                      ),
                      if (task.projectId != null)
                        Text(
                          'Project: ${task.projectId}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isCompleted
                                ? theme.hintColor
                                : theme.hintColor,
                          ),
                        )
                      else if (task.goalId != null)
                        Text(
                          'Goal: ${task.goalId}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isCompleted
                                ? theme.hintColor
                                : theme.hintColor,
                          ),
                        ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        backgroundColor: theme.colorScheme.surface,
                        valueColor: AlwaysStoppedAnimation(
                          isCompleted
                              ? theme.hintColor.withOpacity(0.5)
                              : bucket.color,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  dueText,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isCompleted ? theme.hintColor : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(.3),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  isCompleted
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: isCompleted ? bucket.color : theme.hintColor,
                ),
                onPressed: () async {
                  if (isCompleted) {
                    await taskController.reopenTask(task);
                  } else {
                    await taskController.completeTask(task);
                  }
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: isCompleted
                    ? 'Mark as incomplete'
                    : 'Mark as complete',
              ),
              const SizedBox(width: 8),
              Expanded(
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
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isCompleted ? theme.hintColor : null,
                            ),
                          ),
                        ),
                        if (task.isRecurring)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Tooltip(
                              message: 'Recurring task',
                              child: Icon(
                                Icons.autorenew_rounded,
                                size: 16,
                                color: bucket.color,
                              ),
                            ),
                          ),
                        _PriorityChip(priority: priority),
                      ],
                    ),
                    if (task.projectId != null)
                      Text(
                        'Project: ${task.projectId}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isCompleted
                              ? theme.hintColor
                              : theme.hintColor,
                        ),
                      )
                    else if (task.goalId != null)
                      Text(
                        'Goal: ${task.goalId}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isCompleted
                              ? theme.hintColor
                              : theme.hintColor,
                        ),
                      ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor: theme.colorScheme.surface,
                      valueColor: AlwaysStoppedAnimation(
                        isCompleted
                            ? theme.hintColor.withOpacity(0.5)
                            : bucket.color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                dueText,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isCompleted ? theme.hintColor : null,
                ),
              ),
            ],
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(.3),
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isCompleted ? bucket.color : theme.hintColor,
              ),
              onPressed: () async {
                if (isCompleted) {
                  await taskController.reopenTask(task);
                } else {
                  await taskController.completeTask(task);
                }
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: isCompleted ? 'Mark as incomplete' : 'Mark as complete',
            ),
            const SizedBox(width: 8),
            Expanded(
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
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: isCompleted ? theme.hintColor : null,
                          ),
                        ),
                      ),
                      if (task.isRecurring)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Tooltip(
                            message: 'Recurring task',
                            child: Icon(
                              Icons.autorenew_rounded,
                              size: 16,
                              color: bucket.color,
                            ),
                          ),
                        ),
                      _PriorityChip(priority: priority),
                    ],
                  ),
                  if (task.projectId != null)
                    Text(
                      'Project: ${task.projectId}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isCompleted ? theme.hintColor : theme.hintColor,
                      ),
                    )
                  else if (task.goalId != null)
                    Text(
                      'Goal: ${task.goalId}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isCompleted ? theme.hintColor : theme.hintColor,
                      ),
                    ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: theme.colorScheme.surface,
                    valueColor: AlwaysStoppedAnimation(
                      isCompleted
                          ? theme.hintColor.withOpacity(0.5)
                          : bucket.color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              dueText,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isCompleted ? theme.hintColor : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.priority});

  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _chipColor(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
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

  Color _chipColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.low:
        return Colors.blue;
    }
  }
}

class CalendarView extends ConsumerWidget {
  const CalendarView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = firstDay.weekday % 7; // Sun=0

    final tasksAsync = ref.watch(tasksStreamProvider);

    return tasksAsync.when(
      data: (tasks) {
        final tasksByDay = <int, int>{};
        for (final task in tasks) {
          if (task.dueDate != null && sameMonth(task.dueDate!, now)) {
            tasksByDay[task.dueDate!.day] =
                (tasksByDay[task.dueDate!.day] ?? 0) + 1;
          }
        }

        return SectionCard(
          title: DateFormat.yMMMM().format(now),
          subtitle: 'Tap day to view tasks',
          child: Column(
            children: [
              // Weekday headers
              Row(
                children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                    .map(
                      (day) => Expanded(
                        child: Text(
                          day,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
              // Days grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1.2,
                ),
                itemCount: 42, // 6 weeks max
                itemBuilder: (context, index) {
                  final day = index - firstWeekday + 1;
                  if (day < 1 || day > daysInMonth) {
                    return const SizedBox();
                  }
                  final count = tasksByDay[day] ?? 0;
                  final isToday = now.day == day;
                  return GestureDetector(
                    onTap: () {
                      ref
                          .read(timelineFilterProvider.notifier)
                          .setDateRange(
                            DateTimeRange(
                              start: DateTime(now.year, now.month, day),
                              end: DateTime(now.year, now.month, day),
                            ),
                          );
                    },
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isToday
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$day',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          if (count > 0)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                count,
                                (_) => Container(
                                  width: 4,
                                  height: 4,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              TextButton.icon(
                onPressed: () {}, // TODO: Switch month
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                label: const Text('Next month'),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}

bool sameMonth(DateTime date1, DateTime date2) =>
    date1.year == date2.year && date1.month == date2.month;
