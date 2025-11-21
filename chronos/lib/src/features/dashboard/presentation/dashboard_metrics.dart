import 'dart:math' as math;
import 'package:chronos/src/shared/constants.dart';

import '../../../data/local/app_database.dart';
import '../data/dashboard_models.dart';

Map<TimelineBucket, List<Task>> groupTasksByBucket(List<Task> tasks) {
  final map = {for (final bucket in TimelineBucket.values) bucket: <Task>[]};
  for (final task in tasks) {
    final bucket = bucketForTask(task);
    map[bucket]!.add(task);
  }
  return map;
}

Map<String, List<SubTask>> groupSubTasksByTask(List<SubTask> subTasks) {
  final map = <String, List<SubTask>>{};
  for (final subTask in subTasks) {
    map.putIfAbsent(subTask.taskId, () => []).add(subTask);
  }
  for (final entry in map.entries) {
    entry.value.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }
  return map;
}

TimelineBucket bucketForTask(Task task) {
  if (task.flagImmediate) return TimelineBucket.immediate;
  if (task.flagToday) return TimelineBucket.today;
  final due = task.dueDate;
  if (due == null) return TimelineBucket.backlog;
  final now = DateTime.now();
  final difference = due.difference(DateTime(now.year, now.month, now.day));
  if (!difference.isNegative && difference.inDays == 0) {
    return TimelineBucket.today;
  } else if (difference.inDays <= 3) {
    return TimelineBucket.upcoming;
  }
  return TimelineBucket.backlog;
}

double taskProgress(Task task) {
  final est = task.estimatedMinutes <= 0 ? 60 : task.estimatedMinutes;
  final actual = task.actualMinutes;
  final value = actual / est;
  return value.clamp(0.0, 1.0);
}

double subTaskCompletionProgress(List<SubTask> subTasks) {
  if (subTasks.isEmpty) return 0;
  final completed = subTasks.where((subTask) => subTask.isCompleted).length;
  return completed / subTasks.length;
}

TaskPriority priorityFromInt(int value) {
  switch (value) {
    case 0:
      return TaskPriority.high;
    case 1:
      return TaskPriority.medium;
    default:
      return TaskPriority.low;
  }
}

FocusSession? findActiveSession(List<FocusSession> sessions) {
  for (final session in sessions) {
    if (session.endedAt == null) {
      return session;
    }
  }
  return null;
}

double sessionProgress(FocusSession? session) {
  if (session == null) return 0;
  final target = sessionTargetMinutes(session) ?? 30;
  final minutes = sessionElapsedMinutes(session);
  return (minutes / target).clamp(0.0, 1.0);
}

String sessionDurationDisplay(FocusSession? session) {
  if (session == null) return '00:00';
  final now = DateTime.now();
  final end = session.endedAt ?? now;
  final duration = end.difference(session.startedAt);
  final mm = duration.inMinutes.toString().padLeft(2, '0');
  final ss = (duration.inSeconds % 60).toString().padLeft(2, '0');
  return '$mm:$ss';
}

String sessionLabel(FocusSession? session) {
  if (session == null) return 'No session';
  if (session.notes?.isNotEmpty == true) return session.notes!;
  if (session.taskId != null) return 'Task ${session.taskId}';
  if (session.projectId != null) return 'Project ${session.projectId}';
  return 'Focus Session';
}

int? sessionTargetMinutes(FocusSession? session) {
  if (session == null) return null;
  return session.durationMinutes > 0 ? session.durationMinutes : null;
}

double sessionElapsedMinutes(FocusSession session) {
  if (session.endedAt != null) {
    return session.endedAt!.difference(session.startedAt).inSeconds / 60.0;
  }
  return DateTime.now().difference(session.startedAt).inSeconds / 60.0;
}

int sessionDisplayMinutes(FocusSession session) {
  return sessionElapsedMinutes(session).round();
}

bool isTaskCompleted(Task task) => task.status >= taskStatusCompleted;

