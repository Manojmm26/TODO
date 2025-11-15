import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

class ChronosTheme {
  ChronosTheme._();

  static const Color seedColor = Color(0xFF6750A4);
  static const Color focusAccent = Color(0xFF00BFA5);

  static ThemeData get light => _buildTheme(Brightness.light);
  static ThemeData get dark => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
    );

    final textTheme = GoogleFonts.interTextTheme(base.textTheme);

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      scaffoldBackgroundColor: brightness == Brightness.dark
          ? const Color(0xFF10121A)
          : const Color(0xFFF7F7FB),
      cardTheme: base.cardTheme.copyWith(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: brightness == Brightness.dark
            ? const Color(0xFF1B1E2A)
            : const Color(0xFFFFFFFF),
      ),
      dividerTheme: base.dividerTheme.copyWith(
        thickness: 1,
        color: colorScheme.outlineVariant,
      ),
    );
  }
}
