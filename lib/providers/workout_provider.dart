import 'dart:async';
import 'package:flutter/material.dart';
import '../models/exercise_set.dart';
import '../models/training_session.dart';
import '../models/workout_config.dart';
import '../services/storage_service.dart';
import '../services/workout_service.dart';
import '../core/utils/haptic_utils.dart';

class WorkoutProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();

  List<TrainingSession> _sessions = [];
  WorkoutConfig _config = WorkoutConfig.defaultConfig();
  
  // -- Active Session State --
  bool _isSessionActive = false;
  String _activeWorkoutType = '';
  List<ExerciseSet> _currentSessionExercises = [];
  String _selectedExercise = '';
  
  // -- Timer State --
  Timer? _restTimer;
  int _secondsLeft = 0;
  bool _showTimer = false;
  DateTime? _timerEndTime;

  // -- Getters --
  List<TrainingSession> get sessions => _sessions;
  WorkoutConfig get config => _config;
  bool get isSessionActive => _isSessionActive;
  String get activeWorkoutType => _activeWorkoutType;
  List<ExerciseSet> get currentSessionExercises => _currentSessionExercises;
  String get selectedExercise => _selectedExercise;
  int get secondsLeft => _secondsLeft;
  bool get showTimer => _showTimer;

  WorkoutProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    await _storage.init();
    _sessions = _storage.loadSessions();
    _config = _storage.loadConfig();
    _checkRunningTimer();
    notifyListeners();
  }

  void _checkRunningTimer() {
    final prefs = _storage.prefs; // Acceder a SharedPreferences via StorageService
    final endTimeStr = prefs.getString('timer_end_time');
    if (endTimeStr != null) {
      final endTime = DateTime.parse(endTimeStr);
      final diff = endTime.difference(DateTime.now()).inSeconds;
      if (diff > 0) {
        _timerEndTime = endTime;
        _secondsLeft = diff;
        _showTimer = true;
        _startTimerLoop();
      } else {
        prefs.remove('timer_end_time');
      }
    }
  }

  // --- Session Management ---
  void startWorkout(String type) {
    if (!_config.exerciseDb.containsKey(type)) return;
    
    _activeWorkoutType = type;
    _currentSessionExercises = [];
    _isSessionActive = true;
    
    final exercises = _config.exerciseDb[type];
    if (exercises != null && exercises.isNotEmpty) {
      _selectedExercise = exercises[0];
    } else {
      _selectedExercise = '';
    }
    
    notifyListeners();
  }

  void finishWorkout() {
    _restTimer?.cancel();
    if (_currentSessionExercises.isNotEmpty) {
      final session = TrainingSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: _activeWorkoutType,
        exercises: List.from(_currentSessionExercises),
        date: _currentSessionExercises.last.date,
        endDate: DateTime.now(),
      );
      _sessions.insert(0, session);
      _storage.saveSessions(_sessions);
    }
    _isSessionActive = false;
    _activeWorkoutType = '';
    _currentSessionExercises = [];
    _showTimer = false;
    notifyListeners();
  }

  void cancelWorkout() {
    _restTimer?.cancel();
    _isSessionActive = false;
    _activeWorkoutType = '';
    _currentSessionExercises = [];
    _showTimer = false;
    notifyListeners();
  }

  void deleteSession(String sessionId) {
    _sessions.removeWhere((s) => s.id == sessionId);
    _storage.saveSessions(_sessions);
    notifyListeners();
  }

  void addSet(String name, double weight, double reps, String note) {
    final now = DateTime.now();
    final newSet = ExerciseSet(
      name: name.toUpperCase(),
      weight: weight,
      reps: reps,
      note: note,
      time: "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}",
      date: now,
    );

    _currentSessionExercises.insert(0, newSet);
    
    // Check if it's a new PB
    final pb = WorkoutService.getPB(_sessions, name);
    if (pb == null || newSet.calculateScore() > pb.calculateScore()) {
      HapticUtils.recordCelebration();
    } else {
      HapticUtils.light();
    }

    startRestTimer();
    notifyListeners();
  }

  void setSelectedExercise(String ex) {
    _selectedExercise = ex;
    notifyListeners();
  }

  // --- Timer logic ---
  void startRestTimer({int? customSeconds}) {
    _restTimer?.cancel();
    final duration = customSeconds ?? _config.defaultRestSeconds;
    _secondsLeft = duration;
    _showTimer = true;
    _timerEndTime = DateTime.now().add(Duration(seconds: duration));
    _storage.prefs.setString('timer_end_time', _timerEndTime!.toIso8601String());
    
    _startTimerLoop();
    notifyListeners();
  }

  void _startTimerLoop() {
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        _secondsLeft--;
        notifyListeners();
      } else {
        _restTimer?.cancel();
        _showTimer = false;
        _storage.prefs.remove('timer_end_time');
        HapticUtils.timerFinish();
        notifyListeners();
      }
    });
  }

  void stopTimer() {
    _restTimer?.cancel();
    _showTimer = false;
    _storage.prefs.remove('timer_end_time');
    notifyListeners();
  }

  // --- Config Updates ---
  void updateConfig(WorkoutConfig newConfig) {
    _config = newConfig;
    _storage.saveConfig(_config);
    notifyListeners();
  }

  void deleteExercise(String group, String exercise) {
    final newDb = Map<String, List<String>>.from(_config.exerciseDb);
    final newArchived = Map<String, List<String>>.from(_config.archivedExercises);
    
    newDb[group]?.remove(exercise);
    newArchived[group]?.remove(exercise);
    
    updateConfig(_config.copyWith(exerciseDb: newDb, archivedExercises: newArchived));
  }

  // --- Helpers ---
  ExerciseSet? getPB(String exerciseName) => WorkoutService.getPB(_sessions, exerciseName);
  ExerciseSet? getLastTime(String exerciseName) => WorkoutService.getLastTime(_sessions, exerciseName);
  Map<String, String> getSuggestion() => WorkoutService.getSuggestion(_sessions, _config);
}
