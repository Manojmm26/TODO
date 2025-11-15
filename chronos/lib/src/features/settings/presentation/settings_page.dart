import 'package:flutter/material.dart';

import '../../../shared/widgets/section_card.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: const [
        SectionCard(
          title: 'Appearance',
          subtitle: 'Toggle light/dark & accents',
          child: _AppearanceSettings(),
        ),
        SizedBox(height: 24),
        SectionCard(
          title: 'Notifications',
          subtitle: 'Desktop reminders & focus alerts',
          child: _NotificationSettings(),
        ),
        SizedBox(height: 24),
        SectionCard(
          title: 'System Integration',
          subtitle: 'Startup behavior & data storage',
          child: _SystemSettings(),
        ),
      ],
    );
  }
}

class _AppearanceSettings extends StatefulWidget {
  const _AppearanceSettings();

  @override
  State<_AppearanceSettings> createState() => _AppearanceSettingsState();
}

class _AppearanceSettingsState extends State<_AppearanceSettings> {
  ThemeMode _mode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: ThemeMode.values.map((mode) {
        return RadioListTile<ThemeMode>(
          value: mode,
          groupValue: _mode,
          onChanged: (value) =>
              setState(() => _mode = value ?? ThemeMode.system),
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

class _NotificationSettings extends StatefulWidget {
  const _NotificationSettings();

  @override
  State<_NotificationSettings> createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<_NotificationSettings> {
  bool _taskReminders = true;
  bool _focusAlerts = true;
  bool _digestEmails = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile.adaptive(
          value: _taskReminders,
          onChanged: (value) => setState(() => _taskReminders = value),
          title: const Text('Task reminders'),
          subtitle: const Text('Native desktop notifications before due time'),
        ),
        SwitchListTile.adaptive(
          value: _focusAlerts,
          onChanged: (value) => setState(() => _focusAlerts = value),
          title: const Text('Focus session alerts'),
          subtitle: const Text('Break + resume prompts during time clock'),
        ),
        SwitchListTile.adaptive(
          value: _digestEmails,
          onChanged: (value) => setState(() => _digestEmails = value),
          title: const Text('Weekly digest email'),
          subtitle: const Text('Send a summary of goals & time insights'),
        ),
      ],
    );
  }
}

class _SystemSettings extends StatefulWidget {
  const _SystemSettings();

  @override
  State<_SystemSettings> createState() => _SystemSettingsState();
}

class _SystemSettingsState extends State<_SystemSettings> {
  bool _launchAtStartup = true;
  bool _launchMinimized = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile.adaptive(
          value: _launchAtStartup,
          onChanged: (value) => setState(() => _launchAtStartup = value),
          title: const Text('Launch Chronos when Windows starts'),
          subtitle: const Text('Requires launch_at_startup integration'),
        ),
        SwitchListTile.adaptive(
          value: _launchMinimized,
          onChanged: (value) => setState(() => _launchMinimized = value),
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
