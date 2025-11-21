import 'package:drift/drift.dart';

import '../app_database.dart';

part 'digest_dao.g.dart';

@DriftAccessor(tables: [DigestSnapshots])
class DigestDao extends DatabaseAccessor<ChronosDatabase> with _$DigestDaoMixin {
  DigestDao(super.db);

  Stream<List<DigestSnapshot>> watchSnapshots() =>
      select(digestSnapshots).watch();
  Future<void> upsertSnapshot(DigestSnapshotsCompanion snapshot) =>
      into(digestSnapshots).insertOnConflictUpdate(snapshot);
}
