import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.taskReminders = true,
    this.focusAlerts = true,
    this.digestEmails = false,
    this.launchAtStartup = true,
    this.launchMinimized = false,
    this.pomodoroEnabled = false,
    this.workDuration = 25.0,
    this.breakDuration = 5.0,
    this.ambientSounds = true,
    this.selectedSound = 'Rain',
    this.notificationChimes = true,
  });

  final ThemeMode themeMode;
  final bool taskReminders;
  final bool focusAlerts;
  final bool digestEmails;
  final bool launchAtStartup;
  final bool launchMinimized;
  final bool pomodoroEnabled;
  final double workDuration;
  final double breakDuration;
  final bool ambientSounds;
  final String selectedSound;
  final bool notificationChimes;

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? taskReminders,
    bool? focusAlerts,
    bool? digestEmails,
    bool? launchAtStartup,
    bool? launchMinimized,
    bool? pomodoroEnabled,
    double? workDuration,
    double? breakDuration,
    bool? ambientSounds,
    String? selectedSound,
    bool? notificationChimes,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      taskReminders: taskReminders ?? this.taskReminders,
      focusAlerts: focusAlerts ?? this.focusAlerts,
      digestEmails: digestEmails ?? this.digestEmails,
      launchAtStartup: launchAtStartup ?? this.launchAtStartup,
      launchMinimized: launchMinimized ?? this.launchMinimized,
      pomodoroEnabled: pomodoroEnabled ?? this.pomodoroEnabled,
      workDuration: workDuration ?? this.workDuration,
      breakDuration: breakDuration ?? this.breakDuration,
      ambientSounds: ambientSounds ?? this.ambientSounds,
      selectedSound: selectedSound ?? this.selectedSound,
      notificationChimes: notificationChimes ?? this.notificationChimes,
    );
  }

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.index,
    'taskReminders': taskReminders,
    'focusAlerts': focusAlerts,
    'digestEmails': digestEmails,
    'launchAtStartup': launchAtStartup,
    'launchMinimized': launchMinimized,
    'pomodoroEnabled': pomodoroEnabled,
    'workDuration': workDuration,
    'breakDuration': breakDuration,
    'ambientSounds': ambientSounds,
    'selectedSound': selectedSound,
    'notificationChimes': notificationChimes,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    themeMode: ThemeMode.values[json['themeMode'] ?? ThemeMode.system.index],
    taskReminders: json['taskReminders'] ?? true,
    focusAlerts: json['focusAlerts'] ?? true,
    digestEmails: json['digestEmails'] ?? false,
    launchAtStartup: json['launchAtStartup'] ?? true,
    launchMinimized: json['launchMinimized'] ?? false,
    pomodoroEnabled: json['pomodoroEnabled'] ?? false,
    workDuration: json['workDuration'] ?? 25.0,
    breakDuration: json['breakDuration'] ?? 5.0,
    ambientSounds: json['ambientSounds'] ?? true,
    selectedSound: json['selectedSound'] ?? 'Rain',
    notificationChimes: json['notificationChimes'] ?? true,
  );
}

class SettingsController extends StateNotifier<AppSettings> {
  static const String _themeModeKey = 'theme_mode';
  static const String _taskRemindersKey = 'task_reminders';
  static const String _focusAlertsKey = 'focus_alerts';
  static const String _digestEmailsKey = 'digest_emails';
  static const String _launchAtStartupKey = 'launch_at_startup';
  static const String _launchMinimizedKey = 'launch_minimized';
  static const String _pomodoroEnabledKey = 'pomodoro_enabled';
  static const String _workDurationKey = 'work_duration';
  static const String _breakDurationKey = 'break_duration';
  static const String _ambientSoundsKey = 'ambient_sounds';
  static const String _selectedSoundKey = 'selected_sound';
  static const String _notificationChimesKey = 'notification_chimes';

