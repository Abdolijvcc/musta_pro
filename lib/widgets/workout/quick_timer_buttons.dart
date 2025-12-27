import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_manager.dart';
import '../../providers/workout_provider.dart';

class QuickTimerButtons extends StatelessWidget {
  const QuickTimerButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeManager>(context);
    final workout = Provider.of<WorkoutProvider>(context);

    final presets = [60, 90, 120, 180, 300];

    return Wrap(
      spacing: 8,
      children: presets.map((seconds) {
        final bool isDefault = seconds == workout.config.defaultRestSeconds;
        return GestureDetector(
          onTap: () => workout.startRestTimer(customSeconds: seconds),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDefault ? theme.accentColor.withOpacity(0.2) : theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDefault ? theme.accentColor : Colors.white.withOpacity(0.1),
              ),
            ),
            child: Text(
              "${seconds}s",
              style: TextStyle(
                fontSize: 10,
                color: isDefault ? theme.accentColor : Colors.white60,
                fontWeight: isDefault ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
