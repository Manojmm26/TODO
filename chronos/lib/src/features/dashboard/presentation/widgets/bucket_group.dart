import 'package:chronos/src/core/theme/app_theme.dart';
import 'package:chronos/src/features/dashboard/data/dashboard_models.dart';
import 'package:chronos/src/features/dashboard/presentation/dashboard_metrics.dart';
import 'package:chronos/src/features/dashboard/presentation/plan_task_dialog.dart';
import 'package:chronos/src/shared/widgets/task_tile.dart';
import 'package:flutter/material.dart';

import '../../../../data/local/app_database.dart';

class BucketGroup extends StatefulWidget {
  const BucketGroup({
    super.key,
    required this.bucket,
    required this.tasks,
    required this.subTasksByTask,
  });

  final TimelineBucket bucket;
  final List<Task> tasks;
  final Map<String, List<SubTask>> subTasksByTask;

  @override
  State<BucketGroup> createState() => _BucketGroupState();
}

class _BucketGroupState extends State<BucketGroup> {
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
                      color: Theme.of(
                        context,
                      ).extension<CustomColors>()!.focusAccent!,
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
