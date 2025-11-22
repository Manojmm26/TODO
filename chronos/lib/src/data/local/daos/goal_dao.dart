import 'package:drift/drift.dart';

import '../app_database.dart';

part 'goal_dao.g.dart';

@DriftAccessor(tables: [Goals])
class GoalDao extends DatabaseAccessor<ChronosDatabase> with _$GoalDaoMixin {
  GoalDao(super.db);

  Stream<List<Goal>> watchGoals() => select(goals).watch();
  Future<List<Goal>> getGoals() => select(goals).get();
  Future<void> upsertGoal(GoalsCompanion goal) =>
      into(goals).insertOnConflictUpdate(goal);
  Future<void> updateGoal(GoalsCompanion goal) =>
      (update(goals)..where((tbl) => tbl.id.equals(goal.id.value))).write(goal);
  Future<int> deleteGoal(String id) =>
      (delete(goals)..where((tbl) => tbl.id.equals(id))).go();
}
