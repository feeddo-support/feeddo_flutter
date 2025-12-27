import 'package:flutter/material.dart';

class FeeddoColors {
  final Color background;
  final List<Color>? backgroundGradient;
  final List<double>? backgroundGradientStops;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardBackground;
  final Color cardText;
  final Color iconColor;
  final Color closeButtonColor;
  final Color primary;
  final Color surface;
  final Color success;
  final Color error;
  final Color border;
  final Color divider;
  final Color appBarBackground;

  const FeeddoColors({
    this.background = const Color(0xFF000000),
    this.backgroundGradient,
    this.backgroundGradientStops,
    this.textPrimary = const Color(0xFFFFFFFF),
    this.textSecondary = const Color(0xFFB3B3B3),
    this.cardBackground = const Color(0xFFFFFFFF),
    this.cardText = const Color(0xFF000000),
    this.iconColor = const Color(0xFF000000),
    this.closeButtonColor = const Color(0xFFFFFFFF),
    this.primary = const Color(0xFF2196F3),
    this.surface = const Color(0xFFFFFFFF),
    this.success = const Color(0xFF4CAF50),
    this.error = const Color(0xFFF44336),
    this.border = const Color(0xFFE0E0E0),
    this.divider = const Color(0xFFBDBDBD),
    this.appBarBackground = const Color(0xFF000000),
  });

  FeeddoColors copyWith({
    Color? background,
    List<Color>? backgroundGradient,
    List<double>? backgroundGradientStops,
    Color? textPrimary,
    Color? textSecondary,
    Color? cardBackground,
    Color? cardText,
    Color? iconColor,
    Color? closeButtonColor,
    Color? primary,
    Color? surface,
    Color? success,
    Color? error,
    Color? border,
    Color? divider,
    Color? appBarBackground,
  }) {
    return FeeddoColors(
        background: background ?? this.background,
        backgroundGradient: backgroundGradient ?? this.backgroundGradient,
        backgroundGradientStops:
            backgroundGradientStops ?? this.backgroundGradientStops,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        cardBackground: cardBackground ?? this.cardBackground,
        cardText: cardText ?? this.cardText,
        iconColor: iconColor ?? this.iconColor,
        closeButtonColor: closeButtonColor ?? this.closeButtonColor,
        primary: primary ?? this.primary,
        surface: surface ?? this.surface,
        success: success ?? this.success,
        error: error ?? this.error,
        border: border ?? this.border,
        divider: divider ?? this.divider,
        appBarBackground: appBarBackground ?? this.appBarBackground);
  }
}

class FeeddoTheme {
  final FeeddoColors colors;
  final bool isDark;

  const FeeddoTheme({
    required this.colors,
    this.isDark = true,
  });

  factory FeeddoTheme.dark() {
    return const FeeddoTheme(
      colors: FeeddoColors(
        background: Color(0xFF09090B),
        backgroundGradient: null,
        backgroundGradientStops: null,
        textPrimary: Color(0xFFFAFAFA),
        textSecondary: Color(0xFFA1A1AA),
        cardBackground: Color(0xFF18181B),
        cardText: Color(0xFFFAFAFA),
        iconColor: Color(0xFFA1A1AA),
        closeButtonColor: Color(0xFFFAFAFA),
        primary: Color(0xFFFFFFFF),
        surface: Color(0xFF18181B),
        success: Color(0xFF22C55E),
        error: Color(0xFFEF4444),
        border: Color(0xFF27272A),
        divider: Color.fromARGB(255, 26, 26, 26),
        appBarBackground: Color.fromARGB(255, 0, 0, 0),
      ),
      isDark: true,
    );
  }
  factory FeeddoTheme.light() {
    return const FeeddoTheme(
      colors: FeeddoColors(
        background: Color.fromARGB(255, 251, 251, 251),
        backgroundGradient: null,
        backgroundGradientStops: null,
        textPrimary: Color(0xFF111827),
        textSecondary: Color(0xFF4B5563),
        cardBackground: Color(0xFFFFFFFF),
        cardText: Color(0xFF111827),
        iconColor: Color(0xFF4B5563),
        closeButtonColor: Color(0xFF111827),
        primary: Color.fromARGB(255, 0, 0, 0),
        surface: Color(0xFFFFFFFF),
        success: Color(0xFF10B981),
        error: Color(0xFFEF4444),
        border: Color(0xFFE5E7EB),
        divider: Color(0xFFE5E7EB),
        appBarBackground: Color.fromARGB(255, 255, 255, 255),
      ),
      isDark: false,
    );
  }
}
