import '../models/exercise_set.dart';
import '../models/training_session.dart';
import '../models/workout_config.dart';

class WorkoutService {
  // Calcular récord personal (PR/PB) para un ejercicio
  static ExerciseSet? getPB(List<TrainingSession> sessions, String exerciseName) {
    final String searchName = exerciseName.toUpperCase();
    final allSets = sessions
        .expand((s) => s.exercises)
        .where((e) => e.name == searchName)
        .toList();

    if (allSets.isEmpty) return null;

    return allSets.reduce((a, b) => a.calculateScore() > b.calculateScore() ? a : b);
  }

  // Obtener la última vez que se realizó un ejercicio
  static ExerciseSet? getLastTime(List<TrainingSession> sessions, String exerciseName) {
    final String searchName = exerciseName.toUpperCase();
    for (var session in sessions) {
      for (var exercise in session.exercises) {
        if (exercise.name == searchName) return exercise;
      }
    }
    return null;
  }

  // Obtener sugerencia de rutina según el modo de planificación
  static Map<String, String> getSuggestion(List<TrainingSession> sessions, WorkoutConfig config) {
    if (config.plannerMode == 'calendar') {
      final days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
      final dayName = days[DateTime.now().weekday - 1];
      final task = config.weeklyPlan[dayName] ?? 'DESCANSO';
      return {'type': task, 'reason': 'Hoy es $dayName'};
    } else {
      if (sessions.isEmpty || config.groups.isEmpty) {
        return {
          'type': config.groups.isNotEmpty ? config.groups[0] : 'CREA UNA RUTINA',
          'reason': 'Comienza hoy'
        };
      }
      final lastType = sessions[0].type;
      final lastIdx = config.groups.indexOf(lastType);
      if (lastIdx == -1) return {'type': config.groups[0], 'reason': 'Nueva rutina'};
      final nextIdx = (lastIdx + 1) % config.groups.length;
      return {'type': config.groups[nextIdx], 'reason': 'Siguiente en el ciclo'};
    }
  }

  // Calcular volumen semanal total
  static double calculateWeeklyVolume(List<TrainingSession> sessions) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return sessions
        .where((s) => s.date.isAfter(startOfWeek))
        .fold(0, (sum, s) => sum + s.calculateTotalVolume());
  }
}