  SettingsController() : super(const AppSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeModeKey) ?? ThemeMode.system.index;
    state = state.copyWith(
      themeMode: ThemeMode.values[themeIndex],
      taskReminders: prefs.getBool(_taskRemindersKey) ?? true,
      focusAlerts: prefs.getBool(_focusAlertsKey) ?? true,
      digestEmails: prefs.getBool(_digestEmailsKey) ?? false,
      launchAtStartup: prefs.getBool(_launchAtStartupKey) ?? true,
      launchMinimized: prefs.getBool(_launchMinimizedKey) ?? false,
      pomodoroEnabled: prefs.getBool(_pomodoroEnabledKey) ?? false,
      workDuration: prefs.getDouble(_workDurationKey) ?? 25.0,
      breakDuration: prefs.getDouble(_breakDurationKey) ?? 5.0,
      ambientSounds: prefs.getBool(_ambientSoundsKey) ?? true,
      selectedSound: prefs.getString(_selectedSoundKey) ?? 'Rain',
      notificationChimes: prefs.getBool(_notificationChimesKey) ?? true,
    );

    if (!kIsWeb) {
      try {
        final actualEnabled = await launchAtStartup.isEnabled();
        if (state.launchAtStartup != actualEnabled) {
          state = state.copyWith(launchAtStartup: actualEnabled);
          await prefs.setBool(_launchAtStartupKey, actualEnabled);
        }
      } catch (e) {
        debugPrint('Failed to check launch at startup: $e');
      }
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, state.themeMode.index);
    await prefs.setBool(_taskRemindersKey, state.taskReminders);
    await prefs.setBool(_focusAlertsKey, state.focusAlerts);
    await prefs.setBool(_digestEmailsKey, state.digestEmails);
    await prefs.setBool(_launchAtStartupKey, state.launchAtStartup);
    await prefs.setBool(_launchMinimizedKey, state.launchMinimized);
    await prefs.setBool(_pomodoroEnabledKey, state.pomodoroEnabled);
    await prefs.setDouble(_workDurationKey, state.workDuration);
    await prefs.setDouble(_breakDurationKey, state.breakDuration);
    await prefs.setBool(_ambientSoundsKey, state.ambientSounds);
    await prefs.setString(_selectedSoundKey, state.selectedSound);
    await prefs.setBool(_notificationChimesKey, state.notificationChimes);
  }

  void updateThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _saveSettings();
  }

  void updateTaskReminders(bool value) {
    state = state.copyWith(taskReminders: value);
    _saveSettings();
  }

  void updateFocusAlerts(bool value) {
    state = state.copyWith(focusAlerts: value);
    _saveSettings();
  }

  void updateDigestEmails(bool value) {
    state = state.copyWith(digestEmails: value);
    _saveSettings();
  }

  Future<void> updateLaunchAtStartup(bool value) async {
    state = state.copyWith(launchAtStartup: value);
    await _saveSettings();

    if (!kIsWeb) {
      try {
        if (value) {
          await launchAtStartup.enable();
        } else {
          await launchAtStartup.disable();
        }
      } catch (e) {
        debugPrint('Failed to update launch at startup: $e');
        // Optionally revert state
        // state = state.copyWith(launchAtStartup: !value);
      }
    }
  }

  void updateLaunchMinimized(bool value) {
    state = state.copyWith(launchMinimized: value);
    _saveSettings();
  }

  void updatePomodoroEnabled(bool value) {
    state = state.copyWith(pomodoroEnabled: value);
    _saveSettings();
  }

  void updateWorkDuration(double value) {
    state = state.copyWith(workDuration: value);
    _saveSettings();
  }

  void updateBreakDuration(double value) {
    state = state.copyWith(breakDuration: value);
    _saveSettings();
  }

  void updateAmbientSounds(bool value) {
    state = state.copyWith(ambientSounds: value);
    _saveSettings();
  }

  void updateSelectedSound(String value) {
    state = state.copyWith(selectedSound: value);
    _saveSettings();
  }

  void updateNotificationChimes(bool value) {
    state = state.copyWith(notificationChimes: value);
    _saveSettings();
  }
}
