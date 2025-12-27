import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/workout_provider.dart';
import '../../widgets/workout/exercise_chip.dart';
import '../../widgets/workout/set_card.dart';
import '../../widgets/workout/record_banner.dart';
import '../../widgets/workout/exercise_history_card.dart';
import '../../widgets/workout/quick_timer_buttons.dart';
import '../../widgets/common/custom_input.dart';
import '../../widgets/common/custom_button.dart';

class WorkoutTab extends StatefulWidget {
  const WorkoutTab({super.key});

  @override
  State<WorkoutTab> createState() => _WorkoutTabState();
}

class _WorkoutTabState extends State<WorkoutTab> {
  final TextEditingController _weightCtrl = TextEditingController();
  final TextEditingController _repsCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workout = Provider.of<WorkoutProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);

    if (workout.isSessionActive) {
      return _buildActiveWorkout(workout, settings);
    }

    return _buildInactiveWorkout(workout, settings);
  }

  Widget _buildInactiveWorkout(WorkoutProvider workout, SettingsProvider settings) {
    final suggestion = workout.getSuggestion();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        GestureDetector(
          onTap: () => suggestion['type'] == 'DESCANSO' ? null : workout.startWorkout(suggestion['type']!),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: suggestion['type'] == 'DESCANSO' 
                  ? const LinearGradient(colors: [Color(0xFF0F172A), Colors.black]) 
                  : LinearGradient(colors: [Theme.of(context).primaryColor.withOpacity(0.8), Theme.of(context).primaryColor]),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(settings.translate('onboarding_title'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70)),
              Text(suggestion['type']!, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
              Text(suggestion['reason']!, style: const TextStyle(fontSize: 10, color: Colors.white)),
            ]),
          ),
        ),
        const SizedBox(height: 35),
        Text(settings.translate('active_exercises'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white38, letterSpacing: 2)),
        const SizedBox(height: 15),
        ...workout.config.groups.map((group) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A), 
            borderRadius: BorderRadius.circular(20), 
            border: Border.all(color: Colors.white.withOpacity(0.08))
          ),
          child: ListTile(
            title: Text(group, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
            trailing: Icon(Icons.chevron_right, size: 18, color: Theme.of(context).primaryColor),
            onTap: () => workout.startWorkout(group),
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildActiveWorkout(WorkoutProvider workout, SettingsProvider settings) {
    final pb = workout.getPB(workout.selectedExercise);
    final last = workout.getLastTime(workout.selectedExercise);

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white38, size: 20),
              onPressed: () => _showCancelDialog(context, workout, settings),
            ),
            Text(settings.translate('training'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
            PrimaryButton(
              label: settings.translate('finish_workout'),
              onPressed: () => workout.finishWorkout(),
              color: Colors.redAccent,
              icon: Icons.check,
            ),
          ],
        ),
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (workout.config.exerciseDb[workout.activeWorkoutType] ?? []).map((ex) => ExerciseChip(
                label: ex,
                isSelected: workout.selectedExercise == ex,
                onTap: () => workout.setSelectedExercise(ex),
              )).toList(),
            ),
            const SizedBox(height: 25),
            if (pb != null) ExerciseHistoryCard(title: "RÉCORD PERSONAL", exerciseSet: pb, isPB: true, onCopy: () => _weightCtrl.text = pb.weight.toString()),
            if (last != null && pb?.id != last.id) ...[
              const SizedBox(height: 10),
              ExerciseHistoryCard(title: "ÚLTIMA VEZ", exerciseSet: last, isPB: false, onCopy: () => _weightCtrl.text = last.weight.toString()),
            ],
            const SizedBox(height: 25),
            Row(children: [
              NumberInput(controller: _weightCtrl, label: 'PESO (KG)'),
              const SizedBox(width: 15),
              NumberInput(controller: _repsCtrl, label: 'REPS'),
            ]),
            const SizedBox(height: 15),
            CustomInput(controller: _noteCtrl, label: 'NOTA DE LA SERIE', hint: '¿Cómo te has sentido?'),
            const SizedBox(height: 15),
            const QuickTimerButtons(),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'GUARDAR SERIE',
              onPressed: () {
                if (_weightCtrl.text.isNotEmpty && _repsCtrl.text.isNotEmpty) {
                  workout.addSet(
                    workout.selectedExercise,
                    double.parse(_weightCtrl.text.replaceAll(',', '.')),
                    double.parse(_repsCtrl.text.replaceAll(',', '.')),
                    _noteCtrl.text,
                  );
                  _weightCtrl.clear();
                  _repsCtrl.clear();
                  _noteCtrl.clear();
                }
              },
            ),
            const SizedBox(height: 25),
            ...workout.currentSessionExercises.map((s) => SetCard(exerciseSet: s)).toList(),
          ],
        ),
      ),
    ]);
  }

  void _showCancelDialog(BuildContext context, WorkoutProvider workout, SettingsProvider settings) {
    showDialog(context: context, builder: (c) => AlertDialog(
      title: Text(settings.translate('exit_workout')),
      content: const Text('¿Seguro que quieres salir? Se perderá el progreso de esta sesión.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: Text(settings.translate('cancel'))),
        TextButton(onPressed: () {
          workout.cancelWorkout();
          Navigator.pop(c);
        }, child: Text(settings.translate('confirm'), style: const TextStyle(color: Colors.redAccent))),
      ],
    ));
  }
}
