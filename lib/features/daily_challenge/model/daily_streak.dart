/// Consecutive days with the daily challenge completed.
///
/// Derived from the set of completed dates rather than stored as a counter:
/// a counter has to be incremented, reset and kept in step with the rows it
/// summarises, and any missed write corrupts it forever. Recomputing from
/// the rows cannot drift, and a completion synced in from another device
/// fixes the streak on its own.
class DailyStreak {
  const DailyStreak({required this.current, required this.longest});

  /// Build from `'YYYY-MM-DD'` keys of completed challenges.
  ///
  /// The current streak stays alive through [today] until it is completed:
  /// having played yesterday but not yet today still shows yesterday's run,
  /// the way players expect ("don't lose your 5-day streak!").
  factory DailyStreak.fromDates(Iterable<String> completedDates, String today) {
    final days = completedDates.map(_dayNumber).whereType<int>().toSet();
    final todayNumber = _dayNumber(today);
    if (days.isEmpty || todayNumber == null) {
      return const DailyStreak(current: 0, longest: 0);
    }

    var anchor = days.contains(todayNumber) ? todayNumber : todayNumber - 1;
    var current = 0;
    while (days.contains(anchor)) {
      current++;
      anchor--;
    }

    var longest = 0;
    for (final day in days) {
      // Only count from the start of each run.
      if (days.contains(day - 1)) continue;
      var length = 1;
      while (days.contains(day + length)) {
        length++;
      }
      if (length > longest) longest = length;
    }

    return DailyStreak(current: current, longest: longest);
  }

  static const empty = DailyStreak(current: 0, longest: 0);

  final int current;
  final int longest;

  /// Whole days since 1970-01-01 in UTC, or null for a malformed key.
  static int? _dayNumber(String key) {
    final parsed = DateTime.tryParse('${key}T00:00:00Z');
    if (parsed == null) return null;
    return parsed.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
  }
}
