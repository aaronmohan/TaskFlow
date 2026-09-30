import 'package:intl/intl.dart';

class DateFormatter {
  static String formatDueDate(DateTime? date) {
    if (date == null) return 'No due date';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    final diff = target.difference(today).inDays;
    if (diff == 0) return 'Due Today';
    if (diff == 1) return 'Due Tomorrow';
    if (diff == -1) return 'Overdue (Yesterday)';
    if (diff < -1) return 'Overdue (${DateFormat('MMM d').format(date)})';

    return 'Due ${DateFormat('MMM d').format(date)}';
  }

  static String formatFull(DateTime? date) {
    if (date == null) return 'Not set';
    return DateFormat('EEEE, MMMM d, y').format(date);
  }

  static String formatShort(DateTime? date) {
    if (date == null) return 'Not set';
    return DateFormat('MMM d, y').format(date);
  }
}
