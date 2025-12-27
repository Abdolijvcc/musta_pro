import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/theme_manager.dart';
import '../../providers/workout_provider.dart';
import '../../models/exercise_set.dart';

class ExerciseDetailScreen extends StatelessWidget {
  final String exerciseName;

  const ExerciseDetailScreen({super.key, required this.exerciseName});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeManager>(context);
    final workout = Provider.of<WorkoutProvider>(context);

    final history = workout.sessions
        .expand((s) => s.exercises)
        .where((e) => e.name == exerciseName.toUpperCase())
        .toList();

    final pb = workout.getPB(exerciseName);

    return Scaffold(
      appBar: AppBar(
        title: Text(exerciseName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
          if (pb != null) _buildPBSection(theme, pb),
          const SizedBox(height: 25),
          _sectionTitle('PROGRESO HISTÓRICO'),
          const SizedBox(height: 15),
          if (history.isNotEmpty) _buildChart(theme, history),
          const SizedBox(height: 25),
          _sectionTitle('TODAS LAS SERIES'),
          const SizedBox(height: 15),
          ...history.map((e) => _buildHistoryItem(theme, e)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white38, letterSpacing: 1.5));

  Widget _buildPBSection(ThemeManager theme, ExerciseSet pb) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: theme.accentColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Text('RÉCORD PERSONAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber)),
          const SizedBox(height: 10),
          Text("${pb.weight}kg x ${pb.reps.toInt()}", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 5),
          Text("Conseguido el ${pb.date.day}/${pb.date.month}/${pb.date.year}", style: const TextStyle(fontSize: 10, color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _buildChart(ThemeManager theme, List<ExerciseSet> history) {
    final spots = history.reversed.toList().asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.calculateScore());
    }).toList();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20)),
      child: LineChart(LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: theme.accentColor,
            barWidth: 4,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [theme.accentColor.withOpacity(0.3), theme.accentColor.withOpacity(0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter
              ),
            ),
          )
        ],
      )),
    );
  }

  Widget _buildHistoryItem(ThemeManager theme, ExerciseSet set) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(15)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("${set.weight}kg x ${set.reps.toInt()}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              Text("${set.date.day}/${set.date.month}/${set.date.year}", style: const TextStyle(fontSize: 10, color: Colors.white24)),
            ],
          ),
          if (set.note.isNotEmpty)
            const Icon(LucideIcons.messageSquare, size: 14, color: Colors.white24),
        ],
      ),
    );
  }
}
