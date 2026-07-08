import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/local/app_database.dart';
import '../data/repositories/chronos_repositories.dart';

final _uuid = const Uuid();

final subTaskControllerProvider = Provider<SubTaskController>((ref) {
  final repository = ref.read(subTaskRepositoryProvider);
  return SubTaskController(repository);
});

class SubTaskController {
  SubTaskController(this._repository);

  final SubTaskRepository _repository;

  Stream<List<SubTask>> watchSubTasks() => _repository.watchSubTasks();
  Future<void> toggleCompletion(String id, bool isCompleted) =>
      _repository.toggleCompletion(id, isCompleted);
  Future<void> delete(String id) => _repository.delete(id);
  Future<void> rename(String id, String title) =>
      _repository.updateTitle(id, title);
  Future<void> create({
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
    return _repository.upsert(companion);
  }
}
