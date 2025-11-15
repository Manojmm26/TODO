import 'package:flutter/material.dart';

class ChronosSection {
  const ChronosSection({
    required this.route,
    required this.label,
    required this.icon,
    required this.description,
  });

  final String route;
  final String label;
  final IconData icon;
  final String description;
}

const dashboardRoute = '/dashboard';
const timelineRoute = '/timeline';
const goalsRoute = '/goals';
const focusRoute = '/focus';
const settingsRoute = '/settings';

const chronosSections = <ChronosSection>[
  ChronosSection(
    route: dashboardRoute,
    label: 'Dashboard',
    icon: Icons.dashboard_rounded,
    description: 'Visual overview & digest',
  ),
  ChronosSection(
    route: timelineRoute,
    label: 'Timeline',
    icon: Icons.timeline_rounded,
    description: 'Schedule & upcoming tasks',
  ),
  ChronosSection(
    route: goalsRoute,
    label: 'Goals',
    icon: Icons.flag_rounded,
    description: 'Goal progress & milestones',
  ),
  ChronosSection(
    route: focusRoute,
    label: 'Focus',
    icon: Icons.timer_rounded,
    description: 'Time clock & sessions',
  ),
  ChronosSection(
    route: settingsRoute,
    label: 'Settings',
    icon: Icons.settings_rounded,
    description: 'Preferences & startup options',
  ),
];
