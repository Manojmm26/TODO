import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

enum AppThemeVariant {
  chronos('Chronos', Color(0xFF6750A4), Color(0xFF00BFA5)),
  nature('Nature', Color(0xFF2E7D32), Color(0xFFAED581)),
  ocean('Ocean', Color(0xFF0277BD), Color(0xFF4FC3F7)),
  sunset('Sunset', Color(0xFFD84315), Color(0xFFFFAB91)),
  midnight('Midnight', Color(0xFF311B92), Color(0xFF7C4DFF)),
  custom('Custom', Colors.grey, Colors.grey);

  final String label;
  final Color seedColor;
  final Color accentColor;

  const AppThemeVariant(this.label, this.seedColor, this.accentColor);
}

class ChronosTheme {
  ChronosTheme._();

  static ThemeData light(AppThemeVariant variant, {Color? customColor}) =>
      _buildTheme(Brightness.light, variant, customColor: customColor);
  static ThemeData dark(AppThemeVariant variant, {Color? customColor}) =>
      _buildTheme(Brightness.dark, variant, customColor: customColor);

  static ThemeData _buildTheme(
    Brightness brightness,
    AppThemeVariant variant, {
    Color? customColor,
  }) {
    final seedColor = variant == AppThemeVariant.custom
        ? (customColor ?? const Color(0xFF6750A4))
        : variant.seedColor;

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
      extensions: [
        CustomColors(
          focusAccent: variant == AppThemeVariant.custom
              ? colorScheme.primary
              : variant.accentColor,
        ),
      ],
    );
  }
}

@immutable
class CustomColors extends ThemeExtension<CustomColors> {
  const CustomColors({required this.focusAccent});

  final Color? focusAccent;

  @override
  CustomColors copyWith({Color? focusAccent}) {
    return CustomColors(focusAccent: focusAccent ?? this.focusAccent);
  }

  @override
  CustomColors lerp(ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) {
      return this;
    }
    return CustomColors(
      focusAccent: Color.lerp(focusAccent, other.focusAccent, t),
    );
  }
}
