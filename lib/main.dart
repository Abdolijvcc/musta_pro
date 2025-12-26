import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const TrainerProApp());
}

enum AppTheme { deepSlate, cyberNeon, crimsonBlood }

class ExerciseSet {
  final String name;
  final double weight;
  final double reps;
  final String note;
  final String time;
  final DateTime date;

  ExerciseSet({
    required this.name,
    required this.weight,
    required this.reps,
    required this.note,
    required this.time,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'weight': weight,
    'reps': reps,
    'note': note,
    'time': time,
    'date': date.toIso8601String(),
  };

  factory ExerciseSet.fromJson(Map<String, dynamic> json) => ExerciseSet(
    name: json['name'],
    weight: (json['weight'] as num).toDouble(),
    reps: (json['reps'] as num).toDouble(),
    note: json['note'] ?? '',
    time: json['time'],
    date: DateTime.parse(json['date']),
  );
}

class TrainingSession {
  final String id;
  final String type;
  final List<ExerciseSet> exercises;
  final DateTime date;

  TrainingSession({
    required this.id,
    required this.type,
    required this.exercises,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'exercises': exercises.map((e) => e.toJson()).toList(),
    'date': date.toIso8601String(),
  };

  factory TrainingSession.fromJson(Map<String, dynamic> json) => TrainingSession(
    id: json['id'],
    type: json['type'],
    exercises: (json['exercises'] as List)
        .map((e) => ExerciseSet.fromJson(e))
        .toList(),
    date: DateTime.parse(json['date']),
  );
}

class TrainerProApp extends StatefulWidget {
  const TrainerProApp({super.key});

  @override
  State<TrainerProApp> createState() => _TrainerProAppState();
}

class _TrainerProAppState extends State<TrainerProApp> {
  AppTheme _currentTheme = AppTheme.deepSlate;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('app_theme_index');
    if (themeIndex != null) {
      setState(() {
        _currentTheme = AppTheme.values[themeIndex];
      });
    }
  }

