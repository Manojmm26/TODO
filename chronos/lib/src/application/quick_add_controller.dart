import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/local/app_database.dart';
import '../data/repositories/chronos_repositories.dart';

final _uuid = const Uuid();

final quickAddControllerProvider = Provider<QuickAddController>((ref) {
  final tasks = ref.read(taskRepositoryProvider);
  final goals = ref.read(goalRepositoryProvider);
  return QuickAddController(tasks: tasks, goals: goals);
});

class QuickAddController {
  QuickAddController({required TaskRepository tasks, required GoalRepository goals})
      : _tasks = tasks,
        _goals = goals;

  final TaskRepository _tasks;
  final GoalRepository _goals;

  Future<void> addTask({
    required String title,
    String? description,
    String? goalId,
    String? projectId,
    DateTime? startDate,
    DateTime? dueDate,
    bool flagImmediate = false,
    bool flagToday = false,
    int? priority,
  }) {
    final companion = TasksCompanion(
      id: Value(_uuid.v4()),
      title: Value(title),
      description: Value(description),
      goalId: Value(goalId),
      projectId: Value(projectId),
      startDate: startDate != null ? Value(startDate) : const Value.absent(),
      dueDate: dueDate != null ? Value(dueDate) : const Value.absent(),
      flagImmediate: Value(flagImmediate),
      flagToday: Value(flagToday),
      priority: priority != null ? Value(priority) : const Value.absent(),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    );
    return _tasks.upsert(companion);
  }

  Future<void> addGoal({required String title, String? description, DateTime? targetDate}) {
    final companion = GoalsCompanion(
      id: Value(_uuid.v4()),
      title: Value(title),
      description: Value(description),
      targetDate: Value(targetDate),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    );
    return _goals.upsert(companion);
  }
}
