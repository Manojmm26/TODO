import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_sections.dart';
import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/focus/presentation/focus_page.dart';
import '../features/goals/presentation/goals_page.dart';
import '../features/settings/presentation/settings_page.dart';
import '../features/shell/presentation/chronos_shell.dart';
import '../features/timeline/presentation/timeline_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: dashboardRoute,
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            ChronosShell(state: state, child: child),
        routes: [
          GoRoute(
            path: dashboardRoute,
            name: 'dashboard',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DashboardPage()),
          ),
          GoRoute(
            path: timelineRoute,
            name: 'timeline',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: TimelinePage()),
          ),
          GoRoute(
            path: goalsRoute,
            name: 'goals',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: GoalsPage()),
          ),
          GoRoute(
            path: focusRoute,
            name: 'focus',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: FocusPage()),
          ),
          GoRoute(
            path: settingsRoute,
            name: 'settings',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SettingsPage()),
          ),
        ],
      ),
    ],
  );
});