  Future<void> _cycleTheme() async {
    final nextTheme = AppTheme.values[(_currentTheme.index + 1) % AppTheme.values.length];
    setState(() {
      _currentTheme = nextTheme;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('app_theme_index', nextTheme.index);
  }

  ThemeData _getThemeData() {
    Color bg;
    Color primary;
    switch (_currentTheme) {
      case AppTheme.cyberNeon:
        bg = const Color(0xFF000000);
        primary = const Color(0xFF00F5FF);
        break;
      case AppTheme.crimsonBlood:
        bg = const Color(0xFF1A0B0B);
        primary = const Color(0xFFFF3131);
        break;
      default:
        bg = const Color(0xFF020617);
        primary = const Color(0xFF3B82F6);
    }

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      primaryColor: primary,
      fontFamily: 'Roboto',
      expansionTileTheme: const ExpansionTileThemeData(
        shape: Border.fromBorderSide(BorderSide(color: Colors.transparent)),
        collapsedShape: Border.fromBorderSide(BorderSide(color: Colors.transparent)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: bg,
        titleTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        contentTextStyle: const TextStyle(color: Colors.white70, fontSize: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _getThemeData(),
      home: MainScreen(currentTheme: _currentTheme, onToggleTheme: _cycleTheme),
    );
  }
}

class MainScreen extends StatefulWidget {
  final AppTheme currentTheme;
  final VoidCallback onToggleTheme;
  const MainScreen({super.key, required this.currentTheme, required this.onToggleTheme});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _activeTab = 0;
  bool _loading = true;
  bool _isSessionActive = false;
  bool _showSettings = false;

  Timer? _restTimer;
  int _secondsLeft = 180;
  int _defaultRestSeconds = 180;
  bool _showTimer = false;

  bool _isNewRecord = false;
  String _recordNote = "";

  List<TrainingSession> _sessions = [];
  List<String> _userGroups = ['TORSO', 'BRAZO', 'PECHO', 'ESPALDA', 'PIERNA'];

  // Base de datos para la búsqueda inteligente
  final List<String> _globalExerciseList = [
    'PRESS BANCA', 'PRESS INCLINADO', 'PRESS MILITAR', 'SENTADILLA', 'PESO MUERTO',
    'JALÓN AL PECHO', 'REMO CON BARRA', 'CURL DE BICEPS', 'EXTENSIÓN DE TRICEPS',
    'PRESS FRANCES', 'APERTURAS', 'LATERALES', 'ZANCADAS', 'DOMINADAS', 'REMO EN T'
  ];

  Map<String, List<String>> _archivedExercises = {};
  Map<String, List<String>> _exerciseDb = {
    'TORSO': ['PRESS BANCA', 'JALÓN AL PECHO ABIERTO', 'PRESS INCLINADO', 'REMO EN T'],
    'BRAZO': ['TRIC UNILAT', 'PRESS FRANCES', 'BÍCEPS SENTADO', 'LATERALES MAQUINA', 'BÍCEPS POLEA', 'MILITAR MÁQUINA'],
    'PECHO': ['PRESS BANCA', 'PRESS INCLINADO MANCUERNA', 'APERTURAS', 'EXTENSIÓN TRIC UNILAT', 'LATERALES MAQUINA', 'PRESS FRANCES', 'MILITAR MÁQUINA'],
    'ESPALDA': ['JALÓN AL PECHO ABIERTO', 'REMO EN T', 'PULL OVER', 'CURL SENTADO', 'BÍCEPS POLEA'],
    'PIERNA': ['ADDUCTOR', 'HAKA', 'FEMORAL TUMBADO', 'EXTENSIÓN', 'FEMORAL SENTADO']
  };
  String _plannerMode = 'sequential';
  Map<String, String> _weeklyPlan = {
    'Lunes': 'DESCANSO', 'Martes': 'DESCANSO', 'Miércoles': 'DESCANSO',
    'Jueves': 'DESCANSO', 'Viernes': 'DESCANSO', 'Sábado': 'DESCANSO', 'Domingo': 'DESCANSO'
  };

  String _activeWorkoutType = '';
  List<ExerciseSet> _currentSessionExercises = [];
  String _selectedExercise = '';
  final TextEditingController _weightCtrl = TextEditingController();
  final TextEditingController _repsCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();

  Color get _accentColor {
    switch (widget.currentTheme) {
      case AppTheme.cyberNeon: return const Color(0xFF00F5FF);
      case AppTheme.crimsonBlood: return const Color(0xFFFF3131);
      default: return const Color(0xFF3B82F6);
    }
  }

  Color get _cardColor {
    switch (widget.currentTheme) {
      case AppTheme.cyberNeon: return const Color(0xFF121212);
      case AppTheme.crimsonBlood: return const Color(0xFF2A1515);
      default: return const Color(0xFF0F172A);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final sessionsStr = prefs.getString('trainer_sessions');
      if (sessionsStr != null) {
        _sessions = (jsonDecode(sessionsStr) as List).map((s) => TrainingSession.fromJson(s)).toList();
      }
      final configStr = prefs.getString('trainer_config');
      if (configStr != null) {
        final config = jsonDecode(configStr);
        _userGroups = List<String>.from(config['groups'] ?? _userGroups);
        _exerciseDb = (config['exercises'] as Map).map((k, v) => MapEntry(k.toString(), List<String>.from(v)));
        _archivedExercises = (config['archivedExercises'] as Map? ?? {}).map((k, v) => MapEntry(k.toString(), List<String>.from(v)));
        _plannerMode = config['plannerMode'] ?? 'sequential';
        _weeklyPlan = Map<String, String>.from(config['weeklyPlan'] ?? _weeklyPlan);
        _defaultRestSeconds = config['defaultRestSeconds'] ?? 180;
      }
      _loading = false;
    });
  }

  Future<void> _saveConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final config = {
      'groups': _userGroups,
      'exercises': _exerciseDb,
      'archivedExercises': _archivedExercises,
      'plannerMode': _plannerMode,
      'weeklyPlan': _weeklyPlan,
      'defaultRestSeconds': _defaultRestSeconds,
    };
    await prefs.setString('trainer_config', jsonEncode(config));
  }

  void _startRestTimer({int? customSeconds}) {
    _restTimer?.cancel();
    setState(() {
      _secondsLeft = customSeconds ?? _defaultRestSeconds;
      _showTimer = true;
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        _restTimer?.cancel();
        _triggerVibration();
        setState(() => _showTimer = false);
      }
    });
  }

  void _triggerVibration() async {
    for (int i = 0; i < 3; i++) {
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  void _addSet() {
    if (_selectedExercise.isEmpty || _weightCtrl.text.isEmpty || _repsCtrl.text.isEmpty) return;
    final now = DateTime.now();
    double weight = double.tryParse(_weightCtrl.text.replaceAll(',', '.')) ?? 0;
    double reps = double.tryParse(_repsCtrl.text.replaceAll(',', '.')) ?? 0;

    final pb = _getPB(_selectedExercise);
    // Cada 2 reps extra cuenta como 1kg en la puntuación de récord
    double currentScore = weight + (reps / 2);
    double pbScore = pb != null ? (pb.weight + (pb.reps / 2)) : 0;

    bool isRecord = currentScore > pbScore;

    final newSet = ExerciseSet(
      name: _selectedExercise.toUpperCase(),
      weight: weight,
      reps: reps,
      note: _noteCtrl.text,
      time: "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}",
      date: now,
    );

    setState(() {
      _currentSessionExercises.insert(0, newSet);
      _weightCtrl.clear();
      _repsCtrl.clear();
      if (isRecord) {
        _isNewRecord = true;
        _recordNote = _noteCtrl.text;
      }
      _noteCtrl.clear();
    });

    if (isRecord) {
      Future.delayed(const Duration(seconds: 4), () => setState(() => _isNewRecord = false));
    }
    _startRestTimer();
  }

  ExerciseSet? _getPB(String exName) {
    if (exName.isEmpty) return null;
    List<ExerciseSet> allSets = _sessions.expand((s) => s.exercises).where((e) => e.name == exName.toUpperCase()).toList();
    if (allSets.isEmpty) return null;
    return allSets.reduce((a, b) {
      double scoreA = a.weight + (a.reps / 2);
      double scoreB = b.weight + (b.reps / 2);
      return scoreA > scoreB ? a : b;
    });
  }

  ExerciseSet? _getLastTime(String exName) {
    if (exName.isEmpty) return null;
    for (var session in _sessions) {
      for (var ex in session.exercises) {
        if (ex.name == exName.toUpperCase()) return ex;
      }
    }
    return null;
  }

  void _moveGroup(int index, int delta) {
    if (index + delta < 0 || index + delta >= _userGroups.length) return;
    setState(() {
      final item = _userGroups.removeAt(index);
      _userGroups.insert(index + delta, item);
      _saveConfig();
    });
  }

  void _archiveExercise(String group, String ex) {
    setState(() {
      _exerciseDb[group]!.remove(ex);
      _archivedExercises[group] ??= [];
      _archivedExercises[group]!.add(ex);
      _saveConfig();
    });
  }

  void _unarchiveExercise(String group, String ex) {
    setState(() {
      _archivedExercises[group]!.remove(ex);
      _exerciseDb[group]!.add(ex);
      _saveConfig();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              Expanded(child: IndexedStack(index: _activeTab, children: [_buildAddTab(), _buildHistoryTab(), _buildStatsTab()])),
              if (!_isSessionActive) _buildBottomNav(),
            ],
          ),
          if (_showTimer) _buildTimerFloating(),
        ],
      ),
    );
  }

