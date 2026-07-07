import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'daos/digest_dao.dart';
import 'daos/focus_session_dao.dart';
import 'daos/goal_dao.dart';
import 'daos/project_dao.dart';
import 'daos/sub_task_dao.dart';
import 'daos/tag_dao.dart';
import 'daos/task_dao.dart';

part 'app_database.g.dart';

class Goals extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get targetDate => dateTime().nullable()();
  RealColumn get progressOverride => real().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  IntColumn get colorHex => integer().withDefault(const Constant(0xFF7C4DFF))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get totalSeconds => integer().withDefault(const Constant(0))();
  DateTimeColumn get timerStartedAt => dateTime().nullable()();

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
  TextColumn get parentRecurringId =>
      text().nullable().references(Tasks, #id)();
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
  BoolColumn get isTemplate => boolean().withDefault(const Constant(false))();
  BoolColumn get flagImmediate =>
      boolean().withDefault(const Constant(false))();
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
  RealColumn get weeklyGoalCompletion =>
      real().withDefault(const Constant(0.0))();

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
  daos: [
    GoalDao,
    ProjectDao,
    TaskDao,
    SubTaskDao,
    FocusSessionDao,
    TagDao,
    DigestDao,
  ],
)
class ChronosDatabase extends _$ChronosDatabase {
  ChronosDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(goals, goals.isCompleted);
      }
      if (from < 3) {
        await m.addColumn(tasks, tasks.isTemplate);
      }
      if (from < 4) {
        await m.addColumn(goals, goals.totalSeconds);
        await m.addColumn(goals, goals.timerStartedAt);
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final supportDir = await getApplicationSupportDirectory();
    final dbFile = File(p.join(supportDir.path, 'chronos.sqlite'));
    return NativeDatabase(dbFile, logStatements: kDebugMode);
  });
}

final chronosDatabaseProvider = Provider<ChronosDatabase>((ref) {
  final db = ChronosDatabase();
  ref.onDispose(db.close);
  return db;
});
