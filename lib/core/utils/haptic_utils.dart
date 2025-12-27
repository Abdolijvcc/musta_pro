import 'package:flutter/services.dart';

class HapticUtils {
  static void light() => HapticFeedback.lightImpact();
  static void medium() => HapticFeedback.mediumImpact();
  static void heavy() => HapticFeedback.heavyImpact();
  
  static void success() async {
    light();
    await Future.delayed(const Duration(milliseconds: 100));
    light();
  }

  static void error() async {
    heavy();
    await Future.delayed(const Duration(milliseconds: 100));
    heavy();
  }

  static void recordCelebration() async {
    for (int i = 0; i < 5; i++) {
      heavy();
      await Future.delayed(Duration(milliseconds: 200 - (i * 30)));
    }
  }

  static void timerFinish() async {
    for (int i = 0; i < 6; i++) {
      heavy();
      await Future.delayed(const Duration(milliseconds: 150));
    }
  }
}
