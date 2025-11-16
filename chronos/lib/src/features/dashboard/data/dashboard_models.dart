import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum TimelineBucket { immediate, today, upcoming, backlog }

class TimelineTask {
  TimelineTask({
    required this.title,
    required this.bucket,
    required this.due,
    required this.progress,
    this.project,
    this.priority = TaskPriority.medium,
  }) : id = _uuid.v4();

  final String id;
  final String title;
  final TimelineBucket bucket;
  final DateTime due;
  final double progress;
  final String? project;
  final TaskPriority priority;
}

class GoalProgress {
  GoalProgress({
    required this.title,
    required this.progress,
    required this.deadline,
    required this.color,
  }) : id = _uuid.v4();

  final String id;
  final String title;
  final double progress;
  final DateTime deadline;
  final Color color;
}

class FocusSessionSummary {
  const FocusSessionSummary({required this.label, required this.minutes});

  final String label;
  final int minutes;
}

class DailyDigest {
  const DailyDigest({
    required this.completedTasks,
    required this.totalFocusMinutes,
    required this.upcomingDeadlines,
    required this.weeklyGoalCompletion,
  });

  final int completedTasks;
  final int totalFocusMinutes;
  final int upcomingDeadlines;
  final double weeklyGoalCompletion;
}

extension TimelineBucketInfo on TimelineBucket {
  String get label {
    switch (this) {
      case TimelineBucket.immediate:
        return 'Immediate';
      case TimelineBucket.today:
        return 'Today';
      case TimelineBucket.upcoming:
        return 'Upcoming';
      case TimelineBucket.backlog:
        return 'Backlog';
    }
  }

  Color get color {
    switch (this) {
      case TimelineBucket.immediate:
        return const Color(0xFFE53935);
      case TimelineBucket.today:
        return const Color(0xFFFFA000);
      case TimelineBucket.upcoming:
        return const Color(0xFF1E88E5);
      case TimelineBucket.backlog:
        return const Color(0xFF6D6D6D);
    }
  }
}

enum TaskPriority { high, medium, low }

extension TaskPriorityLabel on TaskPriority {
  String get label => switch (this) {
    TaskPriority.high => 'High',
    TaskPriority.medium => 'Medium',
    TaskPriority.low => 'Low',
  };
}
