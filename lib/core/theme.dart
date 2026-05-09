import 'package:flutter/material.dart';

/// Color palette theo UI Design System.
class AppColors {
  AppColors._();

  // Primary
  static const primary = Color(0xFF2563EB);
  static const primaryLight = Color(0xFFDBEAFE);
  static const primaryDark = Color(0xFF1D4ED8);

  // Pronunciation feedback
  static const correct = Color(0xFF16A34A);
  static const needsWork = Color(0xFFCA8A04);
  static const wrong = Color(0xFFDC2626);
  static const missed = Color(0xFF9CA3AF);

  // Background
  static const background = Color(0xFFF9FAFB);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF3F4F6);

  // Text
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textOnPrimary = Color(0xFFFFFFFF);

  // Semantic
  static const error = Color(0xFFDC2626);
  static const success = Color(0xFF16A34A);
}

/// Typography theo UI Design System.
class AppTypography {
  AppTypography._();

  // Headings
  static const h1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );
  static const h2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
  static const h3 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  // Body
  static const bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  static const bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  static const bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  // Sentence display (for shadowing)
  static const sentence = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    height: 1.6,
  );
  static const sentenceWord = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  // Labels
  static const label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );
  static const button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
}

/// Spacing system theo UI Design System.
class AppSpacing {
  AppSpacing._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

/// Border radius theo UI Design System.
class AppRadius {
  AppRadius._();

  static const sm = BorderRadius.all(Radius.circular(8));
  static const md = BorderRadius.all(Radius.circular(12));
  static const lg = BorderRadius.all(Radius.circular(16));
  static const full = BorderRadius.all(Radius.circular(999));
}
