import 'package:chronos/src/data/local/app_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GoalRepository {
  GoalRepository(this._dao);
  final GoalDao _dao;

  Stream<List<Goal>> watchGoals() => _dao.watchGoals();
  Future<List<Goal>> fetchGoals() => _dao.getGoals();
  Future<void> upsert(GoalsCompanion goal) => _dao.upsertGoal(goal);
  Future<void> delete(String id) => _dao.deleteGoal(id).then((_) => null);
}

class ProjectRepository {
  ProjectRepository(this._dao);
  final ProjectDao _dao;

  Stream<List<Project>> watchProjects() => _dao.watchProjects();
  Future<void> upsert(ProjectsCompanion project) => _dao.upsertProject(project);
  Future<void> delete(String id) => _dao.deleteProject(id).then((_) => null);
}

class TaskRepository {
  TaskRepository(this._dao);
  final TaskDao _dao;

  Stream<List<Task>> watchTasks() => _dao.watchTasks();
  Future<List<Task>> tasksDueToday(DateTime start, DateTime end) =>
      _dao.tasksDueToday(start, end);
  Future<void> upsert(TasksCompanion task) => _dao.upsertTask(task);
  Future<void> update(String id, TasksCompanion task) =>
      _dao.updateTask(id, task);
  Future<void> delete(String id) => _dao.deleteTask(id).then((_) => null);
  Future<List<Task>> recurringTemplates() => _dao.recurringSourceTasks();
  Future<List<Task>> seriesForTemplate(String templateId) =>
      _dao.seriesForTemplate(templateId);
  Future<Task?> taskById(String id) => _dao.taskById(id);
}

class SubTaskRepository {
  SubTaskRepository(this._dao);
  final SubTaskDao _dao;

  Stream<List<SubTask>> watchSubTasks() => _dao.watchSubTasks();
  Future<List<SubTask>> forTask(String taskId) => _dao.subTasksForTask(taskId);
  Future<void> upsert(SubTasksCompanion subTask) => _dao.upsertSubTask(subTask);
  Future<void> delete(String id) => _dao.deleteSubTask(id).then((_) => null);
  Future<void> toggleCompletion(String id, bool isCompleted) =>
      _dao.toggleCompletion(id, isCompleted);
}

class FocusSessionRepository {
  FocusSessionRepository(this._dao);
  final FocusSessionDao _dao;

  Stream<List<FocusSession>> watchSessions() => _dao.watchSessions();
  Future<void> logSession(FocusSessionsCompanion session) =>
      _dao.logSession(session);
  Future<FocusSession?> activeSession() => _dao.activeSession();
  Future<void> closeSession(String id, DateTime endedAt) =>
      _dao.closeSession(id, endedAt);
}

class TagRepository {
  TagRepository(this._dao);
  final TagDao _dao;

  Stream<List<Tag>> watchTags() => _dao.watchTags();
  Future<void> upsert(TagsCompanion tag) => _dao.upsertTag(tag);
}

class DigestRepository {
  DigestRepository(this._dao);
  final DigestDao _dao;

  Stream<List<DigestSnapshot>> watchSnapshots() => _dao.watchSnapshots();
  Future<void> upsert(DigestSnapshotsCompanion snapshot) =>
      _dao.upsertSnapshot(snapshot);
}

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  final db = ref.watch(chronosDatabaseProvider);
  return GoalRepository(GoalDao(db));
});

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  final db = ref.watch(chronosDatabaseProvider);
  return ProjectRepository(ProjectDao(db));
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final db = ref.watch(chronosDatabaseProvider);
  return TaskRepository(TaskDao(db));
});

final subTaskRepositoryProvider = Provider<SubTaskRepository>((ref) {
  final db = ref.watch(chronosDatabaseProvider);
  return SubTaskRepository(SubTaskDao(db));
});

final focusRepositoryProvider = Provider<FocusSessionRepository>((ref) {
  final db = ref.watch(chronosDatabaseProvider);
  return FocusSessionRepository(FocusSessionDao(db));
});

final tagRepositoryProvider = Provider<TagRepository>((ref) {
  final db = ref.watch(chronosDatabaseProvider);
  return TagRepository(TagDao(db));
});

final digestRepositoryProvider = Provider<DigestRepository>((ref) {
  final db = ref.watch(chronosDatabaseProvider);
  return DigestRepository(DigestDao(db));
});
