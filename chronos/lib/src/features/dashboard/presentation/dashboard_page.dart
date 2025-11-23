import 'package:chronos/src/features/dashboard/presentation/widgets/daily_digest_card.dart';
import 'package:chronos/src/features/dashboard/presentation/widgets/focus_clock_card.dart';
import 'package:chronos/src/features/dashboard/presentation/widgets/goals_progress.dart';
import 'package:chronos/src/features/dashboard/presentation/widgets/time_left_card.dart';
import 'package:chronos/src/features/dashboard/presentation/widgets/timeline_overview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../application/providers.dart';

import '../../../shared/constants.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  bool _showCompleted = false;

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksStreamProvider);
    final goalsAsync = ref.watch(goalsStreamProvider);
    final sessionsAsync = ref.watch(focusSessionsStreamProvider);
    final subTasksAsync = ref.watch(subTasksStreamProvider);
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final bool isWide = width > 1200;

    // Filter tasks based on completion status
    final filteredTasksAsync = tasksAsync.whenData((tasks) {
      final sortedTasks = [...tasks]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (_showCompleted) return sortedTasks;
      return sortedTasks.where((t) => t.status < taskStatusCompleted).toList();
    });

    // Filter goals based on completion status
    final filteredGoalsAsync = goalsAsync.whenData((goals) {
      final sortedGoals = [...goals]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (_showCompleted) return sortedGoals;
      return sortedGoals.where((g) => !g.isCompleted).toList();
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today • ${DateFormat.yMMMMEEEEd().format(DateTime.now())}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                onPressed: () =>
                    setState(() => _showCompleted = !_showCompleted),
                icon: Icon(
                  _showCompleted
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                ),
                tooltip: _showCompleted
                    ? 'Hide completed items'
                    : 'Show completed items',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            children: [
              SizedBox(
                width: isWide ? width * .35 - 48 : width - 48,
                child: const TimeLeftCard(),
              ),
              SizedBox(
                width: isWide ? width * .35 - 48 : width - 48,
                child: GoalsProgress(
                  goalsAsync: filteredGoalsAsync,
                  tasksAsync: tasksAsync,
                ),
              ),
              SizedBox(
                width: isWide ? width * .55 : width - 48,
                child: TimelineOverview(
                  tasksAsync: filteredTasksAsync,
                  subTasksAsync: subTasksAsync,
                ),
              ),

              SizedBox(
                width: isWide ? width * .4 : width - 48,
                child: FocusClockCard(sessionsAsync: sessionsAsync),
              ),
              SizedBox(
                width: isWide ? width * .5 - 48 : width - 48,
                child: DailyDigestCard(
                  tasksAsync: filteredTasksAsync,
                  sessionsAsync: sessionsAsync,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
