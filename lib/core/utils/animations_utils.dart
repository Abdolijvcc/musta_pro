import 'package:flutter/material.dart';

class AnimationUtils {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 800);

  static const Curve defaultCurve = Curves.easeInOutBack;
  static const Curve smoothCurve = Curves.easeOutCubic;

  static Widget fadeIn({required Widget child, Duration? duration}) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: duration ?? fast,
      child: child,
    );
  }
}
