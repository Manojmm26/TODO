import 'package:chronos/src/shared/recurrence/recurrence_utils.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rrule/rrule.dart';
import 'package:uuid/uuid.dart';

import '../data/local/app_database.dart';
import '../data/repositories/chronos_repositories.dart';

final _uuid = const Uuid();

final recurrenceCoordinatorProvider = Provider<RecurrenceCoordinator>((ref) {
  final tasks = ref.read(taskRepositoryProvider);
  return RecurrenceCoordinator(tasks);
});

class RecurrenceCoordinator {
  RecurrenceCoordinator(this._tasks);

  final TaskRepository _tasks;

Future<void> bootstrap() async {
  try {
    final templates = await _tasks.recurringTemplates();
    for (final template in templates) {
      try {
        await _ensureUpcomingOccurrence(template);
      } catch (e, st) {
        debugPrint('Error ensuring occurrence for ${template.id}: $e\n$st');
      }
    }
  } catch (e, st) {
    debugPrint('Error in recurrence bootstrap: $e\n$st');
    rethrow;
  }
}

Future<void> onTaskCompleted(Task task) async {
  try {
    final templateId = task.parentRecurringId ?? task.id;
    final template = await _tasks.taskById(templateId);
    if (template == null || (template.recurrenceRule?.isEmpty ?? true)) return;
    
    await _createOccurrence(template, after: task.dueDate ?? DateTime.now());
  } catch (e, st) {
    debugPrint('Error handling task completion for ${task.id}: $e\n$st');
    rethrow;
  }
}

  Future<void> _ensureUpcomingOccurrence(Task template) async {
    if (template.recurrenceRule == null || template.recurrenceRule!.isEmpty) return;
    final series = await _tasks.seriesForTemplate(template.id);
    final hasOpenChild = series.any((task) => task.parentRecurringId != null && task.status < 2);
    if (hasOpenChild) return;
    final latestDue = _latestDueDate(series) ?? template.dueDate ?? DateTime.now();
    await _createOccurrence(template, after: latestDue);
  }

  Future<void> _createOccurrence(Task template, {DateTime? after}) async {
      try {
    final ruleString = template.recurrenceRule;
    if (ruleString == null || ruleString.isEmpty) return;

    String normalizedRule = ruleString.trim();
    if (!normalizedRule.startsWith('RRULE:')) {
      normalizedRule = 'RRULE:$normalizedRule';
    }

    final rule = RecurrenceRule.fromString(normalizedRule);
    final templateStart = (template.startDate ?? template.dueDate ?? DateTime.now()).toUtc();
    final pivot = (after ?? DateTime.now()).toUtc();
    final normalizedAfter = pivot.isBefore(templateStart) ? templateStart : pivot;
    final iterator = rule
        .getInstances(start: templateStart, after: normalizedAfter, includeAfter: false)
        .iterator;
    if (!iterator.moveNext()) return;
    final nextUtc = iterator.current;
    final nextDue = nextUtc.toLocal();
    final duration = (template.dueDate != null && template.startDate != null)
        ? template.dueDate!.difference(template.startDate!)
        : Duration.zero;
    final nextStart = duration == Duration.zero ? nextDue : nextDue.subtract(duration);
    final companion = TasksCompanion(
      id: Value(_uuid.v4()),
      projectId: Value(template.projectId),
      goalId: Value(template.goalId),
      parentRecurringId: Value(template.id),
      title: Value(template.title),
      description: Value(template.description),
      status: const Value(0),
      priority: Value(template.priority),
      startDate: Value(nextStart),
      dueDate: Value(nextDue),
      reminderAt: const Value.absent(),
      estimatedMinutes: Value(template.estimatedMinutes),
      actualMinutes: const Value(0),
      isRecurring: const Value(true),
      recurrenceRule: Value(template.recurrenceRule),
      flagImmediate: Value(template.flagImmediate),
      flagToday: Value(template.flagToday),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    );
    await _tasks.upsert(companion);
    } catch (e, st) {
    debugPrint('Error creating occurrence for ${template.id}: $e\n$st');
    rethrow;
  }
  }

  DateTime? _latestDueDate(List<Task> tasks) {
    DateTime? latest;
    for (final task in tasks) {
      final due = task.dueDate;
      if (due == null) continue;
      if (latest == null || due.isAfter(latest)) {
        latest = due;
      }
    }
    return latest;
  }
}
