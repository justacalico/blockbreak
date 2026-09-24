import 'package:flutter/material.dart';

/// Locked design tokens. Every color and typeface in the app references
/// these; nothing paints a raw hex outside this file and the painters that
/// read palette ints from content.dart.
class BB {
  static const ink = Color(0xFF14121A);
  static const panel = Color(0xFF1E1A26);
  static const panel2 = Color(0xFF272133);
  static const edge = Color(0xFF3A3248);
  static const cream = Color(0xFFF2EAD8);
  static const dim = Color(0xFF9A92A8);
  static const gold = Color(0xFFF4C531);
  static const leaf = Color(0xFF6FCF6E);
  static const runic = Color(0xFFB48CF2);
  static const crit = Color(0xFFFF8A3C);
  static const danger = Color(0xFFE0455A);

  static const displayFont = 'PressStart2P';
  static const statFont = 'VT323';

  static const display = TextStyle(
    fontFamily: displayFont,
    color: cream,
    fontSize: 12,
    height: 1.5,
  );

  static const displaySm = TextStyle(
    fontFamily: displayFont,
    color: cream,
    fontSize: 9,
    height: 1.4,
  );

  static const stat = TextStyle(
    fontFamily: statFont,
    color: cream,
    fontSize: 22,
    height: 1.0,
  );

  static const statDim = TextStyle(
    fontFamily: statFont,
    color: dim,
    fontSize: 18,
    height: 1.0,
  );

  static const body = TextStyle(
    color: cream,
    fontSize: 14,
    height: 1.35,
  );

  static const bodyDim = TextStyle(
    color: dim,
    fontSize: 13,
    height: 1.3,
  );
}

ThemeData buildTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: BB.ink,
    colorScheme: const ColorScheme.dark(
      surface: BB.panel,
      primary: BB.gold,
      secondary: BB.leaf,
      error: BB.danger,
      onSurface: BB.cream,
      onPrimary: BB.ink,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: BB.cream,
      displayColor: BB.cream,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: BB.panel2,
      contentTextStyle: BB.body,
      behavior: SnackBarBehavior.floating,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: BB.panel,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: BB.panel,
      surfaceTintColor: Colors.transparent,
    ),
  );
}
