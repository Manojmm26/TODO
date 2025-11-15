import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sections.dart';
import '../../../core/theme/app_theme.dart';

class ChronosShell extends ConsumerWidget {
  const ChronosShell({super.key, required this.state, required this.child});

  final GoRouterState state;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedIndex = chronosSections.indexWhere(
      (section) => state.matchedLocation == section.route,
    );

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            _SidebarNavigation(
              selected: selectedIndex >= 0 ? selectedIndex : 0,
              onSelect: (index) => context.go(chronosSections[index].route),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Column(
                children: [
                  _TopBar(colorScheme: colorScheme),
                  const Divider(height: 1),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarNavigation extends StatelessWidget {
  const _SidebarNavigation({required this.selected, required this.onSelect});

  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    return Container(
      width: 230,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      color: brightness == Brightness.dark
          ? const Color(0xFF0C0F17)
          : const Color(0xFFFBFBFE),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chronos',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: ChronosTheme.focusAccent,
            ),
          ),
          const SizedBox(height: 24),
          ...List.generate(chronosSections.length, (index) {
            final section = chronosSections[index];
            final isSelected = index == selected;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _NavTile(
                section: section,
                isSelected: isSelected,
                onTap: () => onSelect(index),
              ),
            );
          }),
          const Spacer(),
          Text('Focus Sessions', style: theme.textTheme.labelSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: 0.4,
                  minHeight: 6,
                  backgroundColor: theme.dividerColor.withOpacity(.3),
                  valueColor: AlwaysStoppedAnimation(ChronosTheme.focusAccent),
                ),
              ),
              const SizedBox(width: 12),
              Text('2/5', style: theme.textTheme.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.section,
    required this.isSelected,
    required this.onTap,
  });

  final ChronosSection section;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isSelected
              ? ChronosTheme.focusAccent.withOpacity(.15)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              section.icon,
              color: isSelected
                  ? ChronosTheme.focusAccent
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? ChronosTheme.focusAccent
                          : colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    section.description,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      color: theme.scaffoldBackgroundColor,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Quick search across goals, projects, tasks...',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add_rounded),
            label: const Text('Quick Add'),
          ),
        ],
      ),
    );
  }
}
