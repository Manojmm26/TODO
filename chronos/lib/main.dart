import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'src/app/chronos_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    // Launch at startup
    launchAtStartup.setup(
      appName: 'Chronos',
      appPath: Platform.resolvedExecutable,
    );

    // Window manager setup & restore
    await windowManager.ensureInitialized();
    final prefs = await SharedPreferences.getInstance();
    final width = prefs.getDouble('window_width') ?? 1200.0;
    final height = prefs.getDouble('window_height') ?? 800.0;
    final x = prefs.getDouble('window_x') ?? 100.0;
    final y = prefs.getDouble('window_y') ?? 100.0;

    debugPrint('📐 LOADING window: ${width}x${height} @ ${x},${y}');

    await windowManager.setSize(Size(width, height));
    await windowManager.setPosition(Offset(x, y));
    await windowManager.show();
    final isMax = prefs.getBool('window_is_maximized') ?? false;
    if (isMax) {
      await windowManager.maximize();
      debugPrint('✅ Window maximized on startup');
    }
    debugPrint('✅ Window restored');
  }

  runApp(const ProviderScope(child: ChronosApp()));
}