int focusMinutesToday(List<FocusSession> sessions) {
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));
  int minutes = 0;
  for (final session in sessions) {
    if (session.startedAt.isAfter(startOfDay) &&
        session.startedAt.isBefore(endOfDay)) {
      minutes += sessionElapsedMinutes(session).round();
    }
  }
  return minutes;
}

double weeklyProgress(List<Task> tasks) {
  if (tasks.isEmpty) return 0;
  final completed = tasks.where(isTaskCompleted).length;
  return completed / tasks.length;
}

int upcomingDeadlines(List<Task> tasks) {
  final now = DateTime.now();
  final threshold = now.add(const Duration(days: 3));
  return tasks.where((task) {
    final due = task.dueDate;
    return due != null && due.isAfter(now) && due.isBefore(threshold);
  }).length;
}

int sessionsTodayCount(List<FocusSession> sessions) {
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));
  return sessions
      .where(
        (session) =>
            session.startedAt.isAfter(startOfDay) &&
            session.startedAt.isBefore(endOfDay),
      )
      .length;
}

/// Returns the fraction of time remaining in the current day as a 0..1 value.
double timeLeftFractionToday() {
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));
  final total = endOfDay.difference(startOfDay).inMinutes.toDouble();
  final left = endOfDay.difference(now).inMinutes.toDouble();
  return (left / total).clamp(0.0, 1.0);
}

/// Returns the fraction of time remaining in the current week (Mon-Sun) as 0..1.
double timeLeftFractionWeek() {
  final now = DateTime.now();
  // Start of week (Monday)
  final startOfWeek = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(Duration(days: now.weekday - 1));
  final endOfWeek = startOfWeek.add(const Duration(days: 7));
  final total = endOfWeek.difference(startOfWeek).inMinutes.toDouble();
  final left = endOfWeek.difference(now).inMinutes.toDouble();
  return (left / total).clamp(0.0, 1.0);
}

/// Returns the fraction of time remaining in the current month as 0..1.
double timeLeftFractionMonth() {
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final startOfNextMonth = (now.month < 12)
      ? DateTime(now.year, now.month + 1, 1)
      : DateTime(now.year + 1, 1, 1);
  final total = startOfNextMonth.difference(startOfMonth).inMinutes.toDouble();
  final left = startOfNextMonth.difference(now).inMinutes.toDouble();
  return (left / total).clamp(0.0, 1.0);
}

int computeCurrentStreak(List<FocusSession> sessions) {
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final datesWithFocus = _sessionsByDate(sessions).keys.toList()
    ..sort((a, b) => b.compareTo(a));
  int streak = 0;
  DateTime expectedDate = todayStart;
  for (final date in datesWithFocus) {
    if (date.isAfter(expectedDate)) continue;
    if (date.isAtSameMomentAs(expectedDate)) {
      streak++;
      expectedDate = expectedDate.subtract(const Duration(days: 1));
    } else {
      break;
    }
  }
  return streak;
}

int computeBestStreak(List<FocusSession> sessions) {
  final datesWithFocus = _sessionsByDate(sessions).keys.toList()..sort();
  if (datesWithFocus.isEmpty) return 0;
  int maxStreak = 1;
  int currentStreak = 1;
  for (int i = 1; i < datesWithFocus.length; i++) {
    if (datesWithFocus[i].difference(datesWithFocus[i - 1]).inDays == 1) {
      currentStreak++;
      maxStreak = math.max(maxStreak, currentStreak);
    } else {
      currentStreak = 1;
    }
  }
  return maxStreak;
}

int totalFocusDays(List<FocusSession> sessions) =>
    _sessionsByDate(sessions).length;

Map<DateTime, bool> _sessionsByDate(List<FocusSession> sessions) {
  final map = <DateTime, bool>{};
  for (final session in sessions) {
    final date = DateTime(
      session.startedAt.year,
      session.startedAt.month,
      session.startedAt.day,
    );
    map[date] = true;
  }
  return map;
}
