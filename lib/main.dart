import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const MustaPro());
}

class MustaPro extends StatelessWidget {
  const MustaPro({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MUSTA PRO',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF020617),
        primaryColor: const Color(0xFF3B82F6),
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class WorkoutSession {
  final String id;
  final String type;
  final List<ExerciseSet> exercises;
  final DateTime date;
  final int totalExercises;

  WorkoutSession({
    required this.id,
    required this.type,
    required this.exercises,
    required this.date,
    required this.totalExercises,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'exercises': exercises.map((e) => e.toJson()).toList(),
    'date': date.toIso8601String(),
    'totalExercises': totalExercises,
  };

  factory WorkoutSession.fromJson(Map<String, dynamic> json) => WorkoutSession(
    id: json['id'],
    type: json['type'],
    exercises: (json['exercises'] as List).map((e) => ExerciseSet.fromJson(e)).toList(),
    date: DateTime.parse(json['date']),
    totalExercises: json['totalExercises'],
  );
}

class ExerciseSet {
  final String name;
  final double weight;
  final int reps;
  final String time;

  ExerciseSet({
    required this.name,
    required this.weight,
    required this.reps,
    required this.time,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'weight': weight,
    'reps': reps,
    'time': time,
  };

  factory ExerciseSet.fromJson(Map<String, dynamic> json) => ExerciseSet(
    name: json['name'],
    weight: json['weight'].toDouble(),
    reps: json['reps'],
    time: json['time'],
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> initialGroups = ['TORSO', 'BRAZO', 'PECHO', 'ESPALDA', 'PIERNA'];
  final Map<String, List<String>> initialExercises = {
    'TORSO': ['PRES BANCA', 'JALÓN AL PECHO ABIERTO', 'PRES INCLINADO', 'REMO EN T'],
    'BRAZO': ['TRIC UNILAT', 'PRESS FRANCES', 'BÍCEPS SENTADO', 'LATERALES MAQUINA', 'BÍCEPS POLEA', 'MILITAR MÁQUINA'],
    'PECHO': ['PRES BANCA', 'PRESS INCLINADO MANCUERNA', 'APERTURAS', 'EXTENSIÓN TRIC UNILAT', 'LATERALES MAQUINA', 'PRESS FRANCES', 'MILITAR MÁQUINA'],
    'ESPALDA': ['JALÓN AL PECHO ABIERTO', 'REMO EN T', 'PULL OVER', 'CURL SENTADO', 'BÍCEPS POLEA'],
    'PIERNA': ['ADDUCTOR', 'HAKA', 'FEMORAL TUMBADO', 'EXTENSIÓN', 'FEMORAL SENTADO']
  };

  List<WorkoutSession> sessions = [];
  List<String> userGroups = [];
  Map<String, List<String>> exerciseDb = {};
  Map<String, List<String>> archivedExercises = {}; // Ejercicios archivados
  bool loading = true;
  int activeTab = 0;
  
  // Sistema de planificación
  bool isLoopMode = true; // true = Bucle, false = Modo Días
  Map<int, String> weeklySchedule = {}; // 0=Lunes, 6=Domingo -> grupo
  
  bool isSessionActive = false;
  String activeWorkoutType = '';
  List<ExerciseSet> currentSessionExercises = [];
  
  String exercise = '';
  String weight = '';
  String reps = '';
  
  String? expandedSession;
  bool showSettings = false;
  
  // Controllers para modales
  final TextEditingController groupNameController = TextEditingController();
  final TextEditingController exerciseNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    final savedSessions = prefs.getString('musta_sessions');
    if (savedSessions != null) {
      final List<dynamic> parsed = jsonDecode(savedSessions);
      sessions = parsed.map((e) => WorkoutSession.fromJson(e)).toList();
    }

    final savedConfig = prefs.getString('musta_config');
    if (savedConfig != null) {
      final config = jsonDecode(savedConfig);
      userGroups = List<String>.from(config['groups'] ?? initialGroups);
      exerciseDb = Map<String, List<String>>.from(
        (config['exercises'] as Map).map((k, v) => MapEntry(k, List<String>.from(v)))
      );
      archivedExercises = Map<String, List<String>>.from(
        (config['archivedExercises'] as Map? ?? {}).map((k, v) => MapEntry(k, List<String>.from(v)))
      );
      isLoopMode = config['isLoopMode'] ?? true;
      weeklySchedule = Map<int, String>.from(
        (config['weeklySchedule'] as Map? ?? {}).map((k, v) => MapEntry(int.parse(k.toString()), v.toString()))
      );
    } else {
      userGroups = initialGroups;
      exerciseDb = initialExercises;
      archivedExercises = {};
      isLoopMode = true;
      weeklySchedule = {};
    }

    setState(() => loading = false);
  }

  Future<void> saveConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('musta_config', jsonEncode({
      'groups': userGroups,
      'exercises': exerciseDb,
      'archivedExercises': archivedExercises,
      'isLoopMode': isLoopMode,
      'weeklySchedule': weeklySchedule.map((k, v) => MapEntry(k.toString(), v)),
    }));
  }

  Future<void> saveSessions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('musta_sessions', jsonEncode(sessions.map((e) => e.toJson()).toList()));
  }

  ExerciseSet? getPersonalBest() {
    if (exercise.isEmpty) return null;
    final allSets = sessions.expand((s) => s.exercises).where((e) => e.name == exercise.toUpperCase()).toList();
    if (allSets.isEmpty) return null;
    return allSets.reduce((a, b) => a.weight > b.weight ? a : b);
  }

  String getWorkoutSuggestion() {
    if (userGroups.isEmpty) return 'SIN RUTINAS';
    
    if (!isLoopMode) {
      // Modo Días: usar programación semanal
      final today = DateTime.now();
      final dayOfWeek = (today.weekday - 1) % 7; // 0=Lunes, 6=Domingo
      if (weeklySchedule.containsKey(dayOfWeek)) {
        return weeklySchedule[dayOfWeek]!;
      }
      return userGroups[0];
    } else {
      // Modo Bucle: secuencial
      if (sessions.isEmpty) return userGroups[0];
      final lastWorkout = sessions[0].type;
      final lastIndex = userGroups.lastIndexOf(lastWorkout);
      if (lastIndex == -1) return userGroups[0];
      return userGroups[(lastIndex + 1) % userGroups.length];
    }
  }

  void startWorkout(String type) {
    setState(() {
      activeWorkoutType = type;
      currentSessionExercises = [];
      isSessionActive = true;
      exercise = exerciseDb[type]?.isNotEmpty == true ? exerciseDb[type]![0] : '';
    });
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void addSet() {
    if (exercise.isEmpty || weight.isEmpty || reps.isEmpty) return;
    
    final now = DateTime.now();
    final newSet = ExerciseSet(
      name: exercise.toUpperCase(),
      weight: double.parse(weight),
      reps: int.parse(reps),
      time: _formatTime(now),
    );

    setState(() {
      currentSessionExercises.insert(0, newSet);
      weight = '';
      reps = '';
    });
  }

  void finishWorkout() async {
    if (currentSessionExercises.isNotEmpty) {
      final newSession = WorkoutSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: activeWorkoutType,
        exercises: currentSessionExercises,
        date: DateTime.now(),
        totalExercises: currentSessionExercises.length,
      );
      
      setState(() {
        sessions.insert(0, newSession);
        isSessionActive = false;
        activeTab = 1;
      });
      
      await saveSessions();
    } else {
      setState(() => isSessionActive = false);
    }
  }

  Future<void> _deleteSession(String sessionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Eliminar sesión', style: TextStyle(color: Colors.white)),
        content: const Text('¿Estás seguro de eliminar esta sesión?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      setState(() {
        sessions.removeWhere((s) => s.id == sessionId);
      });
      await saveSessions();
    }
  }

  void _showWeeklyScheduleModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'PROGRAMACIÓN SEMANAL',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (int day = 0; day < 7; day++)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'][day],
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 12),
                          DropdownButton<String>(
                            value: weeklySchedule[day],
                            isExpanded: true,
                            dropdownColor: const Color(0xFF1E293B),
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                            hint: const Text('Sin rutina', style: TextStyle(color: Color(0xFF64748B))),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('Sin rutina')),
                              ...userGroups.map((g) => DropdownMenuItem(value: g, child: Text(g))),
                            ],
                            onChanged: (value) {
                              setState(() {
                                if (value == null) {
                                  weeklySchedule.remove(day);
                                } else {
                                  weeklySchedule[day] = value;
                                }
                              });
                              saveConfig();
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditGroupsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditGroupsModal(
        userGroups: userGroups,
        exerciseDb: exerciseDb,
        archivedExercises: archivedExercises,
        onGroupsChanged: (newGroups, newExerciseDb, newArchived) {
          setState(() {
            userGroups = newGroups;
            exerciseDb = newExerciseDb;
            archivedExercises = newArchived;
          });
          saveConfig();
        },
      ),
    );
  }

  void _showGroupStatsModal(String group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _GroupStatsModal(
        group: group,
        sessions: sessions,
        exerciseDb: exerciseDb,
        archivedExercises: archivedExercises,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: Text(
            'CARGANDO...',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: Color(0xFF3B82F6),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Row(
          children: [
            const Text(
              'MUSTA ',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
            ),
            const Text(
              'PRO',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: Color(0xFF3B82F6),
              ),
            ),
          ],
        ),
        actions: [
          if (isSessionActive)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF3B82F6),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    activeWorkoutType,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: IndexedStack(
        index: activeTab,
        children: [
          _buildAddTab(),
          _buildHistoryTab(),
          _buildStatsTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withOpacity(0.9),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavButton(0, Icons.play_circle_outline, 'ENTRENO'),
                _buildNavButton(1, Icons.history, 'LOGS'),
                _buildNavButton(2, Icons.trending_up, 'STATS'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton(int index, IconData icon, String label) {
    final isActive = activeTab == index;
    return GestureDetector(
      onTap: () => setState(() {
        activeTab = index;
        showSettings = false;
      }),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 32,
            color: isActive ? const Color(0xFF3B82F6) : const Color(0xFF475569),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: isActive ? const Color(0xFF3B82F6) : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddTab() {
    if (!isSessionActive) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (!showSettings) ...[
              // Selector de modo
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => isLoopMode = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isLoopMode ? const Color(0xFF3B82F6) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'BUCLE',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          isLoopMode = false;
                          saveConfig();
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !isLoopMode ? const Color(0xFF3B82F6) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'MODO DÍAS',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (isLoopMode)
                GestureDetector(
                  onTap: () => startWorkout(getWorkoutSuggestion()),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PRÓXIMO EN CICLO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFBFDBFE),
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          getWorkoutSuggestion(),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                GestureDetector(
                  onTap: () => _showWeeklyScheduleModal(),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PROGRAMACIÓN SEMANAL',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFBFDBFE),
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          getWorkoutSuggestion(),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
            ],
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'RUTINAS DISPONIBLES',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF64748B),
                              letterSpacing: 3,
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(() => showSettings = !showSettings),
                            icon: Icon(
                              showSettings ? Icons.close : Icons.settings,
                              color: showSettings ? Colors.white : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ...userGroups.map((group) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () => startWorkout(group),
                          child: Container(
                            height: 80,
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B).withOpacity(0.5),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white.withOpacity(0.05)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  group,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    fontStyle: FontStyle.italic,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: Color(0xFF475569)),
                              ],
                            ),
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
                if (showSettings)
                  Positioned.fill(
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'CONFIGURACIÓN',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF64748B),
                                  letterSpacing: 3,
                                ),
                              ),
                              IconButton(
                                onPressed: () => setState(() => showSettings = false),
                                icon: const Icon(Icons.close, color: Colors.white),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => _showEditGroupsModal(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B82F6),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text(
                              'EDITAR GRUPOS',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    }

    // Active session view
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  activeWorkoutType,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: finishWorkout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444).withOpacity(0.1),
                  foregroundColor: const Color(0xFFEF4444),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'FINALIZAR',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (exerciseDb[activeWorkoutType] ?? []).map((ex) => 
                    GestureDetector(
                      onTap: () => setState(() => exercise = ex),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: exercise == ex ? const Color(0xFF3B82F6) : const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: exercise == ex ? const Color(0xFF60A5FA) : Colors.white.withOpacity(0.05),
                          ),
                        ),
                        child: Text(
                          ex,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: exercise == ex ? Colors.white : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ).toList(),
                ),
                if (exercise.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.emoji_events, color: Color(0xFF3B82F6), size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'RÉCORD PERSONAL',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF64748B)),
                              ),
                              Text(
                                getPersonalBest() != null 
                                  ? '${getPersonalBest()!.weight}kg x ${getPersonalBest()!.reps}'
                                  : 'PRIMERA VEZ',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                        ),
                        if (getPersonalBest() != null)
                          IconButton(
                            onPressed: () {
                              setState(() {
                                weight = getPersonalBest()!.weight.toStringAsFixed(0);
                              });
                            },
                            icon: const Icon(Icons.content_copy, color: Color(0xFF3B82F6), size: 18),
                            tooltip: 'Copiar peso',
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Text('Peso (kg)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF64748B))),
                          const SizedBox(height: 8),
                          TextField(
                            controller: TextEditingController(text: weight),
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900),
                            decoration: InputDecoration(
                              hintText: '0',
                              filled: true,
                              fillColor: const Color(0xFF1E293B).withOpacity(0.5),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (v) => weight = v,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          const Text('Reps', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF64748B))),
                          const SizedBox(height: 8),
                          TextField(
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900),
                            decoration: InputDecoration(
                              hintText: '0',
                              filled: true,
                              fillColor: const Color(0xFF1E293B).withOpacity(0.5),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (v) => reps = v,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: addSet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: const Text(
                      'GUARDAR SERIE',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ...currentSessionExercises.map((ex) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ex.name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF64748B))),
                    const SizedBox(height: 4),
                    Text('${ex.weight}kg x ${ex.reps}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                  ],
                ),
                Text(ex.time, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF334155))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 16, left: 8),
            child: Text(
              'HISTORIAL',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
            ),
          );
        }
        
        final session = sessions[index - 1];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.all(24),
                leading: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${session.date.day}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                      Text(
                        ['ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN', 'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC'][session.date.month - 1],
                        style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Color(0xFF3B82F6)),
                      ),
                    ],
                  ),
                ),
                title: Text(
                  session.type,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
                ),
                subtitle: Text(
                  '${session.totalExercises} SERIES REGISTRADAS',
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete, color: Color(0xFFEF4444), size: 20),
                      onPressed: () => _deleteSession(session.id),
                    ),
                    Icon(
                      expandedSession == session.id ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: const Color(0xFF475569),
                    ),
                  ],
                ),
                onTap: () => setState(() => expandedSession = expandedSession == session.id ? null : session.id),
              ),
              if (expandedSession == session.id)
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: Column(
                    children: session.exercises.map((ex) => 
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(ex.name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF64748B))),
                            Text('${ex.weight}kg x${ex.reps}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                    ).toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: userGroups.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 16, left: 8),
            child: Text(
              'ANÁLISIS DE MARCAS',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
            ),
          );
        }
        
        final group = userGroups[index - 1];
        final activeExercises = exerciseDb[group]?.length ?? 0;
        final archivedCount = archivedExercises[group]?.length ?? 0;
        return GestureDetector(
          onTap: () => _showGroupStatsModal(group),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.fitness_center, color: Color(0xFF3B82F6), size: 20),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
                      ),
                      Text(
                        '$activeExercises ACTIVOS${archivedCount > 0 ? ' • $archivedCount ARCHIVADOS' : ''}',
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF334155)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EditGroupsModal extends StatefulWidget {
  final List<String> userGroups;
  final Map<String, List<String>> exerciseDb;
  final Map<String, List<String>> archivedExercises;
  final Function(List<String>, Map<String, List<String>>, Map<String, List<String>>) onGroupsChanged;

  const _EditGroupsModal({
    required this.userGroups,
    required this.exerciseDb,
    required this.archivedExercises,
    required this.onGroupsChanged,
  });

  @override
  State<_EditGroupsModal> createState() => _EditGroupsModalState();
}

