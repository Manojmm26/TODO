import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rrule/rrule.dart';

enum RecurrencePreset { none, daily, weekdays, weekly, monthly, custom }

extension RecurrencePresetX on RecurrencePreset {
  String get label => switch (this) {
        RecurrencePreset.none => 'Does not repeat',
        RecurrencePreset.daily => 'Daily',
        RecurrencePreset.weekdays => 'Weekdays',
        RecurrencePreset.weekly => 'Weekly',
        RecurrencePreset.monthly => 'Monthly',
        RecurrencePreset.custom => 'Custom',
      };

  String get description => switch (this) {
        RecurrencePreset.none => 'One-time task',
        RecurrencePreset.daily => 'Repeats every day',
        RecurrencePreset.weekdays => 'Repeats Monday through Friday',
        RecurrencePreset.weekly => 'Repeats every week',
        RecurrencePreset.monthly => 'Repeats every month',
        RecurrencePreset.custom => 'Use a custom RRULE',
      };
}

String? buildRecurrenceRule(
  RecurrencePreset preset, {
  DateTime? endDate,
  String? customRule,
}) {
  String? baseRule;
  switch (preset) {
    case RecurrencePreset.none:
      baseRule = null;
      break;
    case RecurrencePreset.daily:
      baseRule = 'FREQ=DAILY';
      break;
    case RecurrencePreset.weekdays:
      baseRule = 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR';
      break;
    case RecurrencePreset.weekly:
      baseRule = 'FREQ=WEEKLY';
      break;
    case RecurrencePreset.monthly:
      baseRule = 'FREQ=MONTHLY';
      break;
    case RecurrencePreset.custom:
      final trimmed = customRule?.trim();
      baseRule = (trimmed != null && trimmed.isNotEmpty) ? trimmed : null;
      break;
  }

  if (baseRule == null) return null;

  if (endDate != null) {
    final untilValue = _formatUntil(endDate);
    return '$baseRule;UNTIL=$untilValue';
  }

  return baseRule;
}

String recurrenceSummary(
  RecurrencePreset preset, {
  DateTime? endDate,
}) {
  final buffer = StringBuffer();
  buffer.write(preset.description);
  if (preset == RecurrencePreset.none) {
    return buffer.toString();
  }
  if (endDate != null) {
    buffer.write(' · Ends ${DateFormat.yMMMd().format(endDate)}');
  }
  return buffer.toString();
}

String _formatUntil(DateTime date) {
  final utc = DateTime(date.year, date.month, date.day, 23, 59, 59).toUtc();
  final formatter = DateFormat("yyyyMMdd'T'HHmmss'Z'");
  return formatter.format(utc);
}

RecurrencePreset presetFromRule(String? rule) {
  if (rule == null || rule.isEmpty) return RecurrencePreset.none;
  final normalized = rule.toUpperCase();
  if (normalized.contains('FREQ=DAILY') && !normalized.contains('BYDAY=MO,TU,WE,TH,FR')) {
    return RecurrencePreset.daily;
  }
  if (normalized.contains('FREQ=WEEKLY') && normalized.contains('BYDAY=MO,TU,WE,TH,FR')) {
    return RecurrencePreset.weekdays;
  }
  if (normalized.contains('FREQ=WEEKLY')) {
    return RecurrencePreset.weekly;
  }
  if (normalized.contains('FREQ=MONTHLY')) {
    return RecurrencePreset.monthly;
  }
  return RecurrencePreset.custom;
}

bool isValidRecurrenceRule(String? rule) {
  if (rule == null || rule.isEmpty) {
    debugPrint('Rule is null or empty - considered valid');
    return true;
  }
  
  String normalizedRule = rule.trim();
  if (!normalizedRule.startsWith('RRULE:')) {
    normalizedRule = 'RRULE:$normalizedRule';
  }
  
  debugPrint('Validating rule: "$normalizedRule"');
  try {
    final parsed = RecurrenceRule.fromString(normalizedRule);
    debugPrint('Successfully parsed rule: $parsed');
    return true;
  } catch (e, stackTrace) {
    debugPrint('Error parsing rule: $e');
    return false;
  }
}