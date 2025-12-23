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
    );
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
        backgroundGradient: [
          Color(0xFF000000),
          Color(0xFF000000),
          Color(0xFFFFFFFF),
          Color(0xFFFFFFFF),
        ],
        backgroundGradientStops: [0.0, 0.3, 0.7, 1.0],
        textPrimary: Color(0xFFFFFFFF),
        textSecondary: Color(0xFFB3B3B3),
        cardBackground: Color(0xFFFFFFFF),
        cardText: Color(0xFF000000),
        iconColor: Color(0xFF000000),
        closeButtonColor: Color(0xFFFFFFFF),
        primary: Color(0xFF2196F3),
        surface: Color(0xFFFFFFFF),
        success: Color(0xFF4CAF50),
        error: Color(0xFFF44336),
        border: Color(0xFFE0E0E0),
      ),
      isDark: true,
    );
  }

  factory FeeddoTheme.light() {
    return const FeeddoTheme(
      colors: FeeddoColors(
        backgroundGradient: [
          Color(0xFF000000),
          Color(0xFF000000),
          Color(0xFFFFFFFF),
          Color(0xFFFFFFFF),
        ],
        backgroundGradientStops: [0.0, 0.3, 0.7, 1.0],
        textPrimary: Color(0xFFFFFFFF),
        textSecondary: Color(0xFFB3B3B3),
        cardBackground: Color(0xFFFFFFFF),
        cardText: Color(0xFF000000),
        iconColor: Color(0xFF000000),
        closeButtonColor: Color(0xFFFFFFFF),
        primary: Color(0xFF2196F3),
        surface: Color(0xFFFFFFFF),
        success: Color(0xFF4CAF50),
        error: Color(0xFFF44336),
        border: Color(0xFFE0E0E0),
      ),
      isDark: false,
    );
  }
}