  Widget _buildTimerFloating() {
    return Positioned(
      bottom: _isSessionActive ? 40 : 110,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _accentColor.withOpacity(0.5)),
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.timer, color: _accentColor, size: 16),
            const SizedBox(width: 8),
            Text(
              "${(_secondsLeft ~/ 60)}:${(_secondsLeft % 60).toString().padLeft(2, '0')}",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() { _restTimer?.cancel(); _showTimer = false; }),
              child: const Icon(LucideIcons.x, color: Colors.white24, size: 14),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    IconData themeIcon;
    switch (widget.currentTheme) {
      case AppTheme.cyberNeon: themeIcon = LucideIcons.zap; break;
      case AppTheme.crimsonBlood: themeIcon = LucideIcons.flame; break;
      default: themeIcon = LucideIcons.moon;
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 24, 20),
      color: _cardColor.withOpacity(0.8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: Icon(themeIcon, color: _accentColor, size: 24), onPressed: widget.onToggleTheme),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
              children: [
                const TextSpan(text: 'TRAINER', style: TextStyle(color: Colors.white)),
                TextSpan(text: ' PRO', style: TextStyle(color: Color(0xFF3B82F6))),
              ],
            ),
          ),
          (_activeTab == 0 || _isSessionActive)
              ? (_isSessionActive
              ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: _accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Text(_activeWorkoutType, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: _accentColor)),
          )
              : IconButton(
            icon: Icon(_showSettings ? LucideIcons.x : LucideIcons.settings, size: 20, color: _showSettings ? _accentColor : Colors.white24),
            onPressed: () => setState(() => _showSettings = !_showSettings),
          ))
              : const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildAddTab() {
    if (_isSessionActive) return _buildActiveWorkoutView();
    if (_showSettings) return _buildFullSettings();

    final suggestion = _getSuggestion();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        GestureDetector(
          onTap: () => suggestion['type'] == 'DESCANSO' ? null : _startWorkout(suggestion['type']!),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: suggestion['type'] == 'DESCANSO' ? LinearGradient(colors: [_cardColor, Colors.black]) : LinearGradient(colors: [_accentColor.withOpacity(0.8), _accentColor]),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('RECOMENDACIÓN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70)),
              Text(suggestion['type']!, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
              Text(suggestion['reason']!, style: const TextStyle(fontSize: 10, color: Colors.white)),
            ]),
          ),
        ),
        const SizedBox(height: 35),
        const Text('MIS RUTINAS ACTIVAS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white38, letterSpacing: 2)),
        const SizedBox(height: 15),
        ..._userGroups.map((group) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.08))),
          child: ListTile(
            title: Text(group, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
            trailing: Icon(LucideIcons.chevronRight, size: 18, color: _accentColor),
            onTap: () => _startWorkout(group),
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildFullSettings() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _settingTitle('DESCANSO ENTRE SERIES'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          margin: const EdgeInsets.only(top: 10, bottom: 25),
          decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(15)),
          child: Row(children: [
            Text('${_defaultRestSeconds}s', style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(icon: const Icon(LucideIcons.minus), onPressed: () => setState(() { _defaultRestSeconds = (_defaultRestSeconds - 10).clamp(30, 600); _saveConfig(); })),
            IconButton(icon: const Icon(LucideIcons.plus), onPressed: () => setState(() { _defaultRestSeconds = (_defaultRestSeconds + 10).clamp(30, 600); _saveConfig(); })),
          ]),
        ),

        _settingTitle('MODO DE PLANIFICACIÓN'),
        Row(children: [
          _modeBtn('CICLO', 'sequential'),
          const SizedBox(width: 10),
          _modeBtn('CALENDARIO', 'calendar'),
        ]),
        const SizedBox(height: 25),

        if (_plannerMode == 'calendar') ...[
          _settingTitle('ASIGNACIÓN POR DÍAS'),
          const SizedBox(height: 10),
          ..._weeklyPlan.keys.map((day) => _daySelector(day)),
        ] else ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _settingTitle('ORDEN DEL CICLO'),
              TextButton.icon(
                onPressed: _promptAddGroup,
                icon: Icon(LucideIcons.plus, size: 12, color: _accentColor),
                label: Text('AÑADIR GRUPO', style: TextStyle(fontSize: 9, color: _accentColor)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._userGroups.asMap().entries.map((entry) => _groupConfigCard(entry.key, entry.value)),
        ],
      ],
    );
  }

  Widget _settingTitle(String t) => Text(t, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white38, letterSpacing: 1.5));

  Widget _modeBtn(String l, String m) => Expanded(child: GestureDetector(
    onTap: () => setState(() { _plannerMode = m; _saveConfig(); }),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(color: _plannerMode == m ? _accentColor : _cardColor, borderRadius: BorderRadius.circular(12)),
      child: Center(child: Text(l, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
    ),
  ));

  Widget _daySelector(String day) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 15),
    decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      Expanded(child: Text(day, style: const TextStyle(fontSize: 12))),
      DropdownButton<String>(
        value: _weeklyPlan[day],
        underline: const SizedBox(),
        dropdownColor: _cardColor,
        items: ['DESCANSO', ..._userGroups].map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 10, color: Colors.white)))).toList(),
        onChanged: (v) => setState(() { _weeklyPlan[day] = v!; _saveConfig(); }),
      )
    ]),
  );

  Widget _groupConfigCard(int idx, String name) => Container(
    margin: const EdgeInsets.only(bottom: 15),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.05))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1))),
        IconButton(icon: const Icon(LucideIcons.trash2, size: 16, color: Colors.redAccent), onPressed: () => _promptDeleteGroup(idx, name)),
        IconButton(icon: const Icon(LucideIcons.arrowUp, size: 16), onPressed: () => _moveGroup(idx, -1)),
        IconButton(icon: const Icon(LucideIcons.arrowDown, size: 16), onPressed: () => _moveGroup(idx, 1)),
      ]),
      const SizedBox(height: 10),
      const Text('EJERCICIOS ACTIVOS', style: TextStyle(fontSize: 8, color: Colors.white24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [
        ...(_exerciseDb[name] ?? []).map((ex) => Container(
          padding: const EdgeInsets.only(left: 10),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(ex, style: const TextStyle(fontSize: 9)),
            IconButton(
                icon: const Icon(LucideIcons.archive, size: 12, color: Colors.orangeAccent),
                onPressed: () => _archiveExercise(name, ex)
            ),
          ]),
        )),
        IconButton(icon: const Icon(LucideIcons.plusCircle, size: 20, color: Colors.greenAccent), onPressed: () => _promptAddExercise(name)),
      ]),
      if (_archivedExercises[name]?.isNotEmpty == true) ...[
        const SizedBox(height: 15),
        const Text('ARCHIVADOS', style: TextStyle(fontSize: 8, color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: _archivedExercises[name]!.map((ex) => GestureDetector(
          onTap: () => _unarchiveExercise(name, ex),
          child: Chip(
            backgroundColor: Colors.white10,
            label: Text(ex, style: const TextStyle(fontSize: 8, color: Colors.white38)),
            avatar: const Icon(LucideIcons.rotateCcw, size: 10, color: Colors.white38),
          ),
        )).toList()),
      ]
    ]),
  );

  void _promptAddExercise(String group) {
    String selectedFromSearch = "";
    showDialog(context: context, builder: (c) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('AÑADIR EJERCICIO'),
        backgroundColor: _cardColor,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue value) {
                if (value.text == '') return const Iterable<String>.empty();
                return _globalExerciseList.where((String option) {
                  return option.contains(value.text.toUpperCase());
                });
              },
              onSelected: (String selection) => selectedFromSearch = selection,
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Escribe ej: "PRESS"',
                    hintStyle: const TextStyle(color: Colors.white24),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: _accentColor.withOpacity(0.3))),
                  ),
                  onChanged: (v) => selectedFromSearch = v.toUpperCase(),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('CANCELAR', style: TextStyle(color: Colors.white24))),
          TextButton(onPressed: () {
            if (selectedFromSearch.isNotEmpty) {
              setState(() {
                _exerciseDb[group] ??= [];
                if (!_exerciseDb[group]!.contains(selectedFromSearch)) {
                  _exerciseDb[group]!.add(selectedFromSearch);
                }
                _saveConfig();
              });
            }
            Navigator.pop(c);
          }, child: Text('AÑADIR', style: TextStyle(color: _accentColor))),
        ],
      ),
    ));
  }

  void _promptAddGroup() {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (c) => AlertDialog(
      title: const Text('NUEVA RUTINA / GRUPO'),
      backgroundColor: _cardColor,
      content: TextField(
        controller: ctrl,
        autofocus: true,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Ej: BRAZO, PIERNA, FULL BODY...',
          hintStyle: const TextStyle(color: Colors.white24),
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: _accentColor.withOpacity(0.3))),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('CANCELAR', style: TextStyle(color: Colors.white24))),
        TextButton(onPressed: () {
          if (ctrl.text.isNotEmpty) {
            String name = ctrl.text.toUpperCase();
            setState(() {
              _userGroups.add(name);
              _exerciseDb[name] = [];
              _saveConfig();
            });
          }
          Navigator.pop(c);
        }, child: Text('CREAR', style: TextStyle(color: _accentColor))),
      ],
    ));
  }

  void _promptDeleteGroup(int index, String name) {
    showDialog(context: context, builder: (c) => AlertDialog(
      title: const Text('¿ELIMINAR GRUPO?'),
      content: Text('Esto quitará $name de tus rutinas activas.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('CANCELAR', style: TextStyle(color: Colors.white24))),
        TextButton(onPressed: () {
          setState(() {
            _userGroups.removeAt(index);
            _saveConfig();
          });
          Navigator.pop(c);
        }, child: const Text('ELIMINAR', style: TextStyle(color: Colors.redAccent))),
      ],
    ));
  }

  Widget _buildActiveWorkoutView() {
    final pb = _getPB(_selectedExercise);
    final last = _getLastTime(_selectedExercise);

    // Si la anterior vez es récord, no mostrarla doble
    bool lastIsRecord = (pb != null && last != null) &&
        (last.weight == pb.weight && last.reps == pb.reps);

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('ENTRENANDO', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            Row(
              children: [
                IconButton(
                  onPressed: () => _startRestTimer(), // Usa el tiempo de descanso elegido
                  icon: Icon(LucideIcons.timer, color: _accentColor, size: 20),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _finishWorkout,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                      color: Colors.redAccent.withOpacity(0.1),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: const [
                      Icon(LucideIcons.check, size: 14, color: Colors.redAccent),
                      SizedBox(width: 8),
                      Text('FINALIZAR', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.w900)),
                    ]),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      Expanded(child: ListView(padding: const EdgeInsets.symmetric(horizontal: 24), children: [
        Wrap(spacing: 8, runSpacing: 8, children: (_exerciseDb[_activeWorkoutType] ?? []).map((ex) => GestureDetector(
          onTap: () => setState(() => _selectedExercise = ex),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _selectedExercise == ex ? _accentColor : _cardColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(ex, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        )).toList()),
        const SizedBox(height: 25),

        // MOSTRAR RÉCORD Y ANTERIOR SEGÚN LÓGICA
        if (pb != null) _historyDisplayBox(lastIsRecord ? "RÉCORD / ANTERIOR" : "RÉCORD", pb, true),
        if (pb != null && !lastIsRecord && last != null) const SizedBox(height: 10),
        if (!lastIsRecord && last != null) _historyDisplayBox("VEZ ANTERIOR", last, false),

        const SizedBox(height: 25),
        Row(children: [_numInput(_weightCtrl, 'PESO'), const SizedBox(width: 15), _numInput(_repsCtrl, 'REPS')]),
        const SizedBox(height: 15),
        TextField(
            controller: _noteCtrl,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
                hintText: 'OPINIÓN / NOTA DE LA SERIE',
                filled: true,
                fillColor: _cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)
            )
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _addSet,
          style: ElevatedButton.styleFrom(
            backgroundColor: _accentColor,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          child: const Text('GUARDAR SERIE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        const SizedBox(height: 25),
        ..._currentSessionExercises.map((s) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: _cardColor.withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text("${s.name}: ${s.weight}kg x ${s.reps.toInt()}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
              Text(s.time, style: const TextStyle(fontSize: 10, color: Colors.white24))
            ]),
            if (s.note.isNotEmpty) Text(s.note, style: const TextStyle(fontSize: 10, color: Colors.white54, fontStyle: FontStyle.italic)),
          ]),
        )).toList(),
      ])),
    ]);
  }

  Widget _historyDisplayBox(String title, ExerciseSet set, bool isPB) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(15)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(title, style: TextStyle(fontSize: 10, color: isPB ? Colors.amber : Colors.white38, fontWeight: FontWeight.bold)),
          IconButton(
              icon: const Icon(LucideIcons.copy, size: 16),
              onPressed: () => setState(() => _weightCtrl.text = set.weight.toString()) // Solo peso
          ),
        ]),
        Text("${set.weight}kg x ${set.reps.toInt()}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        if (set.note.isNotEmpty) Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text("Opinión: ${set.note}", style: const TextStyle(fontSize: 10, color: Colors.white54, fontStyle: FontStyle.italic)),
        ),
      ]),
    );
  }

  Widget _buildHistoryTab() {
    return _sessions.isEmpty
        ? const Center(child: Text('SIN ACTIVIDAD', style: TextStyle(color: Colors.white12, fontSize: 10)))
        : ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _sessions.length,
      itemBuilder: (c, i) {
        final session = _sessions[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(15)),
          child: ExpansionTile(
            iconColor: _accentColor,
            title: Text(session.type, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            subtitle: Text("${session.date.day}/${session.date.month} - ${session.exercises.length} series", style: const TextStyle(fontSize: 10, color: Colors.white24)),
            children: session.exercises.map((s) => ListTile(
              dense: true,
              title: Text("${s.name}: ${s.weight}kg x ${s.reps.toInt()}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              trailing: Text(s.time, style: const TextStyle(fontSize: 9, color: Colors.white12)),
            )).toList(),
          ),
        );
      },
    );
  }

  Widget _buildStatsTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: _userGroups.map((g) => Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(20)),
        child: ExpansionTile(
          title: Text(g, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          children: (_exerciseDb[g] ?? []).map((ex) {
            final pb = _getPB(ex);
            final history = _sessions.expand((s) => s.exercises).where((e) => e.name == ex.toUpperCase()).toList();
            return _buildStatDetail(ex, pb, history);
          }).toList(),
        ),
      )).toList(),
    );
  }

  Widget _buildStatDetail(String ex, ExerciseSet? pb, List<ExerciseSet> history) {
    // Gráfica basada en fórmula Peso + (Reps / 2)
    final spotsStrength = history.reversed.toList().asMap().entries.map((e) {
      double score = e.value.weight + (e.value.reps / 2);
      return FlSpot(e.key.toDouble(), score);
    }).toList();

    return ExpansionTile(
      title: Text(ex, style: const TextStyle(fontSize: 11, color: Colors.white60)),
      trailing: Text(pb != null ? "${pb.weight}kg" : "-", style: TextStyle(color: _accentColor, fontWeight: FontWeight.bold)),
      children: [
        if (history.isNotEmpty) ...[
          Container(
            height: 140,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: LineChart(LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spotsStrength,
                    isCurved: true,
                    color: _accentColor,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [_accentColor.withOpacity(0.3), _accentColor.withOpacity(0)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                  ),
                ]
            )),
          ),
          ...history.take(5).map((e) => ListTile(
            dense: true,
            title: Text("${e.weight}kg x ${e.reps.toInt()}", style: const TextStyle(fontSize: 10)),
            subtitle: Text("${e.date.day}/${e.date.month}", style: const TextStyle(fontSize: 8, color: Colors.white24)),
          )).toList(),
        ]
      ],
    );
  }

  Widget _numInput(TextEditingController ctrl, String label) {
    return Expanded(child: TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 10, color: Colors.white38),
        filled: true,
        fillColor: _cardColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    ));
  }

  void _startWorkout(String type) {
    setState(() {
      _activeWorkoutType = type;
      _currentSessionExercises = [];
      _isSessionActive = true;
      _showSettings = false;
      _selectedExercise = _exerciseDb[type]?.isNotEmpty == true ? _exerciseDb[type]![0] : '';
    });
  }

  void _finishWorkout() {
    _restTimer?.cancel();
    if (_currentSessionExercises.isNotEmpty) {
      _sessions.insert(0, TrainingSession(id: DateTime.now().toString(), type: _activeWorkoutType, exercises: List.from(_currentSessionExercises), date: DateTime.now()));
      _saveSessions();
    }
    setState(() {
      _isSessionActive = false;
      _activeTab = 1;
      _showTimer = false;
    });
  }

  Future<void> _saveSessions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('trainer_sessions', jsonEncode(_sessions.map((s) => s.toJson()).toList()));
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.only(bottom: 40, top: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(0, LucideIcons.play, 'HOY'),
          _navItem(1, LucideIcons.calendar, 'HISTORIAL'),
          _navItem(2, LucideIcons.trendingUp, 'PROGRESO'),
        ],
      ),
    );
  }

  Widget _navItem(int i, IconData ic, String l) => GestureDetector(
    onTap: () => setState(() { _activeTab = i; _showSettings = false; }),
    child: Column(children: [
      Icon(ic, color: _activeTab == i ? _accentColor : Colors.white24, size: 20),
      const SizedBox(height: 4),
      Text(l, style: TextStyle(fontSize: 8, color: _activeTab == i ? _accentColor : Colors.white24, fontWeight: FontWeight.bold)),
    ]),
  );

  Map<String, String> _getSuggestion() {
    if (_plannerMode == 'calendar') {
      final days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
      String dayName = days[DateTime.now().weekday - 1];
      String task = _weeklyPlan[dayName] ?? 'DESCANSO';
      return {'type': task, 'reason': 'Hoy es $dayName'};
    } else {
      if (_sessions.isEmpty || _userGroups.isEmpty) return {'type': _userGroups.isNotEmpty ? _userGroups[0] : 'CREA UNA RUTINA', 'reason': 'Comienza hoy'};
      String lastType = _sessions[0].type;
      int lastIdx = _userGroups.indexOf(lastType);
      if (lastIdx == -1) return {'type': _userGroups[0], 'reason': 'Nueva rutina'};
      int nextIdx = (lastIdx + 1) % _userGroups.length;
      return {'type': _userGroups[nextIdx], 'reason': 'Siguiente en el ciclo'};
    }
  }
}