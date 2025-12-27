import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/training_session.dart';
import '../models/workout_config.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get prefs => _prefs;

  // --- Sessions ---
  Future<void> saveSessions(List<TrainingSession> sessions) async {
    final List<String> sessionsJson = sessions.map((s) => jsonEncode(s.toJson())).toList();
    await _prefs.setStringList(AppConstants.keySessions, sessionsJson);
  }

  List<TrainingSession> loadSessions() {
    final List<String>? sessionsJson = _prefs.getStringList(AppConstants.keySessions);
    if (sessionsJson == null) return [];
    return sessionsJson.map((s) => TrainingSession.fromJson(jsonDecode(s))).toList();
  }

  // --- Config ---
  Future<void> saveConfig(WorkoutConfig config) async {
    await _prefs.setString(AppConstants.keyConfig, jsonEncode(config.toJson()));
  }

  WorkoutConfig loadConfig() {
    final String? configJson = _prefs.getString(AppConstants.keyConfig);
    if (configJson == null) return WorkoutConfig.defaultConfig();
    return WorkoutConfig.fromJson(jsonDecode(configJson));
  }

  // --- Backup & Export (Stubs for now) ---
  String exportToJson(List<TrainingSession> sessions, WorkoutConfig config) {
    return jsonEncode({
      'sessions': sessions.map((s) => s.toJson()).toList(),
      'config': config.toJson(),
    });
  }
}
