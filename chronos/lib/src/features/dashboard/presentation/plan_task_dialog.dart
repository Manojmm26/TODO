import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../application/quick_add_controller.dart';
import '../../../shared/recurrence/recurrence_utils.dart';
import '../data/dashboard_models.dart';

class PlanTaskDialog extends ConsumerStatefulWidget {
  const PlanTaskDialog({super.key});

  @override
  ConsumerState<PlanTaskDialog> createState() => _PlanTaskDialogState();
}

class _PlanTaskDialogState extends ConsumerState<PlanTaskDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _goalIdController = TextEditingController();
  final _customRecurrenceController = TextEditingController();
  
  TimelineBucket _bucket = TimelineBucket.today;
  DateTime? _explicitDueDate;
  RecurrencePreset _recurrencePreset = RecurrencePreset.none;
  DateTime? _recurrenceEndDate;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _goalIdController.dispose();
    _customRecurrenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Plan task'),
      content: SizedBox(
        width: 460,
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
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Timeline bucket', style: theme.textTheme.labelLarge),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              children: TimelineBucket.values
                  .map(
                    (bucket) => ChoiceChip(
                      label: Text(bucket.label),
                      avatar: Icon(Icons.circle, size: 12, color: bucket.color),
                      selected: _bucket == bucket,
                      onSelected: (_) => setState(() => _bucket = bucket),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _explicitDueDate != null
                        ? 'Due ${DateFormat.yMMMd().format(_explicitDueDate!)}'
                        : 'Auto due: ${_autoDueLabel(_bucket)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _explicitDueDate ?? _suggestedDueDate(_bucket) ?? now,
                      firstDate: now.subtract(const Duration(days: 1)),
                      lastDate: now.add(const Duration(days: 365)),
                    );
                    if (picked != null) setState(() => _explicitDueDate = picked);
                  },
                  child: const Text('Set due date'),
                ),
                if (_explicitDueDate != null)
                  IconButton(
                    tooltip: 'Clear due date',
                    onPressed: () => setState(() => _explicitDueDate = null),
                    icon: const Icon(Icons.close_rounded),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _goalIdController,
              decoration: const InputDecoration(labelText: 'Goal ID (optional)'),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Recurrence', style: theme.textTheme.labelLarge),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<RecurrencePreset>(
              value: _recurrencePreset,
              decoration: const InputDecoration(labelText: 'Repeats'),
              items: RecurrencePreset.values
                  .map(
                    (preset) => DropdownMenuItem(
                      value: preset,
                      child: Text(preset.label),
                    ),
                  )
                  .toList(),
              onChanged: (preset) {
                if (preset == null) return;
                setState(() {
                  _recurrencePreset = preset;
                  if (preset == RecurrencePreset.none) {
                    _recurrenceEndDate = null;
                  }
                });
              },
            ),
            if (_recurrencePreset == RecurrencePreset.custom) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _customRecurrenceController,
                decoration: const InputDecoration(
                  labelText: 'Custom RRULE',
                  hintText: 'e.g. FREQ=MONTHLY;BYDAY=MO',
                ),
              ),
            ],
            if (_recurrencePreset != RecurrencePreset.none) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _recurrenceEndDate != null
                          ? 'Ends ${DateFormat.yMMMd().format(_recurrenceEndDate!)}'
                          : 'No end date',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _recurrenceEndDate ?? now,
                        firstDate: now,
                        lastDate: now.add(const Duration(days: 730)),
                      );
                      if (picked != null) {
                        setState(() => _recurrenceEndDate = picked);
                      }
                    },
                    child: const Text('Set end'),
                  ),
                  if (_recurrenceEndDate != null)
                    IconButton(
                      tooltip: 'Clear end date',
                      onPressed: () => setState(() => _recurrenceEndDate = null),
                      icon: const Icon(Icons.close_rounded),
                    ),
                ],
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  recurrenceSummary(
                    _recurrencePreset,
                    endDate: _recurrenceEndDate,
                  ),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _isSaving ? null : () => _submit(context),
          icon: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save_rounded),
          label: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _submit(BuildContext context) async {
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title required')));
      return;
    }
final recurrenceRule = buildRecurrenceRule(
  _recurrencePreset,
  endDate: _recurrenceEndDate,
  customRule: _customRecurrenceController.text,
);
final isRecurring = recurrenceRule != null;
if (isRecurring) {
  debugPrint('Recurrence Rule: $recurrenceRule');
  if (!isValidRecurrenceRule(recurrenceRule)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invalid recurrence rule format. Please check your rule syntax.'),
      ),
    );
    return;
  }
}
    setState(() => _isSaving = true);
    final quickAdd = ref.read(quickAddControllerProvider);
    final dueDate = _explicitDueDate ?? _suggestedDueDate(_bucket);
    final flags = _bucketFlags(_bucket);
    try {
      await quickAdd.addTask(
        title: title,
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        goalId: _goalIdController.text.trim().isEmpty ? null : _goalIdController.text.trim(),
        dueDate: dueDate,
        startDate: flags.startDate,
        flagImmediate: flags.flagImmediate,
        flagToday: flags.flagToday,
        priority: flags.priority,
        isRecurring: isRecurring,
        recurrenceRule: recurrenceRule,
      );
      if (context.mounted) Navigator.of(context).pop();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to plan task: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _autoDueLabel(TimelineBucket bucket) {
    final due = _suggestedDueDate(bucket);
    if (due == null) return 'No due date';
    return DateFormat.yMMMd().format(due);
  }

  DateTime? _suggestedDueDate(TimelineBucket bucket) {
    final now = DateTime.now();
    return switch (bucket) {
      TimelineBucket.immediate => now,
      TimelineBucket.today => DateTime(now.year, now.month, now.day, 23, 59),
      TimelineBucket.upcoming => now.add(const Duration(days: 3)),
      TimelineBucket.backlog => null,
    };
  }

  _BucketFlags _bucketFlags(TimelineBucket bucket) {
    final now = DateTime.now();
    return switch (bucket) {
      TimelineBucket.immediate => _BucketFlags(flagImmediate: true, priority: 0, startDate: now),
      TimelineBucket.today => _BucketFlags(flagToday: true, priority: 1, startDate: now),
      TimelineBucket.upcoming => _BucketFlags(priority: 1, startDate: now.add(const Duration(days: 1))),
      TimelineBucket.backlog => const _BucketFlags(priority: 2),
    };
  }
}

class _BucketFlags {
  const _BucketFlags({
    this.flagImmediate = false,
    this.flagToday = false,
    this.priority,
    this.startDate,
  });

  final bool flagImmediate;
  final bool flagToday;
  final int? priority;
  final DateTime? startDate;
}
