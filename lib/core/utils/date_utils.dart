import 'package:intl/intl.dart';

class DateUtils {
  static String formatShortDate(DateTime date) {
    return DateFormat('dd/MM').format(date);
  }

  static String formatFullDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  static String getDayName(int weekday) {
    const days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    return days[(weekday - 1) % 7];
  }

  static String getTodayName() {
    return getDayName(DateTime.now().weekday);
  }
}
