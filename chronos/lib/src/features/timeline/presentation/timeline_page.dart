import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../application/providers.dart';
import '../../../data/local/app_database.dart';
import '../../../shared/widgets/section_card.dart';
import '../../dashboard/data/dashboard_models.dart';
import '../../dashboard/presentation/dashboard_metrics.dart';
import '../application/timeline_filter_controller.dart';

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

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.task, required this.bucket});

  final Task task;
  final TimelineBucket bucket;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dueText = task.dueDate != null ? DateFormat('EEE · h:mm a').format(task.dueDate!) : 'No due date';
    final progress = taskProgress(task);
    final priority = priorityFromInt(task.priority);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(.3),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: bucket.color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (task.projectId != null)
                  Text(
                    'Project: ${task.projectId}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  )
                else if (task.goalId != null)
                  Text(
                    'Goal: ${task.goalId}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: theme.colorScheme.surface,
                  valueColor: AlwaysStoppedAnimation(bucket.color),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(dueText, style: theme.textTheme.labelSmall),
              Text(
                priority.label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
