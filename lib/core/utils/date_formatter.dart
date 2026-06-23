import 'package:intl/intl.dart';

/// Utility class for date formatting
class DateFormatter {
  /// Format date to 'MMM dd, yyyy' (e.g., Jan 01, 2023)
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }
  
  /// Format date to 'EEEE, MMM dd, yyyy' (e.g., Monday, Jan 01, 2023)
  static String formatDateWithDay(DateTime date) {
    return DateFormat('EEEE, MMM dd, yyyy').format(date);
  }
  
  /// Format date to 'HH:mm' (e.g., 14:30)
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }
  
  /// Format date to 'MMM dd, yyyy HH:mm' (e.g., Jan 01, 2023 14:30)
  static String formatDateTime(DateTime date) {
    return DateFormat('MMM dd, yyyy HH:mm').format(date);
  }

  /// Format a (possibly UTC) timestamp to local 12-hour date+time
  /// (e.g., Jun 23, 2026 · 04:45 PM)
  static String formatDateTime12(DateTime date) {
    return DateFormat('MMM dd, yyyy · hh:mm a').format(date.toLocal());
  }

  /// Format date to relative time (e.g., 2 hours ago, Yesterday, etc.)
  static String formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} ${(difference.inDays / 365).floor() == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} ${(difference.inDays / 30).floor() == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()} ${(difference.inDays / 7).floor() == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays > 0) {
      return difference.inDays == 1 ? 'Yesterday' : '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
}
