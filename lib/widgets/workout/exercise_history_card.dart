import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_manager.dart';
import '../../models/exercise_set.dart';

class ExerciseHistoryCard extends StatelessWidget {
  final String title;
  final ExerciseSet exerciseSet;
  final bool isPB;
  final VoidCallback? onCopy;

  const ExerciseHistoryCard({
    super.key,
    required this.title,
    required this.exerciseSet,
    required this.isPB,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeManager>(context);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isPB ? Colors.amber.withOpacity(0.2) : Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  color: isPB ? Colors.amber : Colors.white38,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              if (onCopy != null)
                IconButton(
                  icon: const Icon(LucideIcons.copy, size: 16),
                  onPressed: onCopy,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            "${exerciseSet.weight}kg x ${exerciseSet.reps.toInt()}",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          if (exerciseSet.note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                "Nota: ${exerciseSet.note}",
                style: const TextStyle(fontSize: 10, color: Colors.white54, fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }
}
