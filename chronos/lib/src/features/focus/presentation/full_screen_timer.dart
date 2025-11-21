import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/focus_session_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../dashboard/presentation/dashboard_metrics.dart';

class FullScreenFocusTimer extends ConsumerStatefulWidget {
  const FullScreenFocusTimer({super.key});

  @override
  ConsumerState<FullScreenFocusTimer> createState() =>
      _FullScreenFocusTimerState();
}

class _FullScreenFocusTimerState extends ConsumerState<FullScreenFocusTimer> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _enterFullScreen());
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && ref.read(focusSessionControllerProvider).value != null) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _exitFullScreen();
    super.dispose();
  }

  Future<void> _enterFullScreen() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _exitFullScreen() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  Widget build(BuildContext context) {
    final activeSessionState = ref.watch(focusSessionControllerProvider);
    final controller = ref.read(focusSessionControllerProvider.notifier);
    final activeSession = activeSessionState.value;
    final isProcessing = activeSessionState.isLoading;

    if (activeSession == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => Navigator.of(context).pop(),
      );
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final progress = sessionProgress(activeSession);
    final displayDuration = sessionDurationDisplay(activeSession);
    final displayLabel = sessionLabel(activeSession);
    final targetMinutes = sessionTargetMinutes(activeSession);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Exit button
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white70,
                      size: 32,
                    ),
                  ),
                ),
                const Spacer(),
                // Large clock
                SizedBox(
                  width: 400,
                  height: 400,
                  child: CustomPaint(
                    painter: _LargeFocusClockPainter(progress: progress),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          displayLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          displayDuration,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 96,
                            fontWeight: FontWeight.bold,
                            height: 0.9,
                          ),
                        ),
                        if (targetMinutes != null)
                          Text(
                            'of ${targetMinutes.toString().padLeft(2, '0')} min',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 20,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                // Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: isProcessing
                          ? null
                          : () => controller.pauseSession(),
                      icon: const Icon(
                        Icons.pause_circle_filled,
                        color: Colors.white,
                        size: 64,
                      ),
                      padding: const EdgeInsets.all(16),
                      constraints: const BoxConstraints(
                        minWidth: 72,
                        minHeight: 72,
                      ),
                      tooltip: 'Pause',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LargeFocusClockPainter extends CustomPainter {
  const _LargeFocusClockPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const strokeWidth = 24.0;
    final radius = (size.shortestSide - strokeWidth) / 2;
    final backgroundPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeCap = StrokeCap.round;
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = ChronosTheme.focusAccent.withValues(alpha: 0.8)
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
  bool shouldRepaint(covariant _LargeFocusClockPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
