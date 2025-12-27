class WorkoutStats {
  final Map<String, double> volumePerPeriod; // e.g., {'2023-W01': 5000}
  final int weeklyFrequency;
  final String bestDay;
  final List<String> insights;

  WorkoutStats({
    required this.volumePerPeriod,
    required this.weeklyFrequency,
    required this.bestDay,
    required this.insights,
  });

  Map<String, dynamic> toJson() => {
    'volumePerPeriod': volumePerPeriod,
    'weeklyFrequency': weeklyFrequency,
    'bestDay': bestDay,
    'insights': insights,
  };

  factory WorkoutStats.fromJson(Map<String, dynamic> json) => WorkoutStats(
    volumePerPeriod: Map<String, double>.from(json['volumePerPeriod'] ?? {}),
    weeklyFrequency: json['weeklyFrequency'] ?? 0,
    bestDay: json['bestDay'] ?? 'N/A',
    insights: List<String>.from(json['insights'] ?? []),
  );
}
