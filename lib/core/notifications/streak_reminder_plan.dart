/// What a reminder says, which decides its text. A tap always opens the
/// Home, whatever the kind.
enum ReminderKind {
  /// The streak is alive and today is the last day to keep it.
  streakAtRisk,

  /// No streak to lose: an invitation to today's challenge.
  dailyInvite,

  /// Days without playing: a gentler nudge back to the map.
  comeBack,
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

/// The next few reminders, given when the player last played.
///
/// The first comes [idleDelay] after the last game, while the streak can
/// still be saved; the following ones fire at [reminderHour] on the days
/// after. With no game on record the player only gets the daily ones.
///
/// The whole plan is recomputed and rescheduled on every trigger — app
/// start, a finished match, the app going to the background — so nothing
/// has to be cancelled selectively: playing again simply moves the 24-hour
/// reminder forward.
///
/// Several reminders are planned at once because a device that is never
/// opened again cannot reschedule anything: the first is about the streak,
/// the following ones invite the player back, and then it stops. A reminder
/// the player ignores for [horizonDays] days is not one more reminder away
/// from working.
abstract final class StreakReminderPlanner {
  /// Inactivity before the first reminder.
  static const idleDelay = Duration(hours: 24);

  /// The daily reminder after that one: late afternoon, early enough to
  /// still play before midnight.
  static const reminderHour = 18;

  /// Reminders planned ahead.
  static const horizonDays = 3;

  /// Ids 1..[horizonDays]: always the same, so rescheduling replaces.
  static const firstId = 1;

  /// [lastPlayedDate] is the streak's `YYYY-MM-DD`; [lastGameAt] the exact
  /// time of the last recorded match, used when it falls on that day. A
  /// streak kept without a recorded match (a claimed reward) counts as
  /// played at [reminderHour].
  static List<PlannedReminder> plan({
    required String? lastPlayedDate,
    required DateTime? lastGameAt,
    required int currentStreak,
    required DateTime now,
  }) {
    final lastPlayed = DateTime.tryParse(lastPlayedDate ?? '');
    final today = DateTime(now.year, now.month, now.day);
    final times = <DateTime>[];
    var firstDaily = today;

    if (lastPlayed != null) {
      // A last date in the future (a clock moved back): stay quiet.
      if (_dayNumber(lastPlayed) > _dayNumber(today)) return const [];
      final playedAt =
          lastGameAt != null && _dayNumber(lastGameAt) == _dayNumber(lastPlayed)
          ? lastGameAt
          : DateTime(
              lastPlayed.year,
              lastPlayed.month,
              lastPlayed.day,
              reminderHour,
            );
      times.add(playedAt.add(idleDelay));
      // Daily reminders start the day after the 24-hour one.
      final dayAfter = DateTime(
        lastPlayed.year,
        lastPlayed.month,
        lastPlayed.day + 2,
      );
      if (dayAfter.isAfter(firstDaily)) firstDaily = dayAfter;
    }

    // One day more than the horizon, since the first ones may be past.
    for (var offset = 0; offset <= horizonDays; offset++) {
      times.add(
        DateTime(
          firstDaily.year,
          firstDaily.month,
          firstDaily.day + offset,
          reminderHour,
        ),
      );
    }

    final reminders = <PlannedReminder>[];
    for (final at in times) {
      if (reminders.length == horizonDays) break;
      if (!at.isAfter(now)) continue;
      final kind = _kindFor(at, lastPlayed, currentStreak);
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

  static ReminderKind _kindFor(
    DateTime day,
    DateTime? lastPlayed,
    int currentStreak,
  ) {
    if (lastPlayed == null) return ReminderKind.dailyInvite;
    final gap = _dayNumber(day) - _dayNumber(lastPlayed);
    // Played the day before: the streak ends at that midnight.
    if (gap <= 1 && currentStreak > 0) return ReminderKind.streakAtRisk;
    // A day or two off is still a regular; beyond that, someone drifting.
    return gap < 3 ? ReminderKind.dailyInvite : ReminderKind.comeBack;
  }

  /// Day number from the civil date, immune to daylight-saving hours, like
  /// the streak itself.
  static int _dayNumber(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;
}
