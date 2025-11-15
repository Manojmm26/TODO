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

final mockTimelineTasks = <TimelineTask>[
  TimelineTask(
    title: 'Finalize Chronos brand board',
    bucket: TimelineBucket.immediate,
    due: DateTime.now().add(const Duration(hours: 2)),
    progress: .45,
    project: 'Chronos Launch',
    priority: TaskPriority.high,
  ),
  TimelineTask(
    title: 'Prep weekly sprint notes',
    bucket: TimelineBucket.today,
    due: DateTime.now().add(const Duration(hours: 6)),
    progress: .2,
    project: 'Team Operations',
  ),
  TimelineTask(
    title: 'Study session: Italian verbs',
    bucket: TimelineBucket.upcoming,
    due: DateTime.now().add(const Duration(days: 2)),
    progress: .8,
    project: 'Learn Italian',
  ),
  TimelineTask(
    title: 'Refine side-project backlog',
    bucket: TimelineBucket.backlog,
    due: DateTime.now().add(const Duration(days: 10)),
    progress: .05,
  ),
];

final mockGoals = <GoalProgress>[
  GoalProgress(
    title: 'Launch Chronos beta',
    progress: .62,
    deadline: DateTime.now().add(const Duration(days: 21)),
    color: const Color(0xFF7C4DFF),
  ),
  GoalProgress(
    title: 'Learn Italian basics',
    progress: .45,
    deadline: DateTime.now().add(const Duration(days: 35)),
    color: const Color(0xFFFF7043),
  ),
  GoalProgress(
    title: 'Read 12 books in 2025',
    progress: .28,
    deadline: DateTime(DateTime.now().year, 12, 31),
    color: const Color(0xFF26C6DA),
  ),
];

const mockDigest = DailyDigest(
  completedTasks: 7,
  totalFocusMinutes: 115,
  upcomingDeadlines: 3,
  weeklyGoalCompletion: .54,
);

const mockFocusSummary = <FocusSessionSummary>[
  FocusSessionSummary(label: 'Deep Work', minutes: 50),
  FocusSessionSummary(label: 'Daily Review', minutes: 15),
  FocusSessionSummary(label: 'Planning', minutes: 20),
];
