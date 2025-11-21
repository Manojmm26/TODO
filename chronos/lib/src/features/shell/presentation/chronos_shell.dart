import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../application/quick_add_controller.dart';
import '../../../core/constants/app_sections.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/recurrence/recurrence_utils.dart';

class ChronosShell extends ConsumerStatefulWidget {
  const ChronosShell({super.key, required this.state, required this.child});

  final GoRouterState state;
  final Widget child;

  @override
  ConsumerState<ChronosShell> createState() => _ChronosShellState();
}

class _ChronosShellState extends ConsumerState<ChronosShell> {
  bool _isCollapsed = true;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedIndex = chronosSections.indexWhere(
      (section) => widget.state.matchedLocation == section.route,
    );

    final content = Row(
      children: [
        const SizedBox(width: 80), // Space for collapsed sidebar
        const VerticalDivider(width: 1),
        Expanded(
          child: Column(
            children: [
              _TopBar(colorScheme: colorScheme),
              const Divider(height: 1),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: widget.child,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            content,
            if (!_isCollapsed)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isCollapsed = true;
                  });
                },
                child: Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  margin: const EdgeInsets.only(left: 230), // expanded width
                ),
              ),
            _SidebarNavigation(
              key: ValueKey<bool>(_isCollapsed),
              isCollapsed: _isCollapsed,
              onToggle: () => setState(() => _isCollapsed = !_isCollapsed),
              selected: selectedIndex >= 0 ? selectedIndex : 0,
              onSelect: (index) {
                context.go(chronosSections[index].route);
                if (!_isCollapsed) {
                  setState(() {
                    _isCollapsed = true;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarNavigation extends StatelessWidget {
  const _SidebarNavigation({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.isCollapsed,
    required this.onToggle,
  });

  final int selected;
  final ValueChanged<int> onSelect;
  final bool isCollapsed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: isCollapsed ? 80 : 230,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      color: brightness == Brightness.dark
          ? const Color(0xFF0C0F17)
          : const Color(0xFFFBFBFE),
      child: Column(
        crossAxisAlignment: isCollapsed
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          if (!isCollapsed)
            Text(
              'Chronos',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: ChronosTheme.focusAccent,
              ),
            ),
          if (isCollapsed)
            Icon(Icons.watch_later, color: ChronosTheme.focusAccent),
          const SizedBox(height: 24),
          ...List.generate(chronosSections.length, (index) {
            final section = chronosSections[index];
            final isSelected = index == selected;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _NavTile(
                section: section,
                isSelected: isSelected,
                isCollapsed: isCollapsed,
                onTap: () => onSelect(index),
              ),
            );
          }),
          const Spacer(),
          if (!isCollapsed) ...[
            Text('Focus Sessions', style: theme.textTheme.labelSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: 0.4,
                    minHeight: 6,
                    backgroundColor: theme.dividerColor.withValues(alpha: 0.3),
                    valueColor: AlwaysStoppedAnimation(
                      ChronosTheme.focusAccent,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('2/5', style: theme.textTheme.labelSmall),
              ],
            ),
          ],
          const SizedBox(height: 24),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onToggle,
            icon: Icon(
              isCollapsed
                  ? Icons.arrow_forward_ios_rounded
                  : Icons.arrow_back_ios_rounded,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.section,
    required this.isSelected,
    required this.onTap,
    required this.isCollapsed,
  });

  final ChronosSection section;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isCollapsed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: 12,
          horizontal: isCollapsed ? 8 : 14,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isSelected
              ? ChronosTheme.focusAccent.withValues(alpha: .15)
              : Colors.transparent,
        ),
        child: isCollapsed
            ? Center(
                child: Icon(
                  section.icon,
                  color: isSelected
                      ? ChronosTheme.focusAccent
                      : colorScheme.onSurfaceVariant,
                ),
              )
            : Row(
                children: [
                  Icon(
                    section.icon,
                    color: isSelected
                        ? ChronosTheme.focusAccent
                        : colorScheme.onSurfaceVariant,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            section.label,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? ChronosTheme.focusAccent
                                  : colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          Text(
                            section.description,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      color: theme.scaffoldBackgroundColor,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Quick search across goals, projects, tasks...',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          FilledButton.icon(
            onPressed: () => _showQuickAddDialog(context, ref),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Quick Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showQuickAddDialog(BuildContext context, WidgetRef ref) {
    return showDialog(
      context: context,
      builder: (_) => const _QuickAddDialog(),
    );
  }
}

class _QuickAddDialog extends ConsumerStatefulWidget {
  const _QuickAddDialog();

  @override
  ConsumerState<_QuickAddDialog> createState() => _QuickAddDialogState();
}

enum _QuickAddType { task, goal }

class _QuickAddDialogState extends ConsumerState<_QuickAddDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _goalIdController = TextEditingController();
  final _customRecurrenceController = TextEditingController();
  DateTime? _targetDate;
  DateTime? _recurrenceEndDate;
  RecurrencePreset _recurrencePreset = RecurrencePreset.none;
  _QuickAddType _type = _QuickAddType.task;
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
      title: const Text('Quick Add'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<_QuickAddType>(
              segments: const [
                ButtonSegment(value: _QuickAddType.task, label: Text('Task')),
                ButtonSegment(value: _QuickAddType.goal, label: Text('Goal')),
              ],
              selected: {_type},
              onSelectionChanged: (selection) =>
                  setState(() => _type = selection.first),
            ),
            const SizedBox(height: 16),
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
            if (_type == _QuickAddType.task) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _goalIdController,
                decoration: const InputDecoration(
                  labelText: 'Goal ID (optional)',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<RecurrencePreset>(
                initialValue: _recurrencePreset,
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
                    hintText: 'e.g. FREQ=WEEKLY;BYDAY=MO',
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
                        onPressed: () =>
                            setState(() => _recurrenceEndDate = null),
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
            ] else ...[
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
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 1),
                        ),
                        lastDate: DateTime.now().add(const Duration(days: 730)),
                      );
                      if (picked != null) setState(() => _targetDate = picked);
                    },
                    child: const Text('Pick date'),
                  ),
                ],
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
      if (_type == _QuickAddType.task) {
        final recurrenceRule = buildRecurrenceRule(
          _recurrencePreset,
          endDate: _recurrenceEndDate,
          customRule: _customRecurrenceController.text,
        );
        await quickAdd.addTask(
          title: title,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          goalId: _goalIdController.text.trim().isEmpty
              ? null
              : _goalIdController.text.trim(),
          isRecurring: recurrenceRule != null,
          recurrenceRule: recurrenceRule,
        );
      } else {
        await quickAdd.addGoal(
          title: title,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          targetDate: _targetDate,
        );
      }
      if (context.mounted) Navigator.of(context).pop();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $error')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
