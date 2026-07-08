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

      // Use task's due date instead of completion time to ensure
      // early completions don't generate duplicate occurrences for the same period.
      await _createOccurrence(template, after: task.dueDate ?? DateTime.now());
    } catch (e, st) {
      debugPrint('🔴 Error handling task completion for ${task.id}: $e\n$st');
      rethrow;
    }
  }

  DateTime? _getNextOccurrence(Task template, DateTime pivot) {
    final ruleString = template.recurrenceRule;
    if (ruleString == null || ruleString.isEmpty) return null;

    String normalizedRule = ruleString.trim();
    if (!normalizedRule.startsWith('RRULE:')) {
      normalizedRule = 'RRULE:$normalizedRule';
    }

    try {
      final rule = RecurrenceRule.fromString(normalizedRule);
      final templateStart = (template.startDate ?? template.dueDate ?? DateTime.now()).toUtc();
      final iterator = rule
          .getInstances(
            start: templateStart,
            after: pivot.toUtc(),
            includeAfter: false,
          )
          .iterator;
      if (iterator.moveNext()) {
        return iterator.current.toLocal();
      }
    } catch (e) {
      debugPrint('Error parsing RRULE in _getNextOccurrence: $e');
    }
    return null;
  }

  Future<void> ensureUpcomingOccurrence(Task template) async {
    debugPrint('Checking recurrence for ${template.title} (${template.id})');
    if (template.recurrenceRule == null || template.recurrenceRule!.isEmpty) {
      debugPrint('No recurrence rule for ${template.title}');
      return;
    }
    final series = await _tasks.seriesForTemplate(template.id);
    debugPrint('Found ${series.length} existing items in series');

    final occurrences = series.where((t) => t.id != template.id).toList();

    if (occurrences.isEmpty) {
      // Brand new template: create first occurrence immediately
      debugPrint('Brand new template detected. Forcing immediate creation.');
      final pivot = template.startDate ?? template.dueDate ?? DateTime.now();
      await _createOccurrence(template, after: pivot, includeAfter: true);
      return;
    }

    final now = DateTime.now();
    var latestOccurrence = occurrences.first;
    var latestDue = latestOccurrence.dueDate;
    if (latestDue == null) return;

    // Catch up loop: if the latest occurrence is uncompleted but expired (past its next occurrence date),
    // delete it and generate the next one until we reach the current active period.
    while (latestOccurrence.status < 2) {
      final nextDue = _getNextOccurrence(template, latestOccurrence.dueDate!);
      if (nextDue == null || now.isBefore(nextDue)) {
        // Either there are no future occurrences or the next occurrence is in the future.
        // We keep the current active occurrence.
        break;
      }

      debugPrint('Rolling over expired occurrence ${latestOccurrence.id} due ${latestOccurrence.dueDate}');
      await _tasks.delete(latestOccurrence.id);

      // Create the next occurrence
      await _createOccurrence(template, after: latestOccurrence.dueDate!, includeAfter: false);

      // Reload occurrences to get the newly created one
      final updatedSeries = await _tasks.seriesForTemplate(template.id);
      final updatedOccurrences = updatedSeries.where((t) => t.id != template.id).toList();
      if (updatedOccurrences.isEmpty) return;

      latestOccurrence = updatedOccurrences.first;
      latestDue = latestOccurrence.dueDate;
    }

    // If the latest occurrence is completed, generate the next one (which will be in the future or active now)
    if (latestOccurrence.status >= 2) {
      await _createOccurrence(template, after: latestDue!, includeAfter: false);
    }
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
        if (t.id == template.id) {
          return false; // Don't check the template against itself
        }
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
}
