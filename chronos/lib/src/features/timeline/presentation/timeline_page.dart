import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../application/providers.dart';
import '../../../data/local/app_database.dart';
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
    final selectedBuckets = ref.watch(timelineBucketFilterProvider);
    return tasksAsync.when(
      data: (tasks) {
        final grouped = groupTasksByBucket(tasks);
        final visibleBuckets = selectedBuckets.isEmpty
            ? TimelineBucket.values
            : TimelineBucket.values.where(selectedBuckets.contains).toList();
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            SectionCard(
              title: 'Bucket Filters',
              subtitle: 'Toggle which horizons appear below',
              trailing: OverflowBar(
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: () => ref.read(timelineBucketFilterProvider.notifier).selectAll(),
                    child: const Text('Select all'),
                  ),
                  TextButton(
                    onPressed: () => ref.read(timelineBucketFilterProvider.notifier).clear(),
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
                        selected: selectedBuckets.contains(bucket),
                        onSelected: (_) => ref.read(timelineBucketFilterProvider.notifier).toggle(bucket),
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
                            .read(timelineBucketFilterProvider.notifier)
                            .toggle(bucket),
                        icon: Icon(
                          selectedBuckets.contains(bucket)
                              ? Icons.filter_alt_off_rounded
                              : Icons.filter_list_rounded,
                        ),
                      ),
                      child: Builder(
                        builder: (_) {
                          final bucketTasks = grouped[bucket] ?? const <Task>[];
                          if (bucketTasks.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('No tasks in this bucket.'),
                            );
                          }
                          return Column(
                            children: bucketTasks
                                .map((task) => _TimelineRow(task: task, bucket: bucket))
                                .toList(),
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
    final dueText = task.dueDate != null ? DateFormat('EEE · h:mm a').format(task.dueDate!) : 'No due date';
    final progress = taskProgress(task);
    final priority = priorityFromInt(task.priority);
    final taskController = ref.read(taskControllerProvider);
    final isCompleted = task.status >= taskStatusCompleted;

    return Container(
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
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
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
                    isCompleted ? theme.hintColor.withOpacity(0.5) : bucket.color,
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
      default:
        return Colors.grey;
    }
  }
}