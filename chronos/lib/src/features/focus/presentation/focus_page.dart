import 'dart:async';
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
import 'full_screen_timer.dart';

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
        const SizedBox(height: 24),
        SectionCard(
          title: 'Focus Streaks',
          subtitle: 'Your consistency journey',
          child: Consumer(
            builder: (context, ref, child) {
              final sessionsAsync = ref.watch(focusSessionsStreamProvider);
              return sessionsAsync.when(
                data: (sessions) {
                  final currentStreak = computeCurrentStreak(sessions);
                  final bestStreak = computeBestStreak(sessions);
                  final totalDays = totalFocusDays(sessions);
                  final totalMinutes = focusMinutesToday(sessions);
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _StreakMetric(
                              'Current',
                              '$currentStreak days',
                              Icons.local_fire_department,
                            ),
                          ),
                          Expanded(
                            child: _StreakMetric(
                              'Best',
                              '$bestStreak days',
                              Icons.emoji_events,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _StreakMetric(
                              'Total Days',
                              '$totalDays',
                              Icons.calendar_today,
                            ),
                          ),
                          Expanded(
                            child: _StreakMetric(
                              'Today',
                              '$totalMinutes min',
                              Icons.timer,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Text('Error: $error'),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        const SectionCard(
          title: 'Pomodoro',
          subtitle: 'Work + break cycles',
          child: _PomodoroSettings(),
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
  bool isBreakPhase = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && ref.read(focusSessionControllerProvider).value != null) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sessionsAsync = widget.sessionsAsync;
    final sessions = sessionsAsync.asData?.value ?? const <FocusSession>[];
    final sorted = [...sessions]
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    final latestSession = sorted.isNotEmpty ? sorted.first : null;
    final activeSessionState = ref.watch(focusSessionControllerProvider);
    final activeSession = activeSessionState.value;
    final referenceSession = activeSession ?? latestSession;
    final progress = sessionProgress(referenceSession);
    final displayDuration = sessionDurationDisplay(referenceSession);
    final displayLabel = sessionLabel(referenceSession);
    final targetMinutes = sessionTargetMinutes(referenceSession);
    final controller = ref.read(focusSessionControllerProvider.notifier);
    final isProcessing = activeSessionState.isLoading;

    final settings = ref.watch(settingsProvider);
    final pomodoroEnabled = settings.pomodoroEnabled;
    final workDuration = settings.workDuration;
    final breakDuration = settings.breakDuration;

    if (sessionsAsync.isLoading && activeSessionState.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    String phaseLabel = '';
    if (pomodoroEnabled) {
      phaseLabel = isBreakPhase ? 'Break' : 'Work';
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
                      Text(
                        '$displayLabel${phaseLabel.isNotEmpty ? ' ($phaseLabel)' : ''}',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        displayDuration,
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        targetMinutes != null
                            ? 'of $targetMinutes mins'
                            : 'No target',
                        style: theme.textTheme.labelLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24, width: 24),
            // Conditional Expanded: Only expand in horizontal layout
            horizontal
                ? Expanded(
                    child: _FocusControls(
                      activeSession: activeSession,
                      latestSession: latestSession,
                      isProcessing: isProcessing,
                      controller: controller,
                      pomodoroEnabled: pomodoroEnabled,
                      isBreakPhase: isBreakPhase,
                      workDuration: workDuration,
                      breakDuration: breakDuration,
                      tasksAsync: widget.tasksAsync,
                      selectedTaskId: _selectedTaskId,
                      onTaskSelected: (val) =>
                          setState(() => _selectedTaskId = val),
                      onPhaseToggle: () =>
                          setState(() => isBreakPhase = !isBreakPhase),
                      onStartNew: () => _startNewSession(controller),
                    ),
                  )
                : _FocusControls(
                    activeSession: activeSession,
                    latestSession: latestSession,
                    isProcessing: isProcessing,
                    controller: controller,
                    pomodoroEnabled: pomodoroEnabled,
                    isBreakPhase: isBreakPhase,
                    workDuration: workDuration,
                    breakDuration: breakDuration,
                    tasksAsync: widget.tasksAsync,
                    selectedTaskId: _selectedTaskId,
                    onTaskSelected: (val) =>
                        setState(() => _selectedTaskId = val),
                    onPhaseToggle: () =>
                        setState(() => isBreakPhase = !isBreakPhase),
                    onStartNew: () => _startNewSession(controller),
                  ),
          ],
        );
      },
    );
  }

  void _startNewSession(FocusSessionController controller) {
    final settings = ref.read(settingsProvider);
    controller.startSession(
      taskId: _selectedTaskId,
      targetMinutes: settings.pomodoroEnabled
          ? (isBreakPhase ? settings.breakDuration.round() : settings.workDuration.round())
          : 30, // default
    );
  }
}

class _FocusControls extends StatelessWidget {
  const _FocusControls({
    required this.activeSession,
    required this.latestSession,
    required this.isProcessing,
    required this.controller,
    required this.pomodoroEnabled,
    required this.isBreakPhase,
    required this.workDuration,
    required this.breakDuration,
    required this.tasksAsync,
    required this.selectedTaskId,
    required this.onTaskSelected,
    required this.onPhaseToggle,
    required this.onStartNew,
  });

  final FocusSession? activeSession;
  final FocusSession? latestSession;
  final bool isProcessing;
  final FocusSessionController controller;
  final bool pomodoroEnabled;
  final bool isBreakPhase;
  final double workDuration;
  final double breakDuration;
  final AsyncValue<List<Task>> tasksAsync;
  final String? selectedTaskId;
  final ValueChanged<String?> onTaskSelected;
  final VoidCallback onPhaseToggle;
  final VoidCallback onStartNew;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isResumable =
        latestSession != null &&
        latestSession!.endedAt != null &&
        latestSession!.startedAt.day == DateTime.now().day;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (activeSession != null)
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: isProcessing ? null : controller.pauseSession,
                  icon: const Icon(Icons.pause_rounded),
                  label: const Text('Pause'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isProcessing ? null : controller.pauseSession,
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Complete'),
                ),
              ),
            ],
          )
        else if (isResumable)
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: isProcessing
                      ? null
                      : () => controller.resumeSession(latestSession!),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Resume'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isProcessing ? null : onStartNew,
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  label: const Text('Start New'),
                ),
              ),
            ],
          )
        else
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isProcessing ? null : onStartNew,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start Focus Session'),
            ),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const FullScreenFocusTimer(),
                fullscreenDialog: true,
              ),
            );
          },
          icon: const Icon(Icons.fullscreen),
          label: const Text('Full Screen Timer'),
        ),
        const SizedBox(height: 16),
        Text('Attach to task', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        tasksAsync.when(
          data: (tasks) {
            if (tasks.isEmpty) {
              return const Text('No tasks available to link.');
            }
            return InputDecorator(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.task_alt_rounded),
                contentPadding: EdgeInsets.fromLTRB(12, 12, 8, 12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedTaskId,
                  isExpanded: true,
                  hint: const Text('Link current focus to a task'),
                  items: tasks
                      .map(
                        (task) => DropdownMenuItem(
                          value: task.id,
                          child: Text(task.title),
                        ),
                      )
                      .toList(),
                  onChanged: onTaskSelected,
                ),
              ),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => Text('Unable to load tasks: $error'),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: pomodoroEnabled ? onPhaseToggle : null,
          icon: Icon(isBreakPhase ? Icons.work : Icons.coffee_maker),
          label: Text(
            isBreakPhase
                ? 'Switch to Work (${workDuration.round()}min)'
                : 'Switch to Break (${breakDuration.round()}min)',
          ),
        ),
      ],
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
    const strokeWidth = 18.0;
    final radius = (size.shortestSide - strokeWidth) / 2;
    final backgroundPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = Colors.white.withValues(alpha: .15)
      ..strokeCap = StrokeCap.round;
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color
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
      oldDelegate.progress != progress || oldDelegate.color != color;
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
        final sorted = [...sessions]
          ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
        return Column(
          children: sorted
              .map(
                (session) =>
                    _SessionHistoryTile(session: session, theme: theme),
              )
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
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .3),
      ),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.play_circle_fill : Icons.timer_rounded,
            color: Theme.of(context).extension<CustomColors>()!.focusAccent!,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sessionLabel(session),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
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

