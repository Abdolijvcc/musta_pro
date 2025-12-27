import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/workout_config.dart';
import '../../core/theme/theme_manager.dart';
import '../../providers/settings_provider.dart';
import '../../providers/workout_provider.dart';
import '../../models/workout_config.dart';

class DaySelector extends StatelessWidget {
  final String day;
  final String selectedGroup;

  const DaySelector({super.key, required this.day, required this.selectedGroup});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeManager>(context);
    final workout = Provider.of<WorkoutProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final groups = [settings.translate('rest_day'), ...workout.config.groups];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(day, style: const TextStyle(fontSize: 12, color: Colors.white70))),
          DropdownButton<String>(
            value: selectedGroup,
            underline: const SizedBox(),
            dropdownColor: theme.cardColor,
            items: groups.map((g) => DropdownMenuItem(
              value: g,
              child: Text(g, style: const TextStyle(fontSize: 10, color: Colors.white)),
            )).toList(),
            onChanged: (v) {
              if (v != null) {
                final newPlan = Map<String, String>.from(workout.config.weeklyPlan);
                newPlan[day] = v;
                workout.updateConfig(workout.config.copyWith(weeklyPlan: newPlan));
              }
            },
          )
        ],
      ),
    );
  }
}

