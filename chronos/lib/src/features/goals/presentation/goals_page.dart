import 'package:chronos/src/features/dashboard/presentation/dashboard_metrics.dart';
import 'package:chronos/src/shared/widgets/task_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../application/providers.dart';
import '../../../application/quick_add_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/local/app_database.dart';
import '../../../shared/constants.dart';
import '../../../shared/widgets/section_card.dart';
import '../../dashboard/presentation/plan_task_dialog.dart';

class GoalsPage extends ConsumerWidget {
  const GoalsPage({super.key});

  Future<void> _showNewGoalDialog(BuildContext context) {
    return showDialog(context: context, builder: (_) => const _NewGoalDialog());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsStreamProvider);
    final tasksAsync = ref.watch(tasksStreamProvider);
    final cachedGoals = goalsAsync.maybeWhen(
      data: (goals) => goals,
      orElse: () => const <Goal>[],
    );
    final cachedTasks = tasksAsync.maybeWhen(
      data: (tasks) => tasks,
      orElse: () => const <Task>[],
    );
    final tasksByGoal = _tasksGroupedByGoal(cachedTasks);
    final goalLookup = {for (final goal in cachedGoals) goal.id: goal};
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        SectionCard(
          title: 'Active Goals',
          subtitle: 'Track milestones & completion',
          trailing: FilledButton.icon(
            onPressed: () => _showNewGoalDialog(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('New Goal'),
          ),
          child: goalsAsync.when(
            data: (goals) {
              if (goals.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No goals yet — create one to start tracking progress.',
                  ),
                );
              }
              return Column(
                children: goals
                    .map(
                      (goal) => _GoalProgressTile(
                        goal: goal,
                        linkedTasks: tasksByGoal[goal.id] ?? const <Task>[],
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Unable to load goals: $error'),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SectionCard(
          title: 'Weekly Milestones',
          subtitle: 'Highlight task checkpoints linked to goals',
          child: tasksAsync.when(
            data: (tasks) {
              final milestoneTasks = tasks
                  .where((task) => task.goalId != null)
                  .take(4)
                  .toList();
              if (milestoneTasks.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No goal-linked tasks yet. Create tasks and associate them with goals.',
                  ),
                );
              }
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: milestoneTasks.map((task) {
                  final goal = task.goalId != null
                      ? goalLookup[task.goalId!]
                      : null;
                  final siblings = task.goalId != null
                      ? tasksByGoal[task.goalId!] ?? const <Task>[]
                      : const <Task>[];
                  final completedSiblings = siblings
                      .where(isTaskCompleted)
                      .length;
                  return _MilestoneCard(
                    label: task.title,
                    description: task.description ?? 'No description provided',
                    due: task.dueDate,
                    progress: taskProgress(task),
                    goalTitle: goal?.title,
                    goalDue: goal?.targetDate,
                    linkedTaskCount: siblings.length,
                    completedLinkedTasks: completedSiblings,
                  );
                }).toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Unable to load milestones: $error'),
            ),
          ),
        ),
      ],
    );
  }
}

bool isTaskCompleted(Task task) => task.status >= taskStatusCompleted;

class _GoalProgressTile extends ConsumerWidget {
  const _GoalProgressTile({required this.goal, required this.linkedTasks});

