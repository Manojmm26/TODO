import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/local/app_database.dart';
import '../data/repositories/chronos_repositories.dart';

final _uuid = const Uuid();

final focusSessionControllerProvider =
    AsyncNotifierProvider<FocusSessionController, FocusSession?>(
      FocusSessionController.new,
    );

class FocusSessionController extends AsyncNotifier<FocusSession?> {
  @override
  Future<FocusSession?> build() async {
    final repository = ref.watch(focusRepositoryProvider);
    return repository.activeSession();
  }

  Future<void> startSession({
    String? taskId,
    String? projectId,
    int targetMinutes = 30,
    String? notes,
  }) async {
    final current = state.value;
    if (current != null) return; // Prevent double start

    final repository = ref.read(focusRepositoryProvider);
    final session = FocusSessionsCompanion(
      id: Value(_uuid.v4()),
      taskId: Value(taskId),
      projectId: Value(projectId),
      startedAt: Value(DateTime.now()),
      durationMinutes: Value(targetMinutes),
      notes: Value(notes),
    );
    await repository.logSession(session);
    state = AsyncValue.data(await repository.activeSession());
  }

  Future<void> resumeSession(FocusSession previousSession) async {
    // Start a new session with details from the previous one
    await startSession(
      taskId: previousSession.taskId,
      projectId: previousSession.projectId,
      targetMinutes: previousSession.durationMinutes,
      notes: previousSession.notes,
    );
  }

  Future<void> pauseSession() async {
    final current = state.value;
    if (current == null) return;
    final repository = ref.read(focusRepositoryProvider);
    await repository.closeSession(current.id, DateTime.now());
    state = const AsyncValue.data(null);
  }
}
