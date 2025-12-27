import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/workout_config.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_manager.dart';
import '../../providers/settings_provider.dart';
import '../../providers/workout_provider.dart';
import '../../widgets/settings/group_config_card.dart';
import '../../widgets/settings/day_selector.dart';
import '../../widgets/settings/exercise_manager.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeManager>(context);
    final workout = Provider.of<WorkoutProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(settings.translate('settings'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        backgroundColor: theme.cardColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _sectionTitle(settings.translate('language')),
          const SizedBox(height: 10),
          Row(children: [
            _langBtn(context, 'ES', 'es', settings),
            const SizedBox(width: 10),
            _langBtn(context, 'EN', 'en', settings),
            const SizedBox(width: 10),
            _langBtn(context, 'AR', 'ar', settings),
          ]),
          const SizedBox(height: 25),

          _sectionTitle(settings.translate('rest_between_sets')),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            margin: const EdgeInsets.only(top: 10, bottom: 25),
            decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(15)),
            child: Row(children: [
              Text('${workout.config.defaultRestSeconds}s', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              const Spacer(),
              IconButton(
                icon: const Icon(LucideIcons.minus, color: Colors.white), 
                onPressed: () => workout.updateConfig(workout.config.copyWith(
                  defaultRestSeconds: (workout.config.defaultRestSeconds - 10).clamp(30, 600),
                )),
              ),
              IconButton(
                icon: const Icon(LucideIcons.plus, color: Colors.white), 
                onPressed: () => workout.updateConfig(workout.config.copyWith(
                  defaultRestSeconds: (workout.config.defaultRestSeconds + 10).clamp(30, 600),
                )),
              ),
            ]),
          ),

          _sectionTitle(settings.translate('planner_mode')),
          const SizedBox(height: 10),
          Row(children: [
            _modeBtn(context, settings.translate('cycle'), 'sequential', workout.config.plannerMode == 'sequential'),
            const SizedBox(width: 10),
            _modeBtn(context, settings.translate('calendar'), 'calendar', workout.config.plannerMode == 'calendar'),
          ]),
          const SizedBox(height: 25),

          if (workout.config.plannerMode == 'calendar') ...[
            _sectionTitle(settings.translate('day_assignment')),
            const SizedBox(height: 10),
            ...workout.config.weeklyPlan.keys.map((day) => DaySelector(
              day: day,
              selectedGroup: workout.config.weeklyPlan[day]!,
            )),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionTitle(settings.translate('cycle_order')),
                TextButton.icon(
                  onPressed: () => _showAddGroupDialog(context, workout, settings),
                  icon: Icon(LucideIcons.plus, size: 12, color: theme.accentColor),
                  label: Text(settings.translate('add_group'), style: TextStyle(fontSize: 9, color: theme.accentColor)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorder: (oldIndex, newIndex) {
                if (newIndex > oldIndex) newIndex -= 1;
                final newGroups = List<String>.from(workout.config.groups);
                final item = newGroups.removeAt(oldIndex);
                newGroups.insert(newIndex, item);
                workout.updateConfig(workout.config.copyWith(groups: newGroups));
              },
              children: workout.config.groups.asMap().entries.map((entry) => GroupConfigCard(
                key: ValueKey(entry.value),
                groupName: entry.value,
                index: entry.key,
                onDelete: () => _showDeleteGroupDialog(context, workout, entry.key, entry.value, settings),
                onMoveUp: () => _moveGroup(workout, entry.key, -1),
                onMoveDown: () => _moveGroup(workout, entry.key, 1),
                onAddExercise: () => showDialog(
                  context: context, 
                  builder: (c) => ExerciseSearchDialog(onSelected: (ex) {
                    final newDb = Map<String, List<String>>.from(workout.config.exerciseDb);
                    newDb[entry.value] ??= [];
                    if (!newDb[entry.value]!.contains(ex)) {
                      newDb[entry.value]!.add(ex);
                      workout.updateConfig(workout.config.copyWith(exerciseDb: newDb));
                    }
                  }),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _langBtn(BuildContext context, String label, String code, SettingsProvider settings) {
    final isSelected = settings.languageCode == code;
    final theme = Provider.of<ThemeManager>(context);
    return Expanded(child: GestureDetector(
      onTap: () => settings.setLanguage(code),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? theme.accentColor : theme.cardColor, 
          borderRadius: BorderRadius.circular(10)
        ),
        child: Center(child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.white38))),
      ),
    ));
  }

  Widget _sectionTitle(String t) => Text(t, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white38, letterSpacing: 1.5));

  Widget _modeBtn(BuildContext context, String l, String m, bool isSelected) {
    final theme = Provider.of<ThemeManager>(context);
    final workout = Provider.of<WorkoutProvider>(context);
    return Expanded(child: GestureDetector(
      onTap: () => workout.updateConfig(workout.config.copyWith(plannerMode: m)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: isSelected ? theme.accentColor : theme.cardColor, 
          borderRadius: BorderRadius.circular(12)
        ),
        child: Center(child: Text(l, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.white38))),
      ),
    ));
  }

  void _moveGroup(WorkoutProvider workout, int index, int delta) {
    if (index + delta < 0 || index + delta >= workout.config.groups.length) return;
    final newGroups = List<String>.from(workout.config.groups);
    final item = newGroups.removeAt(index);
    newGroups.insert(index + delta, item);
    workout.updateConfig(workout.config.copyWith(groups: newGroups));
  }

  void _showAddGroupDialog(BuildContext context, WorkoutProvider workout, SettingsProvider settings) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (c) => AlertDialog(
      title: Text(settings.translate('new_routine')),
      backgroundColor: const Color(0xFF0F172A),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(hintText: 'Ej: BRAZO, PIERNA...', hintStyle: const TextStyle(color: Colors.white24)),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: Text(settings.translate('cancel'))),
        TextButton(onPressed: () {
          if (ctrl.text.isNotEmpty) {
            final newGroups = List<String>.from(workout.config.groups)..add(ctrl.text.toUpperCase());
            final newDb = Map<String, List<String>>.from(workout.config.exerciseDb)..[ctrl.text.toUpperCase()] = [];
            workout.updateConfig(workout.config.copyWith(groups: newGroups, exerciseDb: newDb));
          }
          Navigator.pop(c);
        }, child: Text(settings.translate('confirm'))),
      ],
    ));
  }

  void _showDeleteGroupDialog(BuildContext context, WorkoutProvider workout, int index, String name, SettingsProvider settings) {
    showDialog(context: context, builder: (c) => AlertDialog(
      title: Text(settings.translate('delete_exercise')),
      content: Text('${settings.translate('confirm')} $name?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: Text(settings.translate('cancel'))),
        TextButton(onPressed: () {
          final newGroups = List<String>.from(workout.config.groups)..removeAt(index);
          workout.updateConfig(workout.config.copyWith(groups: newGroups));
          Navigator.pop(c);
        }, child: Text(settings.translate('confirm'), style: const TextStyle(color: Colors.redAccent))),
      ],
    ));
  }
}

