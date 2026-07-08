import 'package:drift/drift.dart';

import '../app_database.dart';

part 'focus_session_dao.g.dart';

@DriftAccessor(tables: [FocusSessions])
class FocusSessionDao extends DatabaseAccessor<ChronosDatabase> with _$FocusSessionDaoMixin {
  FocusSessionDao(super.db);

  Stream<List<FocusSession>> watchSessions() => select(focusSessions).watch();
  Future<void> logSession(FocusSessionsCompanion session) =>
      into(focusSessions).insert(session);
  Future<FocusSession?> activeSession() {
    final query = select(focusSessions)
      ..where((tbl) => tbl.endedAt.isNull())
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.startedAt)])
      ..limit(1);
    return query.getSingleOrNull();
  }

  Future<void> closeSession(String id, DateTime endedAt) async {
    final session = await (select(focusSessions)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    if (session == null) return;

    final elapsedSeconds = endedAt.difference(session.startedAt).inSeconds;
    // Calculate minutes spent, ensuring at least 1 minute if elapsedSeconds > 0
    final elapsedMinutes = elapsedSeconds > 0 ? (elapsedSeconds / 60.0).ceil() : 0;

    await (update(focusSessions)..where((tbl) => tbl.id.equals(id))).write(
      FocusSessionsCompanion(
        endedAt: Value(endedAt),
        durationMinutes: Value(elapsedMinutes),
      ),
    );

    if (session.taskId != null) {
      final task = await db.taskDao.taskById(session.taskId!);
      if (task != null) {
        final currentActual = task.actualMinutes;
        await db.taskDao.updateTask(
          session.taskId!,
          TasksCompanion(
            actualMinutes: Value(currentActual + elapsedMinutes),
          ),
        );

        if (task.goalId != null) {
          final goalQuery = db.select(db.goals)..where((tbl) => tbl.id.equals(task.goalId!));
          final goal = await goalQuery.getSingleOrNull();
          if (goal != null) {
            await db.goalDao.updateGoal(
              GoalsCompanion(
                id: Value(goal.id),
                totalSeconds: Value(goal.totalSeconds + elapsedSeconds),
              ),
            );
          }
        }
      }
    }
  }
}
