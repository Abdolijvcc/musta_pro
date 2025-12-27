import 'package:flutter/material.dart';

enum AppTheme { deepSlate, cyberNeon, crimsonBlood, goldRush }

class AppThemes {
  static ThemeData getTheme(AppTheme theme) {
    Color bg;
    Color primary;

    switch (theme) {
      case AppTheme.cyberNeon:
        bg = const Color(0xFF000000);
        primary = const Color(0xFF00F5FF);
        break;
      case AppTheme.crimsonBlood:
        bg = const Color(0xFF1A0B0B);
        primary = const Color(0xFFFF3131);
        break;
      case AppTheme.goldRush:
        bg = const Color(0xFF0F0E08);
        primary = const Color(0xFFFFD700);
        break;
      case AppTheme.deepSlate:
      default:
        bg = const Color(0xFF020617);
        primary = const Color(0xFF2563EB);
    }

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      primaryColor: primary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        background: bg,
        surface: bg.withBlue(bg.blue + 10).withRed(bg.red + 10).withGreen(bg.green + 10),
      ),
      fontFamily: 'Roboto', // Asegúrate de que esté en pubspec o usa GoogleFonts
      expansionTileTheme: const ExpansionTileThemeData(
        shape: Border.fromBorderSide(BorderSide(color: Colors.transparent)),
        collapsedShape: Border.fromBorderSide(BorderSide(color: Colors.transparent)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: bg,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        contentTextStyle: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
        ),
      ),
      cardTheme: CardThemeData(
        color: bg.withOpacity(0.8),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  static Color getAccentColor(AppTheme theme) {
    switch (theme) {
      case AppTheme.cyberNeon: return const Color(0xFF00F5FF);
      case AppTheme.crimsonBlood: return const Color(0xFFFF3131);
      case AppTheme.goldRush: return const Color(0xFFFFD700);
      default: return const Color(0xFF2563EB);
    }
  }

  static Color getCardColor(AppTheme theme) {
    switch (theme) {
      case AppTheme.cyberNeon: return const Color(0xFF121212);
      case AppTheme.crimsonBlood: return const Color(0xFF2A1515);
      case AppTheme.goldRush: return const Color(0xFF1C1B12);
      default: return const Color(0xFF0F172A);
    }
  }
}
