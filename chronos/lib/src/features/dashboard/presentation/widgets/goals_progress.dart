import 'package:chronos/src/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/local/app_database.dart';
import '../../../../shared/widgets/goal_timer.dart';

class GoalsProgress extends StatelessWidget {
  const GoalsProgress({
    super.key,
    required this.goalsAsync,
    required this.tasksAsync,
  });

  final AsyncValue<List<Goal>> goalsAsync;
  final AsyncValue<List<Task>> tasksAsync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return goalsAsync.when(
      data: (goals) {
        return SectionCard(
          title: 'Goal Progress',
          subtitle: 'Visual tracker for major goals',
          trailing: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.analytics_rounded),
          ),
          child: goals.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No goals set yet',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                )
              : Column(
                  children: goals.map((goal) {
                    final tasks = tasksAsync.value ?? [];
                    final linkedTasks = tasks
                        .where((t) => t.goalId == goal.id)
                        .toList();
                    final progress = goal.isCompleted
                        ? 1.0
                        : linkedTasks.isNotEmpty
                        ? linkedTasks
                                  .where(
                                    (t) => t.status >= 1,
                                  ) // taskStatusCompleted
                                  .length /
                              linkedTasks.length
                        : (goal.progressOverride ?? 0.0);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      goal.title,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    GoalTimer(goal: goal, compact: true),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${(progress * 100).toInt()}%',
                                style: theme.textTheme.labelSmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            color: Color(goal.colorHex),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        );
      },
      loading: () => const Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stackTrace) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Unable to load goals: $error'),
        ),
      ),
    );
  }
}
