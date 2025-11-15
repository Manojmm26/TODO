import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/section_card.dart';
import '../../dashboard/data/dashboard_models.dart';

class FocusPage extends StatelessWidget {
  const FocusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: const [
        SectionCard(
          title: 'Focus Session',
          subtitle: 'Interactive time clock with zen mode',
          child: _FocusTimer(),
        ),
        SizedBox(height: 24),
        SectionCard(
          title: 'Session History',
          subtitle: 'Log of today’s focus blocks',
          child: _SessionHistory(),
        ),
        SizedBox(height: 24),
        SectionCard(
          title: 'Ambient Options',
          subtitle: 'Enhance focus with background cues',
          child: _AmbientOptions(),
        ),
      ],
    );
  }
}

class _FocusTimer extends StatelessWidget {
  const _FocusTimer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = 0.65;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        return Flex(
          direction: isWide ? Axis.horizontal : Axis.vertical,
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
                      Text('Deep Work', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text(
                        '18:24',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text('of 30 mins'),
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
                    onPressed: () {},
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Start Focus Session'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.center_focus_strong_rounded),
                    label: const Text('Enter Zen Mode'),
                  ),
                  const SizedBox(height: 16),
                  Text('Attach to task', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.task_alt_rounded),
                    ),
                    items: mockTimelineTasks
                        .map(
                          (task) => DropdownMenuItem(
                            value: task.id,
                            child: Text(task.title),
                          ),
                        )
                        .toList(),
                    onChanged: (_) {},
                    hint: const Text('Link current focus to a task'),
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
  const _SessionHistory();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: mockFocusSummary.map((summary) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: theme.colorScheme.surfaceVariant.withOpacity(.3),
          ),
          child: Row(
            children: [
              Icon(Icons.timer_rounded, color: ChronosTheme.focusAccent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.label,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text('Session complete', style: theme.textTheme.labelSmall),
                  ],
                ),
              ),
              Text(
                '${summary.minutes} mins',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        );
      }).toList(),
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
            value: _selectedSound,
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
