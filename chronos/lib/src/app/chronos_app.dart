import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:window_manager/window_manager.dart';

import '../core/theme/app_theme.dart';
import '../routing/app_router.dart';
import '../application/recurrence_coordinator.dart';

class ChronosApp extends ConsumerStatefulWidget {
  const ChronosApp({super.key});

  @override
  ConsumerState<ChronosApp> createState() => _ChronosAppState();
}

class _ChronosAppState extends ConsumerState<ChronosApp>
    with WindowListener, WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      windowManager.addListener(this);
      WidgetsBinding.instance.addObserver(this);
      debugPrint('🪟 WindowListener + WidgetsBindingObserver registered');
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      windowManager.removeListener(this);
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }

  // Log ALL window events

  @override
  void onWindowMoved() {
    debugPrint('🪟 onWindowMoved');
    _scheduleSaveWindowState();
  }

  @override
  void onWindowResized() {
    debugPrint('🪟 onWindowResized');
    _scheduleSaveWindowState();
  }

  void onWindowMaximized() {
    debugPrint('🪟 onWindowMaximized');
    _scheduleSaveWindowState();
  }

  void onWindowUnmaximized() {
    debugPrint('🪟 onWindowUnmaximized');
    _scheduleSaveWindowState();
  }

  void onWindowMinimized() {
    debugPrint('🪟 onWindowMinimized');
  }

  void onWindowRestored() {
    debugPrint('🪟 onWindowRestored');
  }

  void onWindowEnteredFullScreen() {
    debugPrint('🪟 onWindowEnteredFullScreen');
  }

  void onWindowExitedFullScreen() {
    debugPrint('🪟 onWindowExitedFullScreen');
  }

  @override
  void onWindowClose() {
    debugPrint('🪟 onWindowClose() called');
    _saveWindowState();
    super.onWindowClose();
  }

  /// Debounce frequent window events so we don't hammer preferences.
  Timer? _saveStateTimer;

  void _scheduleSaveWindowState([int milliseconds = 300]) {
    _saveStateTimer?.cancel();
    _saveStateTimer = Timer(Duration(milliseconds: milliseconds), () {
      _saveWindowState();
    });
  }

  Future<void> _saveWindowState() async {
    if (!kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final size = await windowManager.getSize();
      final pos = await windowManager.getPosition();

      debugPrint(
        '🚪 SAVING window: ${size.width}x${size.height} @ ${pos.dx},${pos.dy}',
      );

      await prefs.setDouble('window_width', size.width);
      await prefs.setDouble('window_height', size.height);
      await prefs.setDouble('window_x', pos.dx);
      final isMax = await windowManager.isMaximized();
      await prefs.setBool('window_is_maximized', isMax);
      await prefs.setDouble('window_y', pos.dy);

      final savedW = prefs.getDouble('window_width');
      final savedH = prefs.getDouble('window_height');
      debugPrint('💾 SAVED: ${savedW}x$savedH');
      final savedMax = prefs.getBool('window_is_maximized');
      debugPrint('💾 Window maximized: ${savedMax ?? false}');
      debugPrint('✅ Window state saved!');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('📱 AppLifecycleState: $state');
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(appRouterProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final recurrence = ref.read(recurrenceCoordinatorProvider);
      recurrence.bootstrap().catchError((error) {
        debugPrint('Error initializing recurrence: $error');
      });
    });

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
