import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_manager.dart';
import '../../core/constants/exercise_database.dart';

class ExerciseSearchDialog extends StatefulWidget {
  final Function(String) onSelected;

  const ExerciseSearchDialog({super.key, required this.onSelected});

  @override
  State<ExerciseSearchDialog> createState() => _ExerciseSearchDialogState();
}

class _ExerciseSearchDialogState extends State<ExerciseSearchDialog> {
  String selectedFromSearch = "";

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeManager>(context);

    return AlertDialog(
      title: const Text('AÑADIR EJERCICIO'),
      backgroundColor: theme.cardColor,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue value) {
              if (value.text == '') return const Iterable<String>.empty();
              return ExerciseDatabase.globalExerciseList.where((String option) {
                return option.contains(value.text.toUpperCase());
              });
            },
            onSelected: (String selection) => setState(() => selectedFromSearch = selection),
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Escribe ej: "PRESS"',
                  hintStyle: const TextStyle(color: Colors.white24),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: theme.accentColor.withOpacity(0.3)),
                  ),
                ),
                onChanged: (v) => setState(() => selectedFromSearch = v.toUpperCase()),
              );
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCELAR', style: TextStyle(color: Colors.white24)),
        ),
        TextButton(
          onPressed: () {
            if (selectedFromSearch.isNotEmpty) {
              widget.onSelected(selectedFromSearch);
            }
            Navigator.pop(context);
          },
          child: Text('AÑADIR', style: TextStyle(color: theme.accentColor)),
        ),
      ],
    );
  }
}
