import 'package:memory_companion/core/routes/route_paths.dart';

/// What a reminder says, which decides its text and where a tap leads.
enum ReminderKind {
  /// The streak is alive and today is the last day to keep it.
  streakAtRisk,

  /// No streak to lose: an invitation to today's challenge.
  dailyInvite,

  /// Days without playing: a gentler nudge back to the map.
  comeBack;

  /// The screen a tap opens, on top of the Home.
  String get route => switch (this) {
    streakAtRisk || dailyInvite => RoutePaths.dailyChallenge,
    comeBack => RoutePaths.levelMap,
  };
}

/// One local notification to schedule.
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.at,
    required this.kind,
    this.streak = 0,
  });

  final int id;

  /// Local wall-clock time it fires.
  final DateTime at;
  final ReminderKind kind;

  /// The streak at stake, for [ReminderKind.streakAtRisk].
  final int streak;

  @override
  String toString() => 'PlannedReminder($id, $at, ${kind.name}, $streak)';
}

/// The reminders for the next few evenings, given when the player last
/// played.
///
/// The whole plan is recomputed and rescheduled on every trigger — app
/// start, a finished match, the app going to the background — so nothing
/// has to be cancelled selectively: playing today simply produces a plan
/// that skips tonight.
///
/// Several evenings are planned at once because a device that is never
/// opened again cannot reschedule anything: tonight's reminder is about the
/// streak, the following ones invite the player back, and then it stops.
/// A reminder the player ignores for [horizonDays] days is not one more
/// reminder away from working.
abstract final class StreakReminderPlanner {
  /// The evening reminder: late enough to follow the day's routine, early
  /// enough to still play before midnight.
  static const reminderHour = 20;

  /// Evenings planned ahead.
  static const horizonDays = 3;

  /// Ids 1..[horizonDays]: always the same, so rescheduling replaces.
  static const firstId = 1;

  static List<PlannedReminder> plan({
    required String? lastPlayedDate,
    required int currentStreak,
    required DateTime now,
  }) {
    final lastPlayed = DateTime.tryParse(lastPlayedDate ?? '');
    final today = DateTime(now.year, now.month, now.day);
    final reminders = <PlannedReminder>[];

    // One evening more than the horizon, since tonight may be skipped. A
    // bound rather than "until full": a last date in the future (a clock
    // moved back) would otherwise skip evening after evening.
    for (
      var offset = 0;
      offset <= horizonDays && reminders.length < horizonDays;
      offset++
    ) {
      final day = DateTime(today.year, today.month, today.day + offset);
      final at = DateTime(day.year, day.month, day.day, reminderHour);
      if (!at.isAfter(now)) continue;

      final kind = _kindFor(day, lastPlayed, currentStreak);
      // Already played that day (today): nothing to remind.
      if (kind == null) continue;

      reminders.add(
        PlannedReminder(
          id: firstId + reminders.length,
          at: at,
          kind: kind,
          streak: kind == ReminderKind.streakAtRisk ? currentStreak : 0,
        ),
      );
    }
    return reminders;
  }

  static ReminderKind? _kindFor(
    DateTime day,
    DateTime? lastPlayed,
    int currentStreak,
  ) {
    if (lastPlayed == null) return ReminderKind.dailyInvite;
    final gap = _dayNumber(day) - _dayNumber(lastPlayed);
    // Played that day, or the clock went back: stay quiet.
    if (gap <= 0) return null;
    // Played the day before: the streak ends at that midnight.
    if (gap == 1 && currentStreak > 0) return ReminderKind.streakAtRisk;
    // A day or two off is still a regular; beyond that, someone drifting.
    return gap < 3 ? ReminderKind.dailyInvite : ReminderKind.comeBack;
  }

  /// Day number from the civil date, immune to daylight-saving hours, like
  /// the streak itself.
  static int _dayNumber(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;
}
