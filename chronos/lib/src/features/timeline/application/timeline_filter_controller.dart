import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dashboard/data/dashboard_models.dart';

class TimelineFilters {
  const TimelineFilters({
    this.buckets = const {...TimelineBucket.values},
    this.dateRange,
  });

  final Set<TimelineBucket> buckets;
  final DateTimeRange? dateRange;

  TimelineFilters copyWith({
    Set<TimelineBucket>? buckets,
    DateTimeRange? dateRange,
  }) => TimelineFilters(
    buckets: buckets ?? this.buckets,
    dateRange: dateRange ?? this.dateRange,
  );
}

final timelineFilterProvider =
    StateNotifierProvider<TimelineFilterController, TimelineFilters>(
      (ref) => TimelineFilterController(),
    );

class TimelineFilterController extends StateNotifier<TimelineFilters> {
  TimelineFilterController() : super(const TimelineFilters());

  void toggleBucket(TimelineBucket bucket) {
    final nextBuckets = Set<TimelineBucket>.from(state.buckets);
    if (nextBuckets.contains(bucket)) {
      nextBuckets.remove(bucket);
    } else {
      nextBuckets.add(bucket);
    }
    state = state.copyWith(
      buckets: nextBuckets.isEmpty
          ? const {...TimelineBucket.values}
          : nextBuckets,
    );
  }

  void selectAllBuckets() {
    state = state.copyWith(buckets: const {...TimelineBucket.values});
  }

  void clearBuckets() {
    state = state.copyWith(buckets: const <TimelineBucket>{});
  }

  void setDateRange(DateTimeRange? range) {
    state = state.copyWith(dateRange: range);
  }

  void clearDateRange() {
    state = state.copyWith(dateRange: null);
  }
}
