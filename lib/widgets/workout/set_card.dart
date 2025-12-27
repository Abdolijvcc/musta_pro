import 'package:flutter/material.dart';
import '../../models/exercise_set.dart';
import '../../core/utils/date_utils.dart';

class SetCard extends StatelessWidget {
  final ExerciseSet exerciseSet;
  final VoidCallback? onDelete;

  const SetCard({super.key, required this.exerciseSet, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget content = Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "${exerciseSet.name}: ${exerciseSet.weight}kg x ${exerciseSet.reps.toInt()}",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              Text(
                exerciseSet.time,
                style: const TextStyle(fontSize: 10, color: Colors.white24),
              )
            ],
          ),
          if (exerciseSet.note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                exerciseSet.note,
                style: const TextStyle(fontSize: 10, color: Colors.white54, fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );

    if (onDelete == null) return content;

    return Dismissible(
      key: Key(exerciseSet.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete!(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
      ),
      child: content,
    );
  }
}
