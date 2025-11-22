import 'dart:io';

import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

class SystemTrayService with TrayListener, WindowListener {
  static final SystemTrayService _instance = SystemTrayService._internal();

  factory SystemTrayService() {
    return _instance;
  }

  SystemTrayService._internal();

  Future<void> init() async {
    await trayManager.setIcon(
      Platform.isWindows
          ? 'windows/runner/resources/app_icon.ico'
          : 'assets/app_icon.png', // Fallback/placeholder for other OS if needed
    );

    Menu menu = Menu(
      items: [
        MenuItem(key: 'show_window', label: 'Show'),
        MenuItem(key: 'hide_window', label: 'Hide'),
        MenuItem.separator(),
        MenuItem(key: 'exit_app', label: 'Exit'),
      ],
    );

    await trayManager.setContextMenu(menu);
    trayManager.addListener(this);
    windowManager.addListener(this);
  }

  @override
  void onTrayIconMouseDown() {
    // Toggle window visibility on click
    windowManager.isVisible().then((isVisible) {
      if (isVisible) {
        windowManager.hide();
      } else {
        windowManager.show();
        windowManager.focus();
      }
    });
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show_window':
        windowManager.show();
        windowManager.focus();
        break;
      case 'hide_window':
        windowManager.hide();
        break;
      case 'exit_app':
        windowManager.destroy();
        break;
    }
  }

  void dispose() {
    trayManager.removeListener(this);
    windowManager.removeListener(this);
  }

  @override
  void onWindowClose() {
    windowManager.hide();
  }

  @override
  void onWindowMinimize() {
    windowManager.hide();
  }
}
