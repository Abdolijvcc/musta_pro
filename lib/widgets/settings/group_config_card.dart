import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/workout_config.dart';
import '../../core/theme/theme_manager.dart';
import '../../providers/workout_provider.dart';

class GroupConfigCard extends StatelessWidget {
  final String groupName;
  final int index;
  final VoidCallback onDelete;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onAddExercise;

  const GroupConfigCard({
    super.key,
    required this.groupName,
    required this.index,
    required this.onDelete,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onAddExercise,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeManager>(context);
    final workout = Provider.of<WorkoutProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final exercises = workout.config.exerciseDb[groupName] ?? [];
    final archived = workout.config.archivedExercises[groupName] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  groupName,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1),
                ),
              ),
              IconButton(icon: const Icon(LucideIcons.trash2, size: 16, color: Colors.redAccent), onPressed: onDelete),
              IconButton(icon: const Icon(LucideIcons.arrowUp, size: 16), onPressed: onMoveUp),
              IconButton(icon: const Icon(LucideIcons.arrowDown, size: 16), onPressed: onMoveDown),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            settings.translate('active_exercises').toUpperCase(),
            style: const TextStyle(fontSize: 8, color: Colors.white24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...exercises.map((ex) => _ExerciseTag(
                    name: ex,
                    onArchive: () {
                      final newDb = Map<String, List<String>>.from(workout.config.exerciseDb);
                      final newArchived = Map<String, List<String>>.from(workout.config.archivedExercises);
                      newDb[groupName]!.remove(ex);
                      newArchived[groupName] ??= [];
                      newArchived[groupName]!.add(ex);
                      workout.updateConfig(workout.config.copyWith(
                        exerciseDb: newDb,
                        archivedExercises: newArchived,
                      ));
                    },
                    onDelete: () => workout.deleteExercise(groupName, ex),
                  )),
              IconButton(
                icon: const Icon(LucideIcons.plusCircle, size: 20, color: Colors.greenAccent),
                onPressed: onAddExercise,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          if (archived.isNotEmpty) ...[
            const SizedBox(height: 15),
            Text(
              settings.translate('archived').toUpperCase(),
              style: const TextStyle(fontSize: 8, color: Colors.orangeAccent, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: archived.map((ex) => GestureDetector(
                onTap: () {
                  final newDb = Map<String, List<String>>.from(workout.config.exerciseDb);
                  final newArchived = Map<String, List<String>>.from(workout.config.archivedExercises);
                  newArchived[groupName]!.remove(ex);
                  newDb[groupName] ??= [];
                  newDb[groupName]!.add(ex);
                  workout.updateConfig(workout.config.copyWith(
                    exerciseDb: newDb,
                    archivedExercises: newArchived,
                  ));
                },
                child: Chip(
                  backgroundColor: Colors.white10,
                  label: Text(ex, style: const TextStyle(fontSize: 8, color: Colors.white38)),
                  avatar: const Icon(LucideIcons.rotateCcw, size: 10, color: Colors.white38),
                ),
              )).toList(),
            ),
          ]
        ],
      ),
    );
  }
}

class _ExerciseTag extends StatelessWidget {
  final String name;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  const _ExerciseTag({required this.name, required this.onArchive, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(name, style: const TextStyle(fontSize: 9, color: Colors.white70)),
          IconButton(
            icon: const Icon(LucideIcons.archive, size: 12, color: Colors.orangeAccent),
            onPressed: onArchive,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            constraints: const BoxConstraints(),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 12, color: Colors.redAccent),
            onPressed: onDelete,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

