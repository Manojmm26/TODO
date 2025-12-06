import 'package:drift/drift.dart';

import '../app_database.dart';

part 'task_dao.g.dart';

@DriftAccessor(tables: [Tasks])
class TaskDao extends DatabaseAccessor<ChronosDatabase> with _$TaskDaoMixin {
  TaskDao(super.db);

  Stream<List<Task>> watchTasks() => select(tasks).watch();
  Future<List<Task>> tasksDueToday(DateTime start, DateTime end) {
    final query = select(tasks)
      ..where((tbl) => tbl.dueDate.isBetweenValues(start, end));
    return query.get();
  }

  Future<void> upsertTask(TasksCompanion task) =>
      into(tasks).insertOnConflictUpdate(task);
  Future<void> updateTask(String id, TasksCompanion task) {
    assert(!task.id.present, 'Do not include an id when updating a task');
    return (update(
      tasks,
    )..where((tbl) => tbl.id.equals(id))).write(task).then((_) => null);
  }

  Future<int> deleteTask(String id) =>
      (delete(tasks)..where((tbl) => tbl.id.equals(id))).go();

  Future<Task?> taskById(String id) =>
      (select(tasks)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

  Future<List<Task>> recurringSourceTasks() {
    return (select(tasks)..where(
          (tbl) =>
              tbl.isRecurring.equals(true) & tbl.parentRecurringId.isNull(),
        ))
        .get();
  }

  Future<List<Task>> seriesForTemplate(String templateId) =>
      (select(tasks)
            ..where(
              (tbl) =>
                  tbl.id.equals(templateId) |
                  tbl.parentRecurringId.equals(templateId),
            )
            ..orderBy([
              (tbl) => OrderingTerm(
                expression: tbl.dueDate,
                mode: OrderingMode.desc,
              ),
            ]))
          .get();

  /// Watch actionable tasks only (excludes templates)
  Stream<List<Task>> watchActionableTasks() {
    return (select(tasks)
          ..where((tbl) => tbl.isTemplate.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// Watch recurring templates only
  Stream<List<Task>> watchRecurringTemplates() {
    return (select(tasks)
          ..where((tbl) => tbl.isTemplate.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// Delete oldest completed occurrences beyond limit for a template
  Future<void> cleanupCompletedOccurrences(
    String templateId, {
    int keepCount = 50,
  }) async {
    final completed =
        await (select(tasks)
              ..where(
                (t) =>
                    t.parentRecurringId.equals(templateId) &
                    t.status.isBiggerOrEqualValue(2),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
            .get();

    if (completed.length > keepCount) {
      final toDelete = completed.skip(keepCount).map((t) => t.id).toList();
      await (delete(tasks)..where((t) => t.id.isIn(toDelete))).go();
    }
  }
}
