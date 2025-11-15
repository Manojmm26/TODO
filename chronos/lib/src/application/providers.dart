import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/app_database.dart';
import '../data/repositories/chronos_repositories.dart';

final goalsStreamProvider = StreamProvider.autoDispose<List<Goal>>((ref) {
  final repository = ref.watch(goalRepositoryProvider);
  return repository.watchGoals();
});

final projectsStreamProvider = StreamProvider.autoDispose<List<Project>>((ref) {
  final repository = ref.watch(projectRepositoryProvider);
  return repository.watchProjects();
});

final tasksStreamProvider = StreamProvider.autoDispose<List<Task>>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.watchTasks();
});

final tasksDueTodayProvider = FutureProvider.autoDispose<List<Task>>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  final end = start.add(const Duration(days: 1));
  return repository.tasksDueToday(start, end);
});

final focusSessionsStreamProvider = StreamProvider.autoDispose<List<FocusSession>>((ref) {
  final repository = ref.watch(focusRepositoryProvider);
  return repository.watchSessions();
});

final tagsStreamProvider = StreamProvider.autoDispose<List<Tag>>((ref) {
  final repository = ref.watch(tagRepositoryProvider);
  return repository.watchTags();
});

final digestSnapshotsProvider = StreamProvider.autoDispose<List<DigestSnapshot>>((ref) {
  final repository = ref.watch(digestRepositoryProvider);
  return repository.watchSnapshots();
});
