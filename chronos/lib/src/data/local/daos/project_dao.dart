import 'package:drift/drift.dart';

import '../app_database.dart';

part 'project_dao.g.dart';

@DriftAccessor(tables: [Projects])
class ProjectDao extends DatabaseAccessor<ChronosDatabase> with _$ProjectDaoMixin {
  ProjectDao(super.db);

  Stream<List<Project>> watchProjects() => select(projects).watch();
  Future<void> upsertProject(ProjectsCompanion project) =>
      into(projects).insertOnConflictUpdate(project);
  Future<int> deleteProject(String id) =>
      (delete(projects)..where((tbl) => tbl.id.equals(id))).go();
}
