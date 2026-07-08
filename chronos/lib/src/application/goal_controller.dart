import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/app_database.dart';
import '../data/repositories/chronos_repositories.dart';

final goalControllerProvider = Provider<GoalController>((ref) {
  final goals = ref.read(goalRepositoryProvider);
  return GoalController(goals: goals);
});

class GoalController {
  GoalController({
    required GoalRepository goals,
  }) : _goals = goals;

  final GoalRepository _goals;

  Future<void> stopGoalTimer(String goalId) async {
    final allGoals = await _goals.fetchGoals();
    final goal = allGoals.firstWhere((g) => g.id == goalId);

    if (goal.timerStartedAt == null) return;

    final now = DateTime.now();
    final sessionDuration = now.difference(goal.timerStartedAt!).inSeconds;

    final companion = GoalsCompanion(
      id: Value(goalId),
      totalSeconds: Value(goal.totalSeconds + sessionDuration),
      timerStartedAt: const Value(null),
      updatedAt: Value(now),
    );
    await _goals.update(companion);
  }

  Future<void> startGoalTimer(String goalId) {
    final companion = GoalsCompanion(
      id: Value(goalId),
      timerStartedAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    );
    return _goals.update(companion);
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
