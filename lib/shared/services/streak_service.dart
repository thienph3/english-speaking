import 'package:speakeng/shared/services/prefs_service.dart';

/// Tracks daily practice streak using SharedPreferences.
class StreakService {
  static const _keyCount = 'streak_count';
  static const _keyLastDate = 'streak_last_date';

  /// Returns current streak count, updating based on last practice date.
  static int getStreak() {
    final prefs = PrefsService.instance;
    final lastDate = prefs.getString(_keyLastDate);
    final count = prefs.getInt(_keyCount) ?? 0;

    if (lastDate == null) return 0;

    final today = _todayString();
    if (lastDate == today) return count;

    final yesterday = _dateString(DateTime.now().subtract(const Duration(days: 1)));
    if (lastDate == yesterday) return count;

    // Streak broken
    return 0;
  }

  /// Records today's practice and updates streak.
  static Future<void> recordPractice() async {
    final prefs = PrefsService.instance;
    final lastDate = prefs.getString(_keyLastDate);
    final count = prefs.getInt(_keyCount) ?? 0;
    final today = _todayString();

    if (lastDate == today) return; // Already recorded today

    final yesterday = _dateString(DateTime.now().subtract(const Duration(days: 1)));
    final newCount = (lastDate == yesterday) ? count + 1 : 1;

    await prefs.setInt(_keyCount, newCount);
    await prefs.setString(_keyLastDate, today);
  }

  static String _todayString() => _dateString(DateTime.now());

  static String _dateString(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
