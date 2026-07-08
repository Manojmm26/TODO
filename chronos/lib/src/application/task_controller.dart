import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/app_database.dart';
import '../data/repositories/chronos_repositories.dart';
import 'recurrence_coordinator.dart';
import '../shared/constants.dart';

final taskControllerProvider = Provider<TaskController>((ref) {
  final tasks = ref.read(taskRepositoryProvider);
  final recurrence = ref.read(recurrenceCoordinatorProvider);
  return TaskController(tasks: tasks, recurrence: recurrence);
});

class TaskController {
  TaskController({
    required TaskRepository tasks,
    required RecurrenceCoordinator recurrence,
  }) : _tasks = tasks,
       _recurrence = recurrence;

  final TaskRepository _tasks;
  final RecurrenceCoordinator _recurrence;

  Future<void> updateTask(String id, TasksCompanion task) {
    return _tasks.update(id, task);
  }

  Future<void> completeTask(Task task) async {
    if (task.status >= taskStatusCompleted) return;
    final companion = TasksCompanion(
      status: const Value(taskStatusCompleted),
      updatedAt: Value(DateTime.now()),
    );
    await _tasks.update(task.id, companion);
    await _recurrence.onTaskCompleted(task);

    // Cleanup old completed occurrences (keep last 50)
    if (task.parentRecurringId != null) {
      await _tasks.cleanupCompletedOccurrences(
        task.parentRecurringId!,
        keepCount: 50,
      );
    }
  }

  Future<void> reopenTask(Task task) async {
    if (task.status == taskStatusActive) return;
    final companion = TasksCompanion(
      status: const Value(taskStatusActive),
      updatedAt: Value(DateTime.now()),
    );
    await _tasks.update(task.id, companion);
  }
}
