import '../core/constants/exercise_database.dart';
import '../core/constants/app_constants.dart';

class WorkoutConfig {
  final List<String> groups;
  final Map<String, List<String>> exerciseDb;
  final Map<String, List<String>> archivedExercises;
  final String plannerMode;
  final Map<String, String> weeklyPlan;
  final int defaultRestSeconds;

  WorkoutConfig({
    required this.groups,
    required this.exerciseDb,
    required this.archivedExercises,
    this.plannerMode = 'sequential',
    required this.weeklyPlan,
    this.defaultRestSeconds = AppConstants.defaultRestSeconds,
  });

  factory WorkoutConfig.defaultConfig() {
    return WorkoutConfig(
      groups: List.from(ExerciseDatabase.defaultGroups),
      exerciseDb: Map.from(ExerciseDatabase.defaultExerciseDb),
      archivedExercises: {},
      weeklyPlan: {
        'Lunes': 'DESCANSO',
        'Martes': 'DESCANSO',
        'Miércoles': 'DESCANSO',
        'Jueves': 'DESCANSO',
        'Viernes': 'DESCANSO',
        'Sábado': 'DESCANSO',
        'Domingo': 'DESCANSO'
      },
    );
  }

  Map<String, dynamic> toJson() => {
    'groups': groups,
    'exercises': exerciseDb,
    'archivedExercises': archivedExercises,
    'plannerMode': plannerMode,
    'weeklyPlan': weeklyPlan,
    'defaultRestSeconds': defaultRestSeconds,
  };

  factory WorkoutConfig.fromJson(Map<String, dynamic> json) => WorkoutConfig(
    groups: List<String>.from(json['groups'] ?? []),
    exerciseDb: (json['exercises'] as Map? ?? {}).map(
      (k, v) => MapEntry(k.toString(), List<String>.from(v)),
    ),
    archivedExercises: (json['archivedExercises'] as Map? ?? {}).map(
      (k, v) => MapEntry(k.toString(), List<String>.from(v)),
    ),
    plannerMode: json['plannerMode'] ?? 'sequential',
    weeklyPlan: Map<String, String>.from(json['weeklyPlan'] ?? {}),
    defaultRestSeconds: json['defaultRestSeconds'] ?? AppConstants.defaultRestSeconds,
  );

  WorkoutConfig copyWith({
    List<String>? groups,
    Map<String, List<String>>? exerciseDb,
    Map<String, List<String>>? archivedExercises,
    String? plannerMode,
    Map<String, String>? weeklyPlan,
    int? defaultRestSeconds,
  }) {
    return WorkoutConfig(
      groups: groups ?? this.groups,
      exerciseDb: exerciseDb ?? this.exerciseDb,
      archivedExercises: archivedExercises ?? this.archivedExercises,
      plannerMode: plannerMode ?? this.plannerMode,
      weeklyPlan: weeklyPlan ?? this.weeklyPlan,
      defaultRestSeconds: defaultRestSeconds ?? this.defaultRestSeconds,
    );
  }
}
