import 'package:chronos/src/features/dashboard/data/dashboard_models.dart';
import 'package:chronos/src/features/dashboard/presentation/dashboard_metrics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/providers.dart';
import '../../application/sub_task_controller.dart';
import '../../application/task_controller.dart';
import '../../data/local/app_database.dart';
import '../../shared/constants.dart';

double subTaskCompletionProgress(List<SubTask> subTasks) {
  if (subTasks.isEmpty) return 0.0;
  final completed = subTasks.where((s) => s.isCompleted).length;
  return completed / subTasks.length;
}

class TaskTile extends ConsumerWidget {
  const TaskTile({
    super.key,
    required this.task,
    this.bucket,
    this.showUnlink = false,
    this.onUnlink,
    this.showProgressBar = true,
    this.dueFormat = 'MMM d',
  });

  final Task task;
  final TimelineBucket? bucket;
  final bool showUnlink;
  final VoidCallback? onUnlink;
  final bool showProgressBar;
  final String dueFormat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isCompleted = isTaskCompleted(task);
    final controller = ref.read(taskControllerProvider);
    final subTasksAsync = ref.watch(subTasksStreamProvider);
    if (subTasksAsync.isLoading) {
      return const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (subTasksAsync.hasError) {
      return SizedBox(
        height: 80,
        child: Center(child: Text('Error: ${subTasksAsync.error}')),
      );
    }
    final allSubTasks = subTasksAsync.value!;
    final subTasks = allSubTasks.where((s) => s.taskId == task.id).toList();
    final double progress = isCompleted
        ? 1.0
        : (subTasks.isNotEmpty ? subTaskCompletionProgress(subTasks) : 0.0);
    final dueText = task.dueDate != null
        ? DateFormat(dueFormat).format(task.dueDate!)
        : 'No due date';
    final bucketColor = bucket?.color ?? theme.colorScheme.primary;
    return Container(
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
              Checkbox(
                value: isCompleted,
                onChanged: isCompleted
                    ? null
                    : (_) => controller.completeTask(task),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const SizedBox(width: 8),
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
                    if (task.description?.isNotEmpty == true)
                      Text(
                        task.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (bucket != null)
                _PriorityChip(priority: priorityFromInt(task.priority)),
              const SizedBox(width: 8),
              IconButton(
                tooltip: isCompleted ? 'Completed' : 'Mark complete',
                onPressed: isCompleted
                    ? null
                    : () => controller.completeTask(task),
                icon: Icon(
                  isCompleted
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: isCompleted ? bucketColor : null,
                ),
              ),
              if (showUnlink)
                IconButton(
                  tooltip: 'Unlink from goal',
                  onPressed: onUnlink,
                  icon: const Icon(
                    Icons.link_off,
                    size: 18,
                    color: Colors.orange,
                  ),
                ),
            ],
          ),
          if (task.projectId != null || task.goalId != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                task.projectId != null
                    ? 'Project: ${task.projectId}'
                    : 'Goal: ${task.goalId}',
                style: theme.textTheme.labelMedium,
              ),
            ),
          if (showProgressBar)
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
          if (!isCompleted)
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sub-task title required')));
      return;
    }

    setState(() => _isSaving = true);
    final subTasks = ref.read(subTaskControllerProvider);
    try {
      await subTasks.create(
        taskId: widget.taskId,
        title: title,
        sortOrder: widget.nextOrder,
      );
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
          .map(
            (subTask) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: _SubTaskTile(subTask: subTask),
            ),
          )
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
  late final TextEditingController _controller = TextEditingController(
    text: widget.subTask.title,
  );

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
          onChanged: (value) =>
              controller.toggleCompletion(subTask.id, value ?? false),
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
                decoration: subTask.isCompleted
                    ? TextDecoration.lineThrough
                    : null,
                color: subTask.isCompleted
                    ? theme.colorScheme.onSurfaceVariant
                    : null,
              ),
            ),
          ),
        if (_isEditing)
          IconButton(
            tooltip: 'Save',
            onPressed: _isSaving ? null : () => _save(context),
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
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
          icon: Icon(
            _isEditing ? Icons.close_rounded : Icons.delete_outline_rounded,
            size: 18,
          ),
        ),
      ],
    );
  }

  Future<void> _save(BuildContext context) async {
    final title = _controller.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Title required')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      await ref
          .read(subTaskControllerProvider)
          .rename(widget.subTask.id, title);
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isEditing = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to rename: $error')));
      }
    }
  }
}
