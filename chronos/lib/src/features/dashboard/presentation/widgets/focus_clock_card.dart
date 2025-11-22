import 'dart:math' as math;

import 'package:chronos/src/application/focus_session_controller.dart';
import 'package:chronos/src/core/theme/app_theme.dart';
import 'package:chronos/src/features/dashboard/presentation/dashboard_metrics.dart';
import 'package:chronos/src/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../data/local/app_database.dart';

class FocusClockCard extends ConsumerWidget {
  const FocusClockCard({super.key, required this.sessionsAsync});

  final AsyncValue<List<FocusSession>> sessionsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return sessionsAsync.when(
      data: (sessions) {
        final sorted = [...sessions]
          ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
        final activeSession = findActiveSession(sorted);
        final latestSession = sorted.isNotEmpty ? sorted.first : null;
        final referenceSession = activeSession ?? latestSession;
        final progress = sessionProgress(referenceSession);
        final displayDuration = sessionDurationDisplay(referenceSession);
        final displayLabel = sessionLabel(referenceSession);
        final targetMinutes = sessionTargetMinutes(referenceSession);
        final recentSessions = sorted.take(3).toList();
        final focusController = ref.read(
          focusSessionControllerProvider.notifier,
        );

        return SectionCard(
          title: 'Time Clock',
          subtitle: activeSession != null
              ? 'In focus now'
              : 'Current focus session',
          trailing: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.more_horiz),
            label: const Text('History'),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 200,
                width: 200,
                child: CustomPaint(
                  painter: _FocusClockPainter(
                    progress: progress,
                    color: Theme.of(
                      context,
                    ).extension<CustomColors>()!.focusAccent!,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(displayLabel, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          displayDuration,
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (targetMinutes != null)
                          Text(
                            'of $targetMinutes min',
                            style: theme.textTheme.labelSmall,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (activeSession != null)
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => focusController.pauseSession(),
                        icon: const Icon(Icons.pause_rounded),
                        label: const Text('Pause'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => focusController.pauseSession(),
                        icon: const Icon(Icons.stop_rounded),
                        label: const Text('End'),
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => focusController.startSession(),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Start Focus'),
                  ),
                ),
              const SizedBox(height: 24),
              if (recentSessions.isNotEmpty) ...[
                const Divider(),
                const SizedBox(height: 12),
                ...recentSessions.map(
                  (session) => _FocusSummaryTile(session: session),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Text('Error: $error'),
    );
  }
}

class _FocusClockPainter extends CustomPainter {
  _FocusClockPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const strokeWidth = 16.0;
    final radius = (size.shortestSide - strokeWidth) / 2;

    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _FocusClockPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _FocusSummaryTile extends StatelessWidget {
  const _FocusSummaryTile({required this.session});

  final FocusSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final duration = sessionDisplayMinutes(session);
    final startTime = DateFormat.jm().format(session.startedAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 16,
            color: Theme.of(context).extension<CustomColors>()!.focusAccent!,
          ),
          const SizedBox(width: 8),
          Text(sessionLabel(session), style: theme.textTheme.bodyMedium),
          const Spacer(),
          Text('$duration min • $startTime', style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}
