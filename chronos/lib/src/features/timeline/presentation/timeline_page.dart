import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/section_card.dart';
import '../../dashboard/data/dashboard_models.dart';

class TimelinePage extends StatelessWidget {
  const TimelinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: TimelineBucket.values
          .map(
            (bucket) => Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: SectionCard(
                title: bucket.label,
                subtitle: _bucketSubtitle(bucket),
                trailing: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.filter_list_rounded),
                ),
                child: Column(
                  children: mockTimelineTasks
                      .where((task) => task.bucket == bucket)
                      .map((task) => _TimelineRow(task: task))
                      .toList(),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  String _bucketSubtitle(TimelineBucket bucket) => switch (bucket) {
    TimelineBucket.immediate => 'Critical tasks flagged for now',
    TimelineBucket.today => 'Planned for the next 24h',
    TimelineBucket.upcoming => 'Scheduled later this week',
    TimelineBucket.backlog => 'Someday / backlog ideas',
  };
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.task});

  final TimelineTask task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dueText = DateFormat('EEE · h:mm a').format(task.due);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surfaceVariant.withOpacity(.3),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: task.bucket.color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (task.project != null)
                  Text(
                    task.project!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: task.progress,
                  minHeight: 5,
                  backgroundColor: theme.colorScheme.surface,
                  valueColor: AlwaysStoppedAnimation(task.bucket.color),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(dueText, style: theme.textTheme.labelSmall),
              Text(
                task.priority.label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
