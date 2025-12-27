import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../core/theme/theme_manager.dart';
import '../core/theme/app_theme.dart';
import '../providers/workout_provider.dart';
import '../widgets/common/timer_widget.dart';
import 'tabs/workout_tab.dart';
import 'tabs/history_tab.dart';
import 'tabs/stats_tab.dart';
import 'settings/settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _activeTab = 0;

  final List<Widget> _tabs = [
    const WorkoutTab(),
    const HistoryTab(),
    const StatsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeManager>(context);
    final workout = Provider.of<WorkoutProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);

    // Determinar icono del tema para el header
    IconData themeIcon;
    switch (theme.currentTheme) {
      case AppTheme.cyberNeon: themeIcon = LucideIcons.zap; break;
      case AppTheme.crimsonBlood: themeIcon = LucideIcons.flame; break;
      case AppTheme.goldRush: themeIcon = LucideIcons.award; break;
      default: themeIcon = LucideIcons.moon;
    }

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              // Header dinámico
              _buildHeader(theme, workout, themeIcon, settings),
              // Cuerpo de la pestaña activa
              Expanded(
                child: IndexedStack(
                  index: _activeTab,
                  children: _tabs,
                ),
              ),
              // Bottom Navigation
              if (!workout.isSessionActive) _buildBottomNav(theme, settings),
            ],
          ),
          const TimerWidget(),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeManager theme, WorkoutProvider workout, IconData themeIcon, SettingsProvider settings) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 24, 20),
      color: theme.cardColor.withOpacity(0.8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(themeIcon, color: theme.accentColor, size: 24),
            onPressed: () => theme.cycleTheme(),
          ),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
              children: [
                TextSpan(text: settings.translate('onboarding_title').split(' ')[0], style: const TextStyle(color: Colors.white)),
                TextSpan(text: ' ${settings.translate('onboarding_title').split(' ').sublist(1).join(' ')}', style: TextStyle(color: theme.accentColor)),
              ],
            ),
          ),
          if (_activeTab == 0 && !workout.isSessionActive)
            IconButton(
              icon: const Icon(LucideIcons.settings, size: 20, color: Colors.white24),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              ),
            )
          else if (workout.isSessionActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                workout.activeWorkoutType,
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: theme.accentColor),
              ),
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildBottomNav(ThemeManager theme, SettingsProvider settings) {
    return Container(
      padding: const EdgeInsets.only(bottom: 40, top: 15),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.5),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(0, LucideIcons.play, settings.translate('today'), theme),
          _navItem(1, LucideIcons.calendar, settings.translate('history'), theme),
          _navItem(2, LucideIcons.trendingUp, settings.translate('progress'), theme),
        ],
      ),
    );
  }

  Widget _navItem(int i, IconData ic, String l, ThemeManager theme) => GestureDetector(
    onTap: () => setState(() => _activeTab = i),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(ic, color: _activeTab == i ? theme.accentColor : Colors.white24, size: 20),
        const SizedBox(height: 4),
        Text(
          l,
          style: TextStyle(
            fontSize: 8,
            color: _activeTab == i ? theme.accentColor : Colors.white24,
            fontWeight: FontWeight.bold
          )
        ),
      ],
    ),
  );
}
