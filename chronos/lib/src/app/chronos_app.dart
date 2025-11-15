import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../routing/app_router.dart';

class ChronosApp extends ConsumerWidget {
  const ChronosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Chronos',
      debugShowCheckedModeBanner: false,
      theme: ChronosTheme.light,
      darkTheme: ChronosTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
