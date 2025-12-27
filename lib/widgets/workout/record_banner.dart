import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_manager.dart';

class RecordBanner extends StatelessWidget {
  final String message;
  final bool visible;

  const RecordBanner({super.key, required this.message, this.visible = false});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeManager>(context);
    if (!visible) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events, color: Colors.black, size: 20),
          const SizedBox(width: 10),
          Text(
            message,
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
