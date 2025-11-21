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

  Future<void> closeSession(String id, DateTime endedAt) {
    return (update(focusSessions)..where((tbl) => tbl.id.equals(id))).write(
      FocusSessionsCompanion(endedAt: Value(endedAt)),
    );
  }
}
