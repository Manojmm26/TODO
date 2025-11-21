import 'package:chronos/src/features/dashboard/data/dashboard_models.dart';
import 'package:chronos/src/features/dashboard/presentation/dashboard_metrics.dart';
import 'package:chronos/src/features/dashboard/presentation/plan_task_dialog.dart';
import 'package:chronos/src/features/dashboard/presentation/widgets/bucket_group.dart';
import 'package:chronos/src/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/local/app_database.dart';

class TimelineOverview extends StatelessWidget {
  const TimelineOverview({
    super.key,
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
                      (bucket) => BucketGroup(
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
