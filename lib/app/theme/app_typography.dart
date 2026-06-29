import 'package:flutter/material.dart';

class AppTypography {
  const AppTypography._();

  static TextTheme textTheme(ColorScheme colorScheme) {
    return TextTheme(
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.5,
        color: colorScheme.onSurface,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.45,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
