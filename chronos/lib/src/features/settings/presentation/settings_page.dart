import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../application/settings_controller.dart';
import '../../../shared/widgets/section_card.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../application/providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        SectionCard(
          title: 'Appearance',
          subtitle: 'Toggle light/dark & accents',
          child: _AppearanceSettings(),
        ),
        const SizedBox(height: 24),
        SectionCard(
          title: 'Notifications',
          subtitle: 'Desktop reminders & focus alerts',
          child: _NotificationSettings(),
        ),
        const SizedBox(height: 24),
        SectionCard(
          title: 'System Integration',
          subtitle: 'Startup behavior & data storage',
          child: _SystemSettings(),
        ),
        const SizedBox(height: 24),
        SectionCard(
          title: 'Data Backup',
          subtitle: 'Export/Import your preferences',
          child: Consumer(
            builder: (context, ref, child) {
              final settings = ref.watch(settingsProvider);
              return Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.download),
                      label: const Text('Export'),
                      onPressed: () async {
                        final result = await FilePicker.platform.saveFile(
                          dialogTitle: 'Save settings.json',
                          fileName: 'chronos-settings.json',
                        );
                        if (result != null) {
                          final file = File(result);
                          await file.writeAsString(
                            json.encode(settings.toJson()),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Settings exported!'),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.upload),
                      label: const Text('Import'),
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['json'],
                        );
                        if (result != null &&
                            result.files.single.path != null) {
                          final file = File(result.files.single.path!);
                          final jsonString = await file.readAsString();
                          final jsonMap =
                              json.decode(jsonString) as Map<String, dynamic>;
                          ref
                              .read(settingsProvider.notifier)
                              .updateSettings(AppSettings.fromJson(jsonMap));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Settings imported!'),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AppearanceSettings extends ConsumerStatefulWidget {
  const _AppearanceSettings();

  @override
  ConsumerState<_AppearanceSettings> createState() =>
      _AppearanceSettingsState();
}

class _AppearanceSettingsState extends ConsumerState<_AppearanceSettings> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    return Column(
      children: ThemeMode.values.map((mode) {
        return RadioListTile<ThemeMode>(
          value: mode,
          groupValue: settings.themeMode,
          onChanged: (value) =>
              ref.read(settingsProvider.notifier).updateThemeMode(value!),
          title: Text(mode.name.toUpperCase()),
          subtitle: Text(_labelForMode(mode)),
        );
      }).toList(),
    );
  }

  String _labelForMode(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'Always use bright Chronos visuals',
    ThemeMode.dark => 'Use the deep focus theme',
    ThemeMode.system => 'Match operating system setting',
  };
}

class _NotificationSettings extends ConsumerStatefulWidget {
  const _NotificationSettings();

  @override
  ConsumerState<_NotificationSettings> createState() =>
      _NotificationSettingsState();
}

class _NotificationSettingsState extends ConsumerState<_NotificationSettings> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    return Column(
      children: [
        SwitchListTile.adaptive(
          value: settings.taskReminders,
          onChanged: (value) =>
              ref.read(settingsProvider.notifier).updateTaskReminders(value),
          title: const Text('Task reminders'),
          subtitle: const Text('Native desktop notifications before due time'),
        ),
        SwitchListTile.adaptive(
          value: settings.focusAlerts,
          onChanged: (value) =>
              ref.read(settingsProvider.notifier).updateFocusAlerts(value),
          title: const Text('Focus session alerts'),
          subtitle: const Text('Break + resume prompts during time clock'),
        ),
        SwitchListTile.adaptive(
          value: settings.digestEmails,
          onChanged: (value) =>
              ref.read(settingsProvider.notifier).updateDigestEmails(value),
          title: const Text('Weekly digest email'),
          subtitle: const Text('Send a summary of goals & time insights'),
        ),
      ],
    );
  }
}

class _SystemSettings extends ConsumerStatefulWidget {
  const _SystemSettings();

  @override
  ConsumerState<_SystemSettings> createState() => _SystemSettingsState();
}

class _SystemSettingsState extends ConsumerState<_SystemSettings> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile.adaptive(
          value: settings.launchAtStartup,
          onChanged: (value) =>
              ref.read(settingsProvider.notifier).updateLaunchAtStartup(value),
          title: const Text('Launch Chronos when Windows starts'),
          subtitle: const Text('Requires launch_at_startup integration'),
        ),
        SwitchListTile.adaptive(
          value: settings.launchMinimized,
          onChanged: (value) =>
              ref.read(settingsProvider.notifier).updateLaunchMinimized(value),
          title: const Text('Start minimized in system tray'),
          subtitle: const Text('Keeps dashboard ready without clutter'),
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Data directory',
            helperText: 'SQLite/Drift storage location',
            prefixIcon: Icon(Icons.folder_rounded),
          ),
        ),
      ],
    );
  }
}
