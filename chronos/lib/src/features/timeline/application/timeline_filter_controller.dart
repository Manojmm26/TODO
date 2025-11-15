import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dashboard/data/dashboard_models.dart';

final timelineBucketFilterProvider = StateNotifierProvider<TimelineBucketFilterController, Set<TimelineBucket>>(
  (ref) => TimelineBucketFilterController(),
);

class TimelineBucketFilterController extends StateNotifier<Set<TimelineBucket>> {
  TimelineBucketFilterController()
      : super({
          ...TimelineBucket.values,
        });

  void toggle(TimelineBucket bucket) {
    final next = {...state};
    if (next.contains(bucket)) {
      next.remove(bucket);
    } else {
      next.add(bucket);
    }
    state = next.isEmpty ? {...TimelineBucket.values} : next;
  }

  void selectAll() => state = {...TimelineBucket.values};

  void clear() => state = {};
}
