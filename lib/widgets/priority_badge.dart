import 'package:flutter/material.dart';
import '../models/task.dart';

class PriorityBadge extends StatelessWidget {
  final TaskPriority priority;

  const PriorityBadge({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color bg;
    Color fg;
    Color border;

    switch (priority) {
      case TaskPriority.high:
        fg = isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
        bg = isDark ? const Color(0x33EF4444) : const Color(0xFFFEE2E2);
        border = isDark ? const Color(0x55EF4444) : const Color(0xFFFECACA);
        break;
      case TaskPriority.medium:
        fg = isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
        bg = isDark ? const Color(0x33F59E0B) : const Color(0xFFFEF3C7);
        border = isDark ? const Color(0x55F59E0B) : const Color(0xFFFDE68A);
        break;
      case TaskPriority.low:
        fg = isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
        bg = isDark ? const Color(0x333B82F6) : const Color(0xFFDBEAFE);
        border = isDark ? const Color(0x553B82F6) : const Color(0xFFBFDBFE);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        priority.label.toUpperCase(),
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
