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
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 200,
                  child: CustomPaint(
                    painter: _FocusClockPainter(progress: progress),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            displayLabel,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            displayDuration,
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            targetMinutes != null
                                ? 'of $targetMinutes mins'
                                : 'No target',
                            style: theme.textTheme.labelMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FilledButton.icon(
                      onPressed: () {
                        if (activeSession != null) {
                          focusController.pauseSession();
                        } else {
                          focusController.startSession();
                        }
                      },
                      icon: Icon(
                        activeSession != null
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                      label: Text(
                        activeSession != null
                            ? 'Pause Session'
                            : 'Start Session',
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (recentSessions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          children: [
                            Icon(
                              Icons.access_time_outlined,
                              size: 48,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No focus sessions logged yet.',
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () => focusController.startSession(),
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: const Text('Start your first'),
                            ),
                          ],
                        ),
                      )
                    else
                      ...recentSessions.map(
                        (session) => _FocusSummaryTile(session: session),
                      ),
                  ],
                ),
              ),
            ],
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
          child: Text('Unable to load focus sessions: $error'),
        ),
      ),
    );
  }
}

class _FocusClockPainter extends CustomPainter {
  _FocusClockPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final strokeWidth = 16.0;
    final radius = (size.shortestSide - strokeWidth) / 2;
    final backgroundPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = Colors.white.withValues(alpha: .15)
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = ChronosTheme.focusAccent
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _FocusClockPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _FocusSummaryTile extends StatelessWidget {
  const _FocusSummaryTile({required this.session});

  final FocusSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = session.endedAt == null;
    final durationMinutes = sessionDisplayMinutes(session);
    final label = session.notes?.isNotEmpty == true
        ? session.notes!
        : (isActive ? 'Active session' : 'Focus session');
    final timestamp = DateFormat.MMMd().add_jm().format(session.startedAt);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .4),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt_rounded, color: ChronosTheme.focusAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$label • $timestamp',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text('$durationMinutes mins', style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}
