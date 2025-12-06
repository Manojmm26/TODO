import 'dart:convert';
import 'dart:io';
import 'package:chronos/src/core/theme/app_theme.dart';

import 'widgets/custom_color_picker.dart';
import 'recurring_templates_page.dart';
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
        const SizedBox(height: 24),
        SectionCard(
          title: 'Recurring Tasks',
          subtitle: 'Manage your recurring task templates',
          child: ListTile(
            leading: const Icon(Icons.repeat_rounded),
            title: const Text('Manage Templates'),
            subtitle: const Text('View, edit, or delete recurring patterns'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const RecurringTemplatesPage(),
              ),
            ),
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
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Theme Mode', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        ...ThemeMode.values.map((mode) {
          return RadioListTile<ThemeMode>(
            value: mode,
            groupValue: settings.themeMode,
            onChanged: (value) =>
                ref.read(settingsProvider.notifier).updateThemeMode(value!),
            title: Text(mode.name.toUpperCase()),
            subtitle: Text(_labelForMode(mode)),
            contentPadding: EdgeInsets.zero,
          );
        }),
        const SizedBox(height: 24),
        Text('Color Theme', style: theme.textTheme.labelLarge),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: AppThemeVariant.values.map((variant) {
            final isSelected = settings.themeVariant == variant;
            return InkWell(
              onTap: () => ref
                  .read(settingsProvider.notifier)
                  .updateThemeVariant(variant),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 100,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.dividerColor.withValues(alpha: 0.2),
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: isSelected
                      ? theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.2,
                        )
                      : null,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: variant.seedColor,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: variant.seedColor.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: variant.accentColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      variant.label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: isSelected ? FontWeight.bold : null,
                        color: isSelected ? theme.colorScheme.primary : null,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (settings.themeVariant == AppThemeVariant.custom) ...[
          const SizedBox(height: 32),
          Center(
            child: HueRingPicker(
              color: Color(settings.customThemeColorValue),
              onColorChanged: (color) {
                ref
                    .read(settingsProvider.notifier)
                    .updateCustomThemeColor(color.value);
              },
            ),
          ),
        ],
      ],
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
