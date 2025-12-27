import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_manager.dart';
import '../../providers/workout_provider.dart';

class TimerWidget extends StatefulWidget {
  const TimerWidget({super.key});

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeManager>(context);
    final workout = Provider.of<WorkoutProvider>(context);

    if (!workout.showTimer) {
      if (_isExpanded) WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => _isExpanded = false));
      return const SizedBox.shrink();
    }

    if (_isExpanded) {
      return _buildExpandedTimer(theme, workout);
    }

    return Positioned(
      bottom: workout.isSessionActive ? 40 : 110,
      right: 20,
      child: GestureDetector(
        onTap: () => setState(() => _isExpanded = true),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: theme.accentColor.withOpacity(0.5)),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.timer, color: theme.accentColor, size: 16),
              const SizedBox(width: 8),
              Text(
                "${(workout.secondsLeft ~/ 60)}:${(workout.secondsLeft % 60).toString().padLeft(2, '0')}",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => workout.stopTimer(),
                child: const Icon(LucideIcons.x, color: Colors.white24, size: 16),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedTimer(ThemeManager theme, WorkoutProvider workout) {
    return Container(
      color: Colors.black.withOpacity(0.95),
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.timer, color: workout.secondsLeft == 0 ? Colors.redAccent : theme.accentColor, size: 80),
                const SizedBox(height: 20),
                Text(
                  "${(workout.secondsLeft ~/ 60)}:${(workout.secondsLeft % 60).toString().padLeft(2, '0')}",
                  style: TextStyle(
                    color: workout.secondsLeft == 0 ? Colors.redAccent : Colors.white,
                    fontSize: 120, // Texto gigante
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: -5,
                    shadows: [
                      Shadow(color: (workout.secondsLeft == 0 ? Colors.redAccent : theme.accentColor).withOpacity(0.5), blurRadius: 30)
                    ]
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (workout.secondsLeft > 0) ...[
                      _extraBtn("+30s", () => workout.startRestTimer(customSeconds: workout.secondsLeft + 30)),
                      const SizedBox(width: 20),
                      _extraBtn("STOP", () => workout.stopTimer(), color: Colors.redAccent),
                    ] else ...[
                      _extraBtn("REPEAT", () => workout.startRestTimer(), color: theme.accentColor),
                      const SizedBox(width: 20),
                      _extraBtn("CLOSE", () => workout.stopTimer(), color: Colors.white24),
                    ],
                  ],
                )
              ],
            ),
          ),
          Positioned(
            top: 60,
            right: 24,
            child: IconButton(
              icon: const Icon(LucideIcons.x, color: Colors.white, size: 30),
              onPressed: () => setState(() => _isExpanded = false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _extraBtn(String label, VoidCallback onTap, {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: color ?? Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
