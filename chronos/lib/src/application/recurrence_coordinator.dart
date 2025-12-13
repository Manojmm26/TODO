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
          await ensureUpcomingOccurrence(template);
        } catch (e, st) {
          debugPrint('Error ensuring occurrence for ${template.id}: $e\n$st');
        }
      }
    } catch (e, st) {
      debugPrint('🔴 Error in recurrence bootstrap: $e\n$st');
      // Consider rethrowing or exposing via a stream if critical
      rethrow;
    }
  }

  Future<void> onTaskCompleted(Task task) async {
    try {
      final templateId = task.parentRecurringId ?? task.id;
      final template = await _tasks.taskById(templateId);
      if (template == null || (template.recurrenceRule?.isEmpty ?? true)) {
        return;
      }

      // Use completion time (now) instead of task's due date to ensure
      // the next occurrence respects the recurrence interval
      // (e.g., daily = tomorrow, weekly = next week)
      await _createOccurrence(template, after: DateTime.now());
    } catch (e, st) {
      debugPrint('🔴 Error handling task completion for ${task.id}: $e\n$st');
      rethrow;
    }
  }

  Future<void> ensureUpcomingOccurrence(Task template) async {
    debugPrint('Checking recurrence for ${template.title} (${template.id})');
    if (template.recurrenceRule == null || template.recurrenceRule!.isEmpty) {
      debugPrint('No recurrence rule for ${template.title}');
      return;
    }
    final series = await _tasks.seriesForTemplate(template.id);
    debugPrint('Found ${series.length} existing items in series');

    // Check for open tasks that are expired (due before today)
    // and remove them per user request ("if i don't complete it should be removed")
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    bool didExpire = false;

    // Use a secondary list to avoid concurrent modification if we were iterating and deleting
    // but here we just iterate first.
    final openTasks = series
        .where((t) => t.parentRecurringId != null && t.status < 2)
        .toList();

    for (final task in openTasks) {
      if (task.dueDate != null && task.dueDate!.isBefore(todayStart)) {
        await _tasks.delete(task.id);
        didExpire = true;
      } else {
        // We have a valid future/today task, so we don't need to generate a new one.
        debugPrint(
          'Valid future task exists: ${task.title} due ${task.dueDate}',
        );
        return;
      }
    }

    DateTime pivotDate;
    bool includeAfter = false;

    if (didExpire) {
      // If we expired old tasks, we want to catch up to "Today".
      // Using yesterday allows 'next' to be 'Today' (if daily) or next valid occurrence.
      pivotDate = now.subtract(const Duration(days: 1));
      includeAfter = false;
    } else {
      final latestDue = _latestDueDate(series);
      if (latestDue == null) {
        // Brand new template: We want the first instance immediately.
        // Even if start date is today.
        debugPrint('Brand new template detected. Forcing immediate creation.');
        pivotDate = template.startDate ?? template.dueDate ?? now;
        includeAfter = true;
      } else {
        // Standard continuation
        pivotDate = latestDue;
        includeAfter = false;
      }
    }

    await _createOccurrence(
      template,
      after: pivotDate,
      includeAfter: includeAfter,
    );
  }

  Future<void> _createOccurrence(
    Task template, {
    DateTime? after,
    bool includeAfter = false,
  }) async {
    try {
      debugPrint('_createOccurrence: after=$after, includeAfter=$includeAfter');
      final ruleString = template.recurrenceRule;
      if (ruleString == null || ruleString.isEmpty) return;

      String normalizedRule = ruleString.trim();
      if (!normalizedRule.startsWith('RRULE:')) {
        normalizedRule = 'RRULE:$normalizedRule';
      }

      final rule = RecurrenceRule.fromString(normalizedRule);
      final templateStart =
          (template.startDate ?? template.dueDate ?? DateTime.now()).toUtc();

      // If after is null, use now.
      final pivot = (after ?? DateTime.now()).toUtc();

      debugPrint('RRULE calc: start=$templateStart, pivot=$pivot');

      // If pivot is before start, snap to start?
      // rrule handles 'after' correctly relative to 'start'.
      // But if we want to force inclusion of start, we must be careful.
      // If includeAfter is true, we simply pass it to getInstances.

      final normalizedAfter = pivot.isBefore(templateStart)
          ? (includeAfter
                ? templateStart
                : templateStart.subtract(const Duration(seconds: 1)))
          : pivot;

      final iterator = rule
          .getInstances(
            start: templateStart,
            after: normalizedAfter,
            includeAfter: includeAfter,
          )
          .iterator;
      if (!iterator.moveNext()) {
        debugPrint('No next occurrence found by RRULE');
        return;
      }
      final nextUtc = iterator.current;
      final nextDue = nextUtc.toLocal();

      // Check for duplicates before interacting with DB!
      // Exclude values that are the template itself!
      final series = await _tasks.seriesForTemplate(template.id);
      final isDuplicate = series.any((t) {
        if (t.id == template.id)
          return false; // Don't check the template against itself
        // Simple check: Same Due Date to the minute?
        // Let's use isAtSameMomentAs or checking difference < 1 min
        if (t.dueDate == null) return false;
        return t.dueDate!.isAtSameMomentAs(nextDue) ||
            (t.dueDate!.difference(nextDue).abs() < const Duration(minutes: 1));
      });

      if (isDuplicate) {
        debugPrint(
          'Skipping duplicate occurrence for template ${template.id} at $nextDue',
        );
        return;
      }

      debugPrint('Creating occurrence for $nextDue');

      final duration = (template.dueDate != null && template.startDate != null)
          ? template.dueDate!.difference(template.startDate!)
          : Duration.zero;
      final nextStart = duration == Duration.zero
          ? nextDue
          : nextDue.subtract(duration);
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
        isTemplate: const Value(false), // Occurrences are NOT templates
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
