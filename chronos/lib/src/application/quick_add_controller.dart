import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/local/app_database.dart';
import '../data/repositories/chronos_repositories.dart';

final _uuid = const Uuid();

final quickAddControllerProvider = Provider<QuickAddController>((ref) {
  final tasks = ref.read(taskRepositoryProvider);
  final goals = ref.read(goalRepositoryProvider);
  final subTasks = ref.read(subTaskRepositoryProvider);
  return QuickAddController(tasks: tasks, goals: goals, subTasks: subTasks);
});

class QuickAddController {
  QuickAddController({
    required TaskRepository tasks,
    required GoalRepository goals,
    required SubTaskRepository subTasks,
  }) : _tasks = tasks,
       _goals = goals,
       _subTasks = subTasks;

  final TaskRepository _tasks;
  final GoalRepository _goals;
  final SubTaskRepository _subTasks;

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
    bool isRecurring = false,
    String? recurrenceRule,
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
      isRecurring: Value(isRecurring),
      isTemplate: Value(isRecurring), // Mark as template if recurring
      recurrenceRule: recurrenceRule != null
          ? Value(recurrenceRule)
          : const Value.absent(),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    );
    return _tasks.upsert(companion);
  }

  Future<void> addGoal({
    required String title,
    String? description,
    DateTime? targetDate,
  }) {
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

  Future<void> addSubTask({
    required String taskId,
    required String title,
    int? sortOrder,
  }) {
    final companion = SubTasksCompanion(
      id: Value(_uuid.v4()),
      taskId: Value(taskId),
      title: Value(title),
      sortOrder: sortOrder != null ? Value(sortOrder) : const Value.absent(),
      isCompleted: const Value(false),
    );
    return _subTasks.upsert(companion);
  }

  Future<void> linkTaskToGoal(String taskId, String goalId) {
    final companion = TasksCompanion(
      goalId: Value(goalId),
      updatedAt: Value(DateTime.now()),
    );
    return _tasks.update(taskId, companion);
  }

  Future<void> unlinkTaskFromGoal(String taskId) {
    final companion = TasksCompanion(
      goalId: const Value(null),
      updatedAt: Value(DateTime.now()),
    );
    return _tasks.update(taskId, companion);
  }

  Future<void> toggleGoalCompletion(String goalId, bool isCompleted) {
    final companion = GoalsCompanion(
      isCompleted: Value(isCompleted),
      updatedAt: Value(DateTime.now()),
      id: Value(goalId),
    );
    return _goals.update(companion);
  }
}
