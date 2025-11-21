import 'package:drift/drift.dart';

import '../app_database.dart';

part 'tag_dao.g.dart';

@DriftAccessor(tables: [Tags])
class TagDao extends DatabaseAccessor<ChronosDatabase> with _$TagDaoMixin {
  TagDao(super.db);

  Stream<List<Tag>> watchTags() => select(tags).watch();
  Future<void> upsertTag(TagsCompanion tag) =>
      into(tags).insertOnConflictUpdate(tag);
}
