import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/section_card.dart';
import '../../dashboard/data/dashboard_models.dart';

class GoalsPage extends StatelessWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        SectionCard(
          title: 'Active Goals',
          subtitle: 'Track milestones & completion',
          trailing: FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add_rounded),
            label: const Text('New Goal'),
          ),
          child: Column(
            children: mockGoals
                .map((goal) => _GoalProgressTile(goal: goal))
                .toList(),
          ),
        ),
        const SizedBox(height: 24),
        SectionCard(
          title: 'Weekly Milestones',
          subtitle: 'Plan the steps that feed your goals',
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: List.generate(
              4,
              (index) => _MilestoneCard(
                label: 'Milestone ${index + 1}',
                description: 'Outline actionable checkpoint for key projects',
                due: DateTime.now().add(Duration(days: index * 2 + 1)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GoalProgressTile extends StatelessWidget {
  const _GoalProgressTile({required this.goal});

  final GoalProgress goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [goal.color.withOpacity(.15), goal.color.withOpacity(.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Due ${DateFormat.MMMd().format(goal.deadline)}',
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              Text(
                '${(goal.progress * 100).round()}%',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(.4),
              valueColor: AlwaysStoppedAnimation(goal.color),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.flag_rounded, color: goal.color),
              const SizedBox(width: 8),
              Text(
                'Next milestone: Storyboarding',
                style: theme.textTheme.labelMedium,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Adjust'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({
    required this.label,
    required this.description,
    required this.due,
  });

  final String label;
  final String description;
  final DateTime due;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.colorScheme.surfaceVariant.withOpacity(.35),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(description, style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 16),
              const SizedBox(width: 6),
              Text(
                DateFormat.MMMd().format(due),
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
