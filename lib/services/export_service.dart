import '../models/training_session.dart';

class ExportService {
  // Simulación de exportación a CSV
  static String generateCSV(List<TrainingSession> sessions) {
    StringBuffer buffer = StringBuffer();
    buffer.writeln("Fecha,Rutina,Ejercicio,Peso,Reps,Nota");
    
    for (var session in sessions) {
      for (var ex in session.exercises) {
        buffer.writeln("${session.date},${session.type},${ex.name},${ex.weight},${ex.reps},${ex.note}");
      }
    }
    return buffer.toString();
  }
  
  // Nota: Para compartir imágenes reales se requerirían paquetes como 'render' o 'screenshot'
  // y 'share_plus' en el pubspec. Por ahora dejamos la estructura.
}
