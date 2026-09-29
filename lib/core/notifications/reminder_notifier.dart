import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// A reminder ready for the system: text resolved, time fixed.
class ReminderMessage {
  const ReminderMessage({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;
  final DateTime at;
  final String title;
  final String body;

  /// The route a tap opens.
  final String payload;
}

/// The device's local notifications, as far as the app needs them.
///
/// An interface so the scheduling logic can be tested with a fake, and so
/// platforms without scheduled notifications get [NoopReminderNotifier]
/// instead of a plugin exception.
abstract interface class ReminderNotifier {
  /// Sets up the plugin. Returns the payload of the notification that
  /// launched the app, if one did. [onTap] receives taps from then on.
  Future<String?> initialize({required ValueChanged<String?> onTap});

  /// Asks the system for permission to show notifications. Returns whether
  /// they are allowed.
  Future<bool> requestPermission();

  /// Replaces every scheduled reminder with [reminders].
  Future<void> replaceAll(
    List<ReminderMessage> reminders, {
    required String channelName,
  });
}

/// Web and desktop: scheduled notifications are not offered there.
class NoopReminderNotifier implements ReminderNotifier {
  const NoopReminderNotifier();

  @override
  Future<String?> initialize({required ValueChanged<String?> onTap}) async =>
      null;

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> replaceAll(
    List<ReminderMessage> reminders, {
    required String channelName,
  }) async {}
}

/// Android and iOS, through `flutter_local_notifications`.
class LocalReminderNotifier implements ReminderNotifier {
  LocalReminderNotifier([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const _channelId = 'streak_reminders';

  @override
  Future<String?> initialize({required ValueChanged<String?> onTap}) async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Permission is asked for explicitly, once the Home is on screen,
        // rather than by the plugin in the middle of the splash.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) => onTap(response.payload),
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    return launch?.didNotificationLaunchApp ?? false
        ? launch!.notificationResponse?.payload
        : null;
  }

  @override
  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        false;
  }

  @override
  Future<void> replaceAll(
    List<ReminderMessage> reminders, {
    required String channelName,
  }) async {
    await _plugin.cancelAll();
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        channelName,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: const DarwinNotificationDetails(),
    );
    for (final reminder in reminders) {
      await _plugin.zonedSchedule(
        id: reminder.id,
        // An absolute instant: [ReminderMessage.at] is already the local
        // wall-clock time, so UTC avoids needing the device's zone name.
        scheduledDate: tz.TZDateTime.from(reminder.at, tz.UTC),
        notificationDetails: details,
        // A reminder minutes late is fine; exact alarms need a permission
        // the store audits.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: reminder.title,
        body: reminder.body,
        payload: reminder.payload,
      );
    }
  }
}
