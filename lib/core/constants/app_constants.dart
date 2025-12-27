import 'package:flutter/material.dart';

class AppConstants {
  // Tiempos de descanso (segundos)
  static const int defaultRestSeconds = 180;
  static const int minRestSeconds = 30;
  static const int maxRestSeconds = 600;

  // Límites de inputs
  static const double maxWeight = 999.0;
  static const double maxReps = 999.0;

  // Configuración de animaciones
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 350);
  static const Duration slowAnimation = Duration(milliseconds: 500);

  // Curves
  static const Curve defaultCurve = Curves.easeInOut;

  // Strings reutilizables
  static const String appName = 'TRAINER PRO';
  static const String version = '2.0.0';
  
  // Storage keys
  static const String keySessions = 'trainer_sessions';
  static const String keyConfig = 'trainer_config';
  static const String keyTheme = 'app_theme_index';
}
