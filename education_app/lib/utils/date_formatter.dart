class DateFormatter {
  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${_pluralize(difference.inMinutes, 'minute')} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${_pluralize(difference.inHours, 'hour')} ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} ${_pluralize(difference.inDays, 'day')} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${_pluralize(months, 'month')} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${_pluralize(years, 'year')} ago';
    }
  }

  static String _pluralize(int count, String word) {
    return count == 1 ? word : '${word}s';
  }

  static String formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
} 