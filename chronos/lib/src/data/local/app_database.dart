import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class Goals extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get targetDate => dateTime().nullable()();
  RealColumn get progressOverride => real().nullable()();
  IntColumn get colorHex => integer().withDefault(const Constant(0xFF7C4DFF))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Projects extends Table {
  TextColumn get id => text()();
  TextColumn get goalId => text().nullable().references(Goals, #id)();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  IntColumn get status => integer().withDefault(const Constant(0))();
  IntColumn get colorHex => integer().withDefault(const Constant(0xFF26C6DA))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().nullable().references(Projects, #id)();
  TextColumn get goalId => text().nullable().references(Goals, #id)();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  IntColumn get status => integer().withDefault(const Constant(0))();
  IntColumn get priority => integer().withDefault(const Constant(1))();
  DateTimeColumn get startDate => dateTime().nullable()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  DateTimeColumn get reminderAt => dateTime().nullable()();
  IntColumn get estimatedMinutes => integer().withDefault(const Constant(0))();
  IntColumn get actualMinutes => integer().withDefault(const Constant(0))();
  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();
  TextColumn get recurrenceRule => text().nullable()();
  BoolColumn get flagImmediate => boolean().withDefault(const Constant(false))();
  BoolColumn get flagToday => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SubTasks extends Table {
  TextColumn get id => text()();
  TextColumn get taskId => text().references(Tasks, #id)();
  TextColumn get title => text()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class FocusSessions extends Table {
  TextColumn get id => text()();
  TextColumn get taskId => text().nullable().references(Tasks, #id)();
  TextColumn get projectId => text().nullable().references(Projects, #id)();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  IntColumn get durationMinutes => integer().withDefault(const Constant(0))();
  TextColumn get ambientPreset => text().nullable()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Tags extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get colorHex => integer().withDefault(const Constant(0xFF9E9E9E))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class TaskTags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get taskId => text().references(Tasks, #id)();
  TextColumn get tagId => text().references(Tags, #id)();
}

class DigestSnapshots extends Table {
  TextColumn get id => text()();
  DateTimeColumn get periodStart => dateTime()();
  TextColumn get periodType => text()();
  IntColumn get completedTasks => integer().withDefault(const Constant(0))();
  IntColumn get focusMinutes => integer().withDefault(const Constant(0))();
  IntColumn get upcomingDeadlines => integer().withDefault(const Constant(0))();
  RealColumn get weeklyGoalCompletion => real().withDefault(const Constant(0.0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    Goals,
    Projects,
    Tasks,
    SubTasks,
    FocusSessions,
    Tags,
    TaskTags,
    DigestSnapshots,
  ],
  daos: [GoalDao, ProjectDao, TaskDao, FocusSessionDao, TagDao, DigestDao],
)
class ChronosDatabase extends _$ChronosDatabase {
  ChronosDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final supportDir = await getApplicationSupportDirectory();
    final dbFile = File(p.join(supportDir.path, 'chronos.sqlite'));
    return NativeDatabase(dbFile, logStatements: kDebugMode);
  });
}

@DriftAccessor(tables: [Goals])
class GoalDao extends DatabaseAccessor<ChronosDatabase> {
  GoalDao(ChronosDatabase db) : super(db);

  $GoalsTable get goals => attachedDatabase.goals;

  Stream<List<Goal>> watchGoals() => select(goals).watch();
  Future<List<Goal>> getGoals() => select(goals).get();
  Future<void> upsertGoal(GoalsCompanion goal) => into(goals).insertOnConflictUpdate(goal);
  Future<int> deleteGoal(String id) => (delete(goals)..where((tbl) => tbl.id.equals(id))).go();
}

@DriftAccessor(tables: [Projects])
class ProjectDao extends DatabaseAccessor<ChronosDatabase> {
  ProjectDao(ChronosDatabase db) : super(db);

  $ProjectsTable get projects => attachedDatabase.projects;

  Stream<List<Project>> watchProjects() => select(projects).watch();
  Future<void> upsertProject(ProjectsCompanion project) => into(projects).insertOnConflictUpdate(project);
  Future<int> deleteProject(String id) => (delete(projects)..where((tbl) => tbl.id.equals(id))).go();
}

@DriftAccessor(tables: [Tasks])
class TaskDao extends DatabaseAccessor<ChronosDatabase> {
  TaskDao(ChronosDatabase db) : super(db);

  $TasksTable get tasks => attachedDatabase.tasks;

  Stream<List<Task>> watchTasks() => select(tasks).watch();
  Future<List<Task>> tasksDueToday(DateTime start, DateTime end) {
    final query = select(tasks)
      ..where((tbl) => tbl.dueDate.isBetweenValues(start, end));
    return query.get();
  }

  Future<void> upsertTask(TasksCompanion task) => into(tasks).insertOnConflictUpdate(task);
  Future<int> deleteTask(String id) => (delete(tasks)..where((tbl) => tbl.id.equals(id))).go();
}

@DriftAccessor(tables: [FocusSessions])
class FocusSessionDao extends DatabaseAccessor<ChronosDatabase> {
  FocusSessionDao(ChronosDatabase db) : super(db);

  $FocusSessionsTable get focusSessions => attachedDatabase.focusSessions;

  Stream<List<FocusSession>> watchSessions() => select(focusSessions).watch();
  Future<void> logSession(FocusSessionsCompanion session) => into(focusSessions).insert(session);
}

@DriftAccessor(tables: [Tags])
class TagDao extends DatabaseAccessor<ChronosDatabase> {
  TagDao(ChronosDatabase db) : super(db);

  $TagsTable get tags => attachedDatabase.tags;

  Stream<List<Tag>> watchTags() => select(tags).watch();
  Future<void> upsertTag(TagsCompanion tag) => into(tags).insertOnConflictUpdate(tag);
}

@DriftAccessor(tables: [DigestSnapshots])
class DigestDao extends DatabaseAccessor<ChronosDatabase> {
  DigestDao(ChronosDatabase db) : super(db);

  $DigestSnapshotsTable get digestSnapshots => attachedDatabase.digestSnapshots;

  Stream<List<DigestSnapshot>> watchSnapshots() => select(digestSnapshots).watch();
  Future<void> upsertSnapshot(DigestSnapshotsCompanion snapshot) =>
      into(digestSnapshots).insertOnConflictUpdate(snapshot);
}

final chronosDatabaseProvider = Provider<ChronosDatabase>((ref) {
  final db = ChronosDatabase();
  ref.onDispose(db.close);
  return db;
});
