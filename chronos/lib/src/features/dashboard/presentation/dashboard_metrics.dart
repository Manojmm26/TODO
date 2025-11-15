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
  final minutes = sessionElapsedMinutes(session);
  final duration = Duration(minutes: minutes.round());
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
    return session.endedAt!.difference(session.startedAt).inMinutes.toDouble();
  }
  return DateTime.now().difference(session.startedAt).inMinutes.toDouble();
}

int sessionDisplayMinutes(FocusSession session) {
  return sessionElapsedMinutes(session).round();
}

bool isTaskCompleted(Task task) => task.status >= 2;

int focusMinutesToday(List<FocusSession> sessions) {
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));
  int minutes = 0;
  for (final session in sessions) {
    if (session.startedAt.isAfter(startOfDay) && session.startedAt.isBefore(endOfDay)) {
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
      .where((session) => session.startedAt.isAfter(startOfDay) && session.startedAt.isBefore(endOfDay))
      .length;
}
