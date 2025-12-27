import 'package:uuid/uuid.dart';

class ExerciseSet {
  final String id;
  final String name;
  final double weight;
  final double reps;
  final String note;
  final String time;
  final DateTime date;

  ExerciseSet({
    String? id,
    required this.name,
    required this.weight,
    required this.reps,
    this.note = '',
    required this.time,
    required this.date,
  }) : id = id ?? const Uuid().v4();

  // Cada 2 reps extra cuenta como 1kg en la puntuación de récord
  double calculateScore() {
    return weight + (reps / 2);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'weight': weight,
    'reps': reps,
    'note': note,
    'time': time,
    'date': date.toIso8601String(),
  };

  factory ExerciseSet.fromJson(Map<String, dynamic> json) => ExerciseSet(
    id: json['id'],
    name: json['name'],
    weight: (json['weight'] as num).toDouble(),
    reps: (json['reps'] as num).toDouble(),
    note: json['note'] ?? '',
    time: json['time'],
    date: DateTime.parse(json['date']),
  );

  ExerciseSet copyWith({
    String? name,
    double? weight,
    double? reps,
    String? note,
    String? time,
    DateTime? date,
  }) {
    return ExerciseSet(
      id: id,
      name: name ?? this.name,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      note: note ?? this.note,
      time: time ?? this.time,
      date: date ?? this.date,
    );
  }
}
