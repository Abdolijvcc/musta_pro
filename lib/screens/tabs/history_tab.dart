import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/workout_provider.dart';
import '../../core/theme/theme_manager.dart';
import '../../widgets/workout/set_card.dart';

class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeManager>(context);
    final workout = Provider.of<WorkoutProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);

    if (workout.sessions.isEmpty) {
      return Center(
        child: Text(settings.translate('no_activity'), style: const TextStyle(color: Colors.white12, fontSize: 10)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: workout.sessions.length,
      itemBuilder: (c, i) {
        final session = workout.sessions[i];
        return Dismissible(
          key: Key(session.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(15)),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => workout.deleteSession(session.id),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: ExpansionTile(
              iconColor: theme.accentColor,
              title: Text(session.type, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
              subtitle: Text(
                "${session.date.day}/${session.date.month} - ${session.exercises.length} ${settings.translate('all_sets').toLowerCase()}",
                style: const TextStyle(fontSize: 10, color: Colors.white24),
              ),
              children: session.exercises.map((s) => SetCard(exerciseSet: s)).toList(),
            ),
          ),
        );
      },
    );
  }
}
