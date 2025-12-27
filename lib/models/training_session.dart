import 'exercise_set.dart';

class TrainingSession {
  final String id;
  final String type;
  final List<ExerciseSet> exercises;
  final DateTime date;
  final DateTime? endDate;

  TrainingSession({
    required this.id,
    required this.type,
    required this.exercises,
    required this.date,
    this.endDate,
  });

  double calculateTotalVolume() {
    return exercises.fold(0, (sum, set) => sum + (set.weight * set.reps));
  }

  Duration getDuration() {
    if (endDate == null) return Duration.zero;
    return endDate!.difference(date);
  }

  List<String> getUniqueExercises() {
    return exercises.map((e) => e.name).toSet().toList();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'exercises': exercises.map((e) => e.toJson()).toList(),
    'date': date.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
  };

  factory TrainingSession.fromJson(Map<String, dynamic> json) => TrainingSession(
    id: json['id'],
    type: json['type'],
    exercises: (json['exercises'] as List)
        .map((e) => ExerciseSet.fromJson(e))
        .toList(),
    date: DateTime.parse(json['date']),
    endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
  );
}
