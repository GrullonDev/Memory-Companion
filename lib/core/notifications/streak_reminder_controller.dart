import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/notifications/reminder_notifier.dart';
import 'package:memory_companion/core/notifications/streak_reminder_plan.dart';
import 'package:memory_companion/core/routes/route_paths.dart';
import 'package:memory_companion/features/game/controller/game_controller.dart';
import 'package:memory_companion/features/player/controller/player_controller.dart';

/// The app's navigator, so a notification tapped while the app runs can
/// reach the Home from outside the widget tree.
final appNavigatorKey = GlobalKey<NavigatorState>();

/// Scheduled notifications exist on Android and iOS only.
final reminderNotifierProvider = Provider<ReminderNotifier>((ref) {
  final supported =
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  return supported ? LocalReminderNotifier() : const NoopReminderNotifier();
});

/// The clock reminders are planned from. Overridden in tests.
final reminderClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// The language reminders are written in: the app's, not the device's.
/// Overridden in tests.
final reminderLanguageProvider = Provider<String Function()>(
  (ref) =>
      () => FlutterLocalization.instance.currentLocale?.languageCode ?? 'es',
);

/// The screen a tapped notification asked for, until the Home opens it.
///
/// A route rather than a navigation: on a cold start the tap arrives before
/// the splash has done its work, and only the Home knows it is safe to go.
class PendingNotificationRoute extends Notifier<String?> {
  /// The only screens a notification may open. Reminders scheduled by older
  /// versions pointed elsewhere; those taps just open the app.
  static const allowed = {RoutePaths.home};

  /// Whether the Home has been shown since the app started, i.e. whether
  /// the splash is behind us.
  bool homeReady = false;

  @override
  String? build() => null;

  void request(String? route) {
    if (!allowed.contains(route)) return;
    state = route;
  }

  /// Hands the pending route over once, and forgets it.
  String? take() {
    final route = state;
    state = null;
    return route;
  }
}

final pendingNotificationRouteProvider =
    NotifierProvider<PendingNotificationRoute, String?>(
      PendingNotificationRoute.new,
    );

/// Keeps the streak reminders in step with the player.
///
/// Every trigger replaces the whole plan ([StreakReminderPlanner]): the app
/// starting, the player's streak or last played date changing (a finished
/// match, the daily challenge), and the app going to or coming back from
/// the background. Playing again therefore moves the 24-hour reminder
/// forward, with no bookkeeping of which notification is which.
class StreakReminderController extends Notifier<void> {
  bool _initialized = false;
  bool _permissionAsked = false;

  ReminderNotifier get _notifier => ref.read(reminderNotifierProvider);

  @override
  void build() {
    ref.listen(
      localPlayerProvider.select(
        (player) => switch (player.value) {
          final p? => (p.lastPlayedDate, p.currentStreak),
          null => null,
        },
      ),
      (_, next) {
        if (next != null) reschedule();
      },
      fireImmediately: true,
    );
  }

  /// Sets the plugin up and plans the first reminders. A notification that
  /// launched the app becomes the pending route.
  Future<void> start() async {
    if (_initialized) return;
    try {
      final launchRoute = await _notifier.initialize(onTap: _onTap);
      _initialized = true;
      ref.read(pendingNotificationRouteProvider.notifier).request(launchRoute);
      await reschedule();
    } on Exception catch (error) {
      // Reminders are a nicety: the game must start without them.
      debugPrint('Streak reminders unavailable: $error');
    }
  }

  /// Asks for permission the first time the Home shows in this run. The
  /// system itself stops asking once the player has answered.
  Future<void> requestPermissionOnce() async {
    if (_permissionAsked) return;
    _permissionAsked = true;
    try {
      if (await _notifier.requestPermission()) await reschedule();
    } on Exception catch (error) {
      debugPrint('Notification permission request failed: $error');
    }
  }

  Future<void> reschedule() async {
    if (!_initialized) return;
    final player = ref.read(localPlayerProvider).value;
    if (player == null) return;

    final DateTime? lastGameAt;
    try {
      final lastMatch = await ref
          .read(localMatchRepositoryProvider)
          .watchLastMatch(player.localId)
          .first;
      lastGameAt = lastMatch == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastMatch.playedAt);
    } on Exception catch (error) {
      debugPrint('Could not read the last match: $error');
      return;
    }
    if (!ref.mounted) return;

    final plan = StreakReminderPlanner.plan(
      lastPlayedDate: player.lastPlayedDate,
      lastGameAt: lastGameAt,
      currentStreak: player.currentStreak,
      now: ref.read(reminderClockProvider)(),
    );
    final text = _texts(ref.read(reminderLanguageProvider)());
    try {
      await _notifier.replaceAll([
        for (final reminder in plan)
          ReminderMessage(
            id: reminder.id,
            at: reminder.at,
            title: text(
              _titleKey(reminder.kind),
            ).replaceAll('{n}', '${reminder.streak}'),
            body: text(_bodyKey(reminder.kind)),
            payload: RoutePaths.home,
          ),
      ], channelName: text(AppLocale.reminderChannelName));
    } on Exception catch (error) {
      debugPrint('Could not schedule streak reminders: $error');
    }
  }

  void _onTap(String? route) {
    final pending = ref.read(pendingNotificationRouteProvider.notifier);
    pending.request(route);
    // Before the Home has shown, it will pick the route up itself. After,
    // the stack goes back to a fresh Home, which opens it on top.
    if (pending.homeReady &&
        ref.read(pendingNotificationRouteProvider) != null) {
      appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
        RoutePaths.home,
        (_) => false,
      );
    }
  }

  /// Text without a `BuildContext`: notifications are written outside any
  /// screen.
  static String Function(String key) _texts(String languageCode) {
    final map = languageCode == 'en' ? AppLocale.en : AppLocale.es;
    return (key) => map[key] as String? ?? key;
  }

  static String _titleKey(ReminderKind kind) => switch (kind) {
    ReminderKind.streakAtRisk => AppLocale.reminderStreakTitle,
    ReminderKind.dailyInvite => AppLocale.reminderInviteTitle,
    ReminderKind.comeBack => AppLocale.reminderComeBackTitle,
  };

  static String _bodyKey(ReminderKind kind) => switch (kind) {
    ReminderKind.streakAtRisk => AppLocale.reminderStreakBody,
    ReminderKind.dailyInvite => AppLocale.reminderInviteBody,
    ReminderKind.comeBack => AppLocale.reminderComeBackBody,
  };
}

final streakReminderControllerProvider =
    NotifierProvider<StreakReminderController, void>(
      StreakReminderController.new,
    );
