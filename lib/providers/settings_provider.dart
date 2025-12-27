import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/translations.dart';

class SettingsProvider extends ChangeNotifier {
  bool _autoStartTimer = true;
  bool _hapticEnabled = true;
  String _languageCode = 'es';
  bool _hasCompletedOnboarding = false;

  bool get autoStartTimer => _autoStartTimer;
  bool get hapticEnabled => _hapticEnabled;
  String get languageCode => _languageCode;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _autoStartTimer = prefs.getBool('auto_start_timer') ?? true;
    _hapticEnabled = prefs.getBool('haptic_enabled') ?? true;
    _languageCode = prefs.getString('language_code') ?? 'es';
    _hasCompletedOnboarding = prefs.getBool('has_completed_onboarding') ?? false;
    notifyListeners();
  }

  Future<void> setAutoStartTimer(bool value) async {
    _autoStartTimer = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_start_timer', value);
  }

  Future<void> setHapticEnabled(bool value) async {
    _hapticEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('haptic_enabled', value);
  }

  Future<void> setLanguage(String code) async {
    _languageCode = code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', code);
  }

  String translate(String key) => AppTranslations.translate(key, _languageCode);

  Future<void> completeOnboarding() async {
    _hasCompletedOnboarding = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_completed_onboarding', true);
  }
}
