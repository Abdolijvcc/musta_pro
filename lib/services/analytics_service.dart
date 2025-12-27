import '../models/training_session.dart';

class AnalyticsService {
  // Generar datos para el heatmap (Ej: {'2023-12-26': 1})
  static Map<DateTime, int> getHeatmapData(List<TrainingSession> sessions) {
    final Map<DateTime, int> data = {};
    for (var session in sessions) {
      final date = DateTime(session.date.year, session.date.month, session.date.day);
      data[date] = (data[date] ?? 0) + 1;
    }
    return data;
  }

  // Calcular la racha actual (streaks)
  static int calculateCurrentStreak(List<TrainingSession> sessions) {
    if (sessions.isEmpty) return 0;
    
    int streak = 0;
    DateTime checkDate = DateTime.now();
    checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day);

    final setDates = sessions.map((s) => DateTime(s.date.year, s.date.month, s.date.day)).toSet();

    while (setDates.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    
    return streak;
  }
}
