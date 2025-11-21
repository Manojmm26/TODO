import 'package:drift/drift.dart';

import '../app_database.dart';

part 'sub_task_dao.g.dart';

@DriftAccessor(tables: [SubTasks])
class SubTaskDao extends DatabaseAccessor<ChronosDatabase> with _$SubTaskDaoMixin {
  SubTaskDao(super.db);

  Stream<List<SubTask>> watchSubTasks() => select(subTasks).watch();

  Future<List<SubTask>> subTasksForTask(String taskId) {
    return (select(subTasks)..where((tbl) => tbl.taskId.equals(taskId))).get();
  }

  Future<void> upsertSubTask(SubTasksCompanion subTask) =>
      into(subTasks).insertOnConflictUpdate(subTask);

  Future<int> deleteSubTask(String id) =>
      (delete(subTasks)..where((tbl) => tbl.id.equals(id))).go();

  Future<void> toggleCompletion(String id, bool isCompleted) {
    return (update(subTasks)..where((tbl) => tbl.id.equals(id))).write(
      SubTasksCompanion(isCompleted: Value(isCompleted)),
    );
  }
}