  final Goal goal;
  final List<Task> linkedTasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = Color(goal.colorHex);
    final progress = goal.isCompleted
        ? 1.0
        : linkedTasks.isNotEmpty
        ? linkedTasks.where(isTaskCompleted).length / linkedTasks.length
        : ((goal.progressOverride ?? 0.0).clamp(0.0, 1.0)).toDouble();
    final totalLinked = linkedTasks.length;
    final completedLinked = linkedTasks.where(isTaskCompleted).length;
    final activeLinked = totalLinked - completedLinked;
    final dueDate = goal.targetDate;
    final now = DateTime.now();
    final isOverdue = dueDate != null && dueDate.isBefore(now);
    final isDueSoon =
        dueDate != null && !isOverdue && dueDate.difference(now).inDays <= 7;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [color.withValues(alpha: .15), color.withValues(alpha: .05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      dueDate != null
                          ? 'Due ${DateFormat.MMMd().format(dueDate)}'
                          : 'No deadline',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isOverdue
                            ? theme.colorScheme.error
                            : isDueSoon
                            ? theme.colorScheme.secondary
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: goal.isCompleted ? theme.colorScheme.primary : null,
                ),
              ),
              const SizedBox(width: 16),
              Transform.scale(
                scale: 1.2,
                child: Checkbox(
                  value: goal.isCompleted,
                  onChanged: (value) {
                    if (value == null) return;
                    ref
                        .read(quickAddControllerProvider)
                        .toggleGoalCompletion(goal.id, value);
                  },
                  shape: const CircleBorder(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: .4),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaPill(
                icon: Icons.check_circle_outline,
                label: totalLinked == 0
                    ? 'No linked tasks yet'
                    : '$completedLinked of $totalLinked tasks complete',
              ),
              if (activeLinked > 0)
                _MetaPill(
                  icon: Icons.pending_actions_rounded,
                  label:
                      '$activeLinked active ${(activeLinked == 1) ? 'task' : 'tasks'}',
                ),
              if (goal.description?.isNotEmpty == true)
                _MetaPill(icon: Icons.notes_rounded, label: goal.description!),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => PlanTaskDialog(initialGoalId: goal.id),
            ),
            icon: const Icon(Icons.add_task_rounded),
            label: Text(
              linkedTasks.isEmpty
                  ? 'Add first milestone task'
                  : 'Add milestone task',
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => _LinkExistingTaskDialog(goalId: goal.id),
            ),
            icon: const Icon(Icons.link_rounded),
            label: Text(
              linkedTasks.isEmpty
                  ? 'Link first existing task'
                  : 'Link existing task',
            ),
          ),
          if (linkedTasks.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 24),
            ...linkedTasks.map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: TaskTile(
                  task: task,
                  showUnlink: true,
                  onUnlink: () => ref
                      .read(quickAddControllerProvider)
                      .unlinkTaskFromGoal(task.id),
                  showProgressBar: false,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({
    required this.label,
    required this.description,
    required this.due,
    required this.progress,
    this.goalTitle,
    this.goalDue,
    this.linkedTaskCount = 0,
    this.completedLinkedTasks = 0,
  });

  final String label;
  final String description;
  final DateTime? due;
  final double progress;
  final String? goalTitle;
  final DateTime? goalDue;
  final int linkedTaskCount;
  final int completedLinkedTasks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final goalDeadlineBadge = goalDue != null
        ? DateFormat.MMMd().format(goalDue!)
        : null;
    final goalDeadlineOverdue =
        goalDue != null && goalDue!.isBefore(DateTime.now());
    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .35),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(description, style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surface,
              valueColor: AlwaysStoppedAnimation(
                Theme.of(context).extension<CustomColors>()!.focusAccent!,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (goalTitle != null)
                _MetaPill(icon: Icons.flag_rounded, label: goalTitle!),
              if (linkedTaskCount > 0)
                _MetaPill(
                  icon: Icons.checklist_rtl_rounded,
                  label: '$completedLinkedTasks/$linkedTaskCount subtasks',
                ),
              if (goalDeadlineBadge != null)
                _MetaPill(
                  icon: Icons.av_timer_rounded,
                  label: 'Goal due $goalDeadlineBadge',
                  color: goalDeadlineOverdue ? theme.colorScheme.error : null,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 16),
              const SizedBox(width: 6),
              Text(
                due != null ? DateFormat.MMMd().format(due!) : 'No due date',
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = color ?? theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: tint.withValues(alpha: .08),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: tint),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(color: tint),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewGoalDialog extends ConsumerStatefulWidget {
  const _NewGoalDialog();

  @override
  ConsumerState<_NewGoalDialog> createState() => _NewGoalDialogState();
}

class _NewGoalDialogState extends ConsumerState<_NewGoalDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _targetDate;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Create goal'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _targetDate != null
                        ? DateFormat.yMMMd().format(_targetDate!)
                        : 'No target date',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _targetDate ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 1),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 730)),
                    );
                    if (picked != null) setState(() => _targetDate = picked);
                  },
                  child: const Text('Pick date'),
                ),
                if (_targetDate != null)
                  IconButton(
                    tooltip: 'Clear date',
                    onPressed: () => setState(() => _targetDate = null),
                    icon: const Icon(Icons.close_rounded),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : () => _submit(context),
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _submit(BuildContext context) async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Title required')));
      return;
    }
    setState(() => _isSaving = true);
    final quickAdd = ref.read(quickAddControllerProvider);
    try {
      await quickAdd.addGoal(
        title: title,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        targetDate: _targetDate,
      );
      if (context.mounted) Navigator.of(context).pop();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save goal: $error')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _LinkExistingTaskDialog extends ConsumerStatefulWidget {
  const _LinkExistingTaskDialog({required this.goalId});

  final String goalId;

  @override
  ConsumerState<_LinkExistingTaskDialog> createState() =>
      _LinkExistingTaskDialogState();
}

class _LinkExistingTaskDialogState
    extends ConsumerState<_LinkExistingTaskDialog> {
  final Set<String> _selectedTaskIds = {};

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksStreamProvider);
    return AlertDialog(
      title: const Text('Link existing tasks'),
      content: SizedBox(
        width: 500,
        height: 400,
        child: tasksAsync.when(
          data: (tasks) {
            final unlinked = tasks
                .where((t) => t.goalId == null && !isTaskCompleted(t))
                .toList();
            if (unlinked.isEmpty) {
              return const Center(child: Text('No unlinked tasks available'));
            }
            return ListView.builder(
              itemCount: unlinked.length,
              itemBuilder: (context, index) {
                final task = unlinked[index];
                final isSelected = _selectedTaskIds.contains(task.id);
                return CheckboxListTile(
                  title: Text(task.title),
                  subtitle: Text(task.description ?? ''),
                  value: isSelected,
                  onChanged: (_) {
                    setState(() {
                      if (isSelected) {
                        _selectedTaskIds.remove(task.id);
                      } else {
                        _selectedTaskIds.add(task.id);
                      }
                    });
                  },
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('Error loading tasks')),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _selectedTaskIds.isEmpty
              ? null
              : () async {
                  for (final taskId in _selectedTaskIds) {
                    await ref
                        .read(quickAddControllerProvider)
                        .linkTaskToGoal(taskId, widget.goalId);
                  }
                  if (!mounted) return;
                  Navigator.of(context).pop();
                },
          icon: const Icon(Icons.link),
          label: Text(
            'Link ${_selectedTaskIds.length} task${_selectedTaskIds.length != 1 ? 's' : ''}',
          ),
        ),
      ],
    );
  }
}

Map<String, List<Task>> _tasksGroupedByGoal(List<Task> tasks) {
  final map = <String, List<Task>>{};
  for (final task in tasks) {
    final goalId = task.goalId;
    if (goalId == null) continue;
    map.putIfAbsent(goalId, () => <Task>[]).add(task);
  }
  return map;
}
