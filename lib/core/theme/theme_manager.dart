import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import 'app_theme.dart';

class ThemeManager extends ChangeNotifier {
  AppTheme _currentTheme = AppTheme.deepSlate;

  AppTheme get currentTheme => _currentTheme;
  ThemeData get themeData => AppThemes.getTheme(_currentTheme);
  Color get accentColor => AppThemes.getAccentColor(_currentTheme);
  Color get cardColor => AppThemes.getCardColor(_currentTheme);
  
  // Basado en el locale de la app, pero aquí lo simplificamos a una propiedad
  bool _isRTL = false;
  bool get isRTL => _isRTL;

  void updateRTL(String languageCode) {
    _isRTL = languageCode == 'ar';
    notifyListeners();
  }

  ThemeManager() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(AppConstants.keyTheme);
    if (themeIndex != null && themeIndex < AppTheme.values.length) {
      _currentTheme = AppTheme.values[themeIndex];
      notifyListeners();
    }
  }

  Future<void> cycleTheme() async {
    _currentTheme = AppTheme.values[(_currentTheme.index + 1) % AppTheme.values.length];
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keyTheme, _currentTheme.index);
  }

  Future<void> setTheme(AppTheme theme) async {
    _currentTheme = theme;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keyTheme, theme.index);
  }
}