class _AmbientOptions extends ConsumerWidget {
  const _AmbientOptions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Column(
      children: [
        SwitchListTile.adaptive(
          value: settings.ambientSounds,
          onChanged: notifier.updateAmbientSounds,
          title: const Text('Ambient background sounds'),
          subtitle: const Text('Rain, cafe noise, or white noise presets'),
        ),
        if (settings.ambientSounds)
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: settings.selectedSound,
            items: const [
              DropdownMenuItem(value: 'Rain', child: Text('Rain')),
              DropdownMenuItem(value: 'Cafe', child: Text('Cafe murmurs')),
              DropdownMenuItem(value: 'Waves', child: Text('Ocean waves')),
            ],
            onChanged: (value) =>
                notifier.updateSelectedSound(value ?? settings.selectedSound),
            decoration: const InputDecoration(labelText: 'Sound preset'),
          ),
        const SizedBox(height: 12),
        SwitchListTile.adaptive(
          value: settings.notificationChimes,
          onChanged: notifier.updateNotificationChimes,
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

class _StreakMetric extends StatelessWidget {
  const _StreakMetric(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(label, style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _PomodoroSettings extends ConsumerWidget {
  const _PomodoroSettings();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile.adaptive(
          value: settings.pomodoroEnabled,
          onChanged: notifier.updatePomodoroEnabled,
          title: const Text('Enable Pomodoro mode'),
          subtitle: const Text('Alternate work and break timers'),
        ),
        if (settings.pomodoroEnabled) ...[
          _DurationSlider(
            label: 'Work duration',
            value: settings.workDuration,
            min: 5,
            max: 90,
            onChanged: notifier.updateWorkDuration,
          ),
          _DurationSlider(
            label: 'Break duration',
            value: settings.breakDuration,
            min: 1,
            max: 30,
            onChanged: notifier.updateBreakDuration,
          ),
        ],
      ],
    );
  }
}

class _DurationSlider extends StatelessWidget {
  const _DurationSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelLarge),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          label: '${value.round()} min',
          onChanged: onChanged,
        ),
        Text('${value.round()} minutes', style: theme.textTheme.bodyMedium),
      ],
    );
  }
}
