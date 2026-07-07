import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/quick_add_controller.dart';
import '../../data/local/app_database.dart';

String _formatSeconds(int totalSeconds) {
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

class GoalTimer extends ConsumerStatefulWidget {
  const GoalTimer({super.key, required this.goal, this.compact = false});
  final Goal goal;
  final bool compact;

  @override
  ConsumerState<GoalTimer> createState() => _GoalTimerState();
}

class _GoalTimerState extends ConsumerState<GoalTimer> {
  Timer? _timer;
  late int _currentSessionSeconds;

  @override
  void initState() {
    super.initState();
    _currentSessionSeconds = 0;
    if (widget.goal.timerStartedAt != null) {
      _startTicker();
    }
  }

  @override
  void didUpdateWidget(GoalTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.goal.timerStartedAt != oldWidget.goal.timerStartedAt) {
      if (widget.goal.timerStartedAt != null) {
        _startTicker();
      } else {
        _stopTicker();
      }
    }
  }

  void _startTicker() {
    _timer?.cancel();
    _updateSeconds();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _updateSeconds();
        });
      }
    });
  }

  void _stopTicker() {
    _timer?.cancel();
    _timer = null;
    if (mounted) {
      setState(() {
        _currentSessionSeconds = 0;
      });
    }
  }

  void _updateSeconds() {
    if (widget.goal.timerStartedAt != null) {
      _currentSessionSeconds = DateTime.now()
          .difference(widget.goal.timerStartedAt!)
          .inSeconds;
    } else {
      _currentSessionSeconds = 0;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRunning = widget.goal.timerStartedAt != null;
    final totalFormatted = _formatSeconds(
      widget.goal.totalSeconds + _currentSessionSeconds,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isRunning
            ? theme.colorScheme.primaryContainer.withValues(alpha: .5)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: .3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
            iconSize: 20,
            onPressed: () {
              final controller = ref.read(quickAddControllerProvider);
              if (isRunning) {
                controller.stopGoalTimer(widget.goal.id);
              } else {
                controller.startGoalTimer(widget.goal.id);
              }
            },
            icon: Icon(
              isRunning
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_filled_rounded,
              color: isRunning
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            totalFormatted,
            style: theme.textTheme.labelMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
              fontWeight: isRunning ? FontWeight.bold : null,
              color: isRunning
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (isRunning && _currentSessionSeconds > 0 && !widget.compact) ...[
            const SizedBox(width: 6),
            Text(
              '(+${_formatSeconds(_currentSessionSeconds)})',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary.withValues(alpha: .7),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
