import 'package:chronos/src/features/dashboard/presentation/widgets/daily_digest_card.dart';
import 'package:chronos/src/features/dashboard/presentation/widgets/focus_clock_card.dart';
import 'package:chronos/src/features/dashboard/presentation/widgets/goals_progress.dart';
import 'package:chronos/src/features/dashboard/presentation/widgets/time_left_card.dart';
import 'package:chronos/src/features/dashboard/presentation/widgets/timeline_overview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../application/providers.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksStreamProvider);
    final goalsAsync = ref.watch(goalsStreamProvider);
    final sessionsAsync = ref.watch(focusSessionsStreamProvider);
    final subTasksAsync = ref.watch(subTasksStreamProvider);
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final bool isWide = width > 1200;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today • ${DateFormat.yMMMMEEEEd().format(DateTime.now())}',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
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
                  goalsAsync: goalsAsync,
                  tasksAsync: tasksAsync,
                ),
              ),
              SizedBox(
                width: isWide ? width * .55 : width - 48,
                child: TimelineOverview(
                  tasksAsync: tasksAsync,
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
                  tasksAsync: tasksAsync,
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