class _EditGroupsModalState extends State<_EditGroupsModal> {
  late List<String> groups;
  late Map<String, List<String>> exercises;
  late Map<String, List<String>> archived;
  String? selectedGroup;
  final TextEditingController groupNameController = TextEditingController();
  final TextEditingController exerciseNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    groups = List.from(widget.userGroups);
    exercises = Map.from(widget.exerciseDb);
    archived = Map.from(widget.archivedExercises);
  }

  void _addGroup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Nuevo grupo', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: groupNameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Nombre del grupo',
            hintStyle: TextStyle(color: Color(0xFF64748B)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              groupNameController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final name = groupNameController.text.toUpperCase().trim();
              if (name.isNotEmpty && !groups.contains(name)) {
                setState(() {
                  groups.add(name);
                  exercises[name] = [];
                });
                groupNameController.clear();
                Navigator.pop(context);
                widget.onGroupsChanged(groups, exercises, archived);
              }
            },
            child: const Text('Añadir'),
          ),
        ],
      ),
    );
  }

  void _deleteGroup(String group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Eliminar grupo', style: TextStyle(color: Colors.white)),
        content: Text('¿Eliminar $group?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                groups.remove(group);
                exercises.remove(group);
                archived.remove(group);
              });
              Navigator.pop(context);
              widget.onGroupsChanged(groups, exercises, archived);
            },
            child: const Text('Eliminar', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }

  void _moveGroup(int index, bool up) {
    if ((up && index == 0) || (!up && index == groups.length - 1)) return;
    setState(() {
      final newIndex = up ? index - 1 : index + 1;
      final temp = groups[index];
      groups[index] = groups[newIndex];
      groups[newIndex] = temp;
    });
    widget.onGroupsChanged(groups, exercises, archived);
  }

  void _addExercise(String group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Nuevo ejercicio', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: exerciseNameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Nombre del ejercicio',
            hintStyle: TextStyle(color: Color(0xFF64748B)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              exerciseNameController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final name = exerciseNameController.text.toUpperCase().trim();
              if (name.isNotEmpty) {
                setState(() {
                  if (!exercises.containsKey(group)) exercises[group] = [];
                  exercises[group]!.add(name);
                });
                exerciseNameController.clear();
                Navigator.pop(context);
                widget.onGroupsChanged(groups, exercises, archived);
              }
            },
            child: const Text('Añadir'),
          ),
        ],
      ),
    );
  }

  void _deleteExercise(String group, String exercise) {
    setState(() {
      exercises[group]!.remove(exercise);
      if (!archived.containsKey(group)) archived[group] = [];
      archived[group]!.add(exercise);
    });
    widget.onGroupsChanged(groups, exercises, archived);
  }

  void _restoreExercise(String group, String exercise) {
    setState(() {
      archived[group]!.remove(exercise);
      if (!exercises.containsKey(group)) exercises[group] = [];
      exercises[group]!.add(exercise);
    });
    widget.onGroupsChanged(groups, exercises, archived);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'EDITAR GRUPOS',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ElevatedButton(
                  onPressed: _addGroup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('AÑADIR GRUPO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(height: 16),
                ...groups.asMap().entries.map((entry) {
                  final index = entry.key;
                  final group = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                group,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_upward, size: 18),
                              onPressed: () => _moveGroup(index, true),
                              color: const Color(0xFF3B82F6),
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_downward, size: 18),
                              onPressed: () => _moveGroup(index, false),
                              color: const Color(0xFF3B82F6),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18),
                              onPressed: () => _deleteGroup(group),
                              color: const Color(0xFFEF4444),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _addExercise(group),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6).withOpacity(0.2),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('+ AÑADIR EJERCICIO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900)),
                        ),
                        const SizedBox(height: 12),
                        ...(exercises[group] ?? []).map((ex) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(child: Text(ex, style: const TextStyle(fontSize: 12, color: Colors.white70))),
                              IconButton(
                                icon: const Icon(Icons.archive, size: 16),
                                onPressed: () => _deleteExercise(group, ex),
                                color: const Color(0xFF64748B),
                              ),
                            ],
                          ),
                        )),
                        if ((archived[group] ?? []).isNotEmpty) ...[
                          const Divider(),
                          const Text('ARCHIVADOS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF64748B))),
                          const SizedBox(height: 8),
                          ...(archived[group] ?? []).map((ex) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(child: Text(ex, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
                                IconButton(
                                  icon: const Icon(Icons.restore, size: 16),
                                  onPressed: () => _restoreExercise(group, ex),
                                  color: const Color(0xFF3B82F6),
                                ),
                              ],
                            ),
                          )),
                        ],
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupStatsModal extends StatelessWidget {
  final String group;
  final List<WorkoutSession> sessions;
  final Map<String, List<String>> exerciseDb;
  final Map<String, List<String>> archivedExercises;

  const _GroupStatsModal({
    required this.group,
    required this.sessions,
    required this.exerciseDb,
    required this.archivedExercises,
  });

  Map<String, List<ExerciseSet>> _getExerciseHistory() {
    final Map<String, List<ExerciseSet>> history = {};
    for (final session in sessions) {
      if (session.type == group) {
        for (final ex in session.exercises) {
          if (!history.containsKey(ex.name)) {
            history[ex.name] = [];
          }
          history[ex.name]!.add(ex);
        }
      }
    }
    return history;
  }

  @override
  Widget build(BuildContext context) {
    final exerciseHistory = _getExerciseHistory();
    final activeExercises = exerciseDb[group] ?? [];
    final archived = archivedExercises[group] ?? [];

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  group,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    labelColor: Color(0xFF3B82F6),
                    unselectedLabelColor: Color(0xFF64748B),
                    indicatorColor: Color(0xFF3B82F6),
                    tabs: [
                      Tab(text: 'ACTIVOS'),
                      Tab(text: 'ARCHIVADOS'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            if (activeExercises.isEmpty)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Text(
                                    'No hay ejercicios activos',
                                    style: TextStyle(color: Color(0xFF64748B)),
                                  ),
                                ),
                              )

                            else
                              ...activeExercises.map((exercise) {
                                final history = exerciseHistory[exercise] ?? [];
                                final pb = history.isEmpty ? null : history.reduce((a, b) => a.weight > b.weight ? a : b);
                                return GestureDetector(
                                  onTap: () => _showExerciseDetailModal(context, exercise, history),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E293B),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                exercise,
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                                              ),
                                              if (pb != null)
                                                Text(
                                                  'PB: ${pb.weight}kg x ${pb.reps}',
                                                  style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                                )
                                              else
                                                const Text(
                                                  'Sin registros',
                                                  style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                                ),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.chevron_right, color: Color(0xFF334155)),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                          ],
                        ),
                        ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            if (archived.isEmpty)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Text('No hay ejercicios archivados', style: TextStyle(color: Color(0xFF64748B))),
                                ),
                              )
                            else
                              ...archived.map((exercise) {
                                final history = exerciseHistory[exercise] ?? [];
                                final pb = history.isEmpty ? null : history.reduce((a, b) => a.weight > b.weight ? a : b);
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E293B).withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              exercise,
                                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF64748B)),
                                            ),
                                            if (pb != null)
                                              Text(
                                                'PB: ${pb.weight}kg x ${pb.reps}',
                                                style: const TextStyle(fontSize: 10, color: Color(0xFF475569)),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExerciseDetailModal(BuildContext context, String exercise, List<ExerciseSet> history) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      exercise,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: history.isEmpty
                  ? const Center(
                      child: Text('No hay historial', style: TextStyle(color: Color(0xFF64748B))),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        final set = history[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${set.weight}kg x ${set.reps}',
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                                  ),
                                  Text(
                                    set.time,
                                    style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}