import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/workout_provider.dart';
import '../../core/theme/theme_manager.dart';
import '../../widgets/common/custom_button.dart';
import 'main_screen.dart';
import '../../core/constants/exercise_database.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeManager>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final workout = Provider.of<WorkoutProvider>(context);

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildLanguageStep(theme, settings),
          _buildRoutineStep(theme, settings, workout),
        ],
      ),
    );
  }

  Widget _buildLanguageStep(ThemeManager theme, SettingsProvider settings) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Icon(Icons.language, size: 80, color: theme.accentColor),
          const SizedBox(height: 40),
          Text(
            settings.translate('language').toUpperCase(),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 40),
          _langBtn('ESPAÑOL', 'es', settings),
          const SizedBox(height: 12),
          _langBtn('ENGLISH', 'en', settings),
          const SizedBox(height: 12),
          _langBtn('العربية', 'ar', settings),
          const Spacer(),
          PrimaryButton(
            label: settings.translate('confirm').toUpperCase(),
            onPressed: () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
          ),
        ],
      ),
    );
  }

  Widget _langBtn(String label, String code, SettingsProvider settings) {
    final isSelected = settings.languageCode == code;
    return GestureDetector(
      onTap: () => settings.setLanguage(code),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Provider.of<ThemeManager>(context).accentColor.withOpacity(0.1) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSelected ? Provider.of<ThemeManager>(context).accentColor : Colors.white10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Provider.of<ThemeManager>(context).accentColor : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoutineStep(ThemeManager theme, SettingsProvider settings, WorkoutProvider workout) {
    final structures = ExerciseDatabase.routineStructures;
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Icon(Icons.fitness_center, size: 60, color: theme.accentColor),
          const SizedBox(height: 24),
          Text(
            settings.translate('routine_structure'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 8),
          Text(
            settings.translate('select_base'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              children: structures.keys.map((key) {
                String labelKey;
                switch (key) {
                  case 'PUSH PULL LEG': labelKey = 'ppl'; break;
                  case 'FULL BODY': labelKey = 'full_body'; break;
                  case 'UPPER LOWER': labelKey = 'upper_lower'; break;
                  case 'ARNOLD SPLIT': labelKey = 'arnold_split'; break;
                  case 'MI MEZCLA (ARNOLD+PPL)': labelKey = 'my_mix'; break;
                  case 'PERSONALIZADO': labelKey = 'custom'; break;
                  default: labelKey = 'custom';
                }
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () async {
                      // Actualizar grupos según la estructura
                      final newGroups = structures[key]!;
                      workout.updateConfig(workout.config.copyWith(groups: newGroups));
                      
                      // Marcar onboarding como completado
                      await settings.completeOnboarding();
                      
                      if (!mounted) return;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const MainScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1111), // Color oscuro según la imagen
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Center(
                        child: Text(
                          settings.translate(labelKey).toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
