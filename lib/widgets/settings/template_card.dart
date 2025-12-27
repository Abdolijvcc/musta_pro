import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_manager.dart';

class TemplateCard extends StatelessWidget {
  final String title;
  final List<String> exercises;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const TemplateCard({
    super.key,
    required this.title,
    required this.exercises,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeManager>(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
        subtitle: Text(
          "${exercises.length} ejercicios: ${exercises.take(3).join(', ')}${exercises.length > 3 ? '...' : ''}",
          style: const TextStyle(fontSize: 10, color: Colors.white24),
        ),
        trailing: IconButton(
          icon: const Icon(LucideIcons.trash2, size: 16, color: Colors.white12),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
