import 'exercise_set.dart';

class WorkoutRecord {
  final ExerciseSet set;
  final DateTime achievedDate;
  final String note;

  WorkoutRecord({
    required this.set,
    required this.achievedDate,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
    'set': set.toJson(),
    'achievedDate': achievedDate.toIso8601String(),
    'note': note,
  };

  factory WorkoutRecord.fromJson(Map<String, dynamic> json) => WorkoutRecord(
    set: ExerciseSet.fromJson(json['set']),
    achievedDate: DateTime.parse(json['achievedDate']),
    note: json['note'] ?? '',
  );
}
