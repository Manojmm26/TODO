import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../application/focus_session_controller.dart';
import '../../../application/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/local/app_database.dart';
import '../../../shared/widgets/section_card.dart';
import '../../dashboard/presentation/dashboard_metrics.dart';

class FocusPage extends ConsumerWidget {
  const FocusPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksStreamProvider);
    final sessionsAsync = ref.watch(focusSessionsStreamProvider);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        SectionCard(
          title: 'Focus Session',
          subtitle: 'Interactive time clock with zen mode',
          child: _FocusTimer(
            tasksAsync: tasksAsync,
            sessionsAsync: sessionsAsync,
          ),
        ),
        const SizedBox(height: 24),
        SectionCard(
          title: 'Session History',
          subtitle: 'Log of today’s focus blocks',
          child: _SessionHistory(sessionsAsync: sessionsAsync),
        ),
        const SizedBox(height: 24),
        const SectionCard(
          title: 'Ambient Options',
          subtitle: 'Enhance focus with background cues',
          child: _AmbientOptions(),
        ),
      ],
    );
  }
}

class _FocusTimer extends ConsumerStatefulWidget {
  const _FocusTimer({required this.tasksAsync, required this.sessionsAsync});

  final AsyncValue<List<Task>> tasksAsync;
  final AsyncValue<List<FocusSession>> sessionsAsync;

  @override
  ConsumerState<_FocusTimer> createState() => _FocusTimerState();
}

class _FocusTimerState extends ConsumerState<_FocusTimer> {
  String? _selectedTaskId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sessionsAsync = widget.sessionsAsync;
    final sessions = sessionsAsync.asData?.value ?? const <FocusSession>[];
    final sorted = [...sessions]..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    final latestSession = sorted.isNotEmpty ? sorted.first : null;
    final activeSessionState = ref.watch(focusSessionControllerProvider);
    final activeSession = activeSessionState.value;
    final referenceSession = activeSession ?? latestSession;
    final progress = sessionProgress(referenceSession);
    final displayDuration = sessionDurationDisplay(referenceSession);
    final displayLabel = sessionLabel(referenceSession);
    final targetMinutes = sessionTargetMinutes(referenceSession);
    final controller = ref.read(focusSessionControllerProvider.notifier);
    final isWide = MediaQuery.of(context).size.width > 900;
    final isProcessing = activeSessionState.isLoading;

    if (sessionsAsync.isLoading && activeSessionState.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth > 600;
        return Flex(
          direction: horizontal ? Axis.horizontal : Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SizedBox(
              height: 220,
              width: 220,
              child: CustomPaint(
                painter: _FocusClockPainter(progress: progress),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(displayLabel, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text(
                        displayDuration,
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        targetMinutes != null ? 'of $targetMinutes mins' : 'No target',
                        style: theme.textTheme.labelLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24, width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FilledButton.icon(
                    onPressed: isProcessing
                        ? null
                        : () {
                            if (activeSession != null) {
                              controller.pauseSession();
                            } else {
                              controller.startSession(taskId: _selectedTaskId);
                            }
                          },
                    icon: Icon(activeSession != null ? Icons.pause_rounded : Icons.play_arrow_rounded),
                    label: Text(activeSession != null ? 'Pause Session' : 'Start Focus Session'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.center_focus_strong_rounded),
                    label: Text(isWide ? 'Enter Zen Mode' : 'Zen Mode'),
                  ),
                  const SizedBox(height: 16),
                  Text('Attach to task', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  widget.tasksAsync.when(
                    data: (tasks) {
                      if (tasks.isEmpty) {
                        return const Text('No tasks available to link.');
                      }
                      return DropdownButtonFormField<String>(
                        value: _selectedTaskId,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.task_alt_rounded),
                        ),
                        items: tasks
                            .map(
                              (task) => DropdownMenuItem(
                                value: task.id,
                                child: Text(task.title),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() => _selectedTaskId = value),
                        hint: const Text('Link current focus to a task'),
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (error, _) => Text('Unable to load tasks: $error'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FocusClockPainter extends CustomPainter {
  _FocusClockPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const strokeWidth = 18.0;
    final radius = (size.shortestSide - strokeWidth) / 2;
    final backgroundPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = Colors.white.withOpacity(.15)
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

class _SessionHistory extends StatelessWidget {
  const _SessionHistory({required this.sessionsAsync});

  final AsyncValue<List<FocusSession>> sessionsAsync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return sessionsAsync.when(
      data: (sessions) {
        if (sessions.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No focus sessions logged yet.'),
          );
        }
        final sorted = [...sessions]..sort((a, b) => b.startedAt.compareTo(a.startedAt));
        return Column(
          children: sorted
              .map((session) => _SessionHistoryTile(session: session, theme: theme))
              .toList(),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Unable to load sessions: $error'),
      ),
    );
  }
}

class _SessionHistoryTile extends StatelessWidget {
  const _SessionHistoryTile({required this.session, required this.theme});

  final FocusSession session;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final isActive = session.endedAt == null;
    final duration = sessionDisplayMinutes(session);
    final timestamp = DateFormat.yMMMd().add_jm().format(session.startedAt);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(.3),
      ),
      child: Row(
        children: [
          Icon(isActive ? Icons.play_circle_fill : Icons.timer_rounded, color: ChronosTheme.focusAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sessionLabel(session),
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(timestamp, style: theme.textTheme.labelSmall),
              ],
            ),
          ),
          Text('$duration mins', style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _AmbientOptions extends StatefulWidget {
  const _AmbientOptions();

  @override
  State<_AmbientOptions> createState() => _AmbientOptionsState();
}

class _AmbientOptionsState extends State<_AmbientOptions> {
  bool _ambientSounds = true;
  String _selectedSound = 'Rain';
  bool _notificationChimes = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile.adaptive(
          value: _ambientSounds,
          onChanged: (value) => setState(() => _ambientSounds = value),
          title: const Text('Ambient background sounds'),
          subtitle: const Text('Rain, cafe noise, or white noise presets'),
        ),
        if (_ambientSounds)
          DropdownButtonFormField<String>(
            initialValue: _selectedSound,
            items: const [
              DropdownMenuItem(value: 'Rain', child: Text('Rain')),
              DropdownMenuItem(value: 'Cafe', child: Text('Cafe murmurs')),
              DropdownMenuItem(value: 'Waves', child: Text('Ocean waves')),
            ],
            onChanged: (value) =>
                setState(() => _selectedSound = value ?? _selectedSound),
            decoration: const InputDecoration(labelText: 'Sound preset'),
          ),
        const SizedBox(height: 12),
        SwitchListTile.adaptive(
          value: _notificationChimes,
          onChanged: (value) => setState(() => _notificationChimes = value),
          title: const Text('Focus session chimes'),
          subtitle: const Text('Play gentle alerts for breaks and resumes'),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.spatial_audio_rounded),
            label: const Text('Preview sound'),
          ),
        ),
      ],
    );
  }
}
