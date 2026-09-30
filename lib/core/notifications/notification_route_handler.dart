import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/notifications/streak_reminder_controller.dart';
import 'package:memory_companion/core/routes/route_paths.dart';

/// Sits in the Home and does two things the first time it shows:
///
///  * takes the route a tapped reminder asked for; reminders only ever ask
///    for the Home, so today the Home simply stays on screen;
///  * asks for notification permission, once the player has seen the app
///    rather than on a bare splash.
class NotificationRouteHandler extends ConsumerStatefulWidget {
  const NotificationRouteHandler({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<NotificationRouteHandler> createState() =>
      _NotificationRouteHandlerState();
}

class _NotificationRouteHandlerState
    extends ConsumerState<NotificationRouteHandler> {
  @override
  void initState() {
    super.initState();
    ref.read(pendingNotificationRouteProvider.notifier).homeReady = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final route = ref.read(pendingNotificationRouteProvider.notifier).take();
      if (route != null && route != RoutePaths.home) {
        Navigator.of(context).pushNamed(route);
      }
      ref
          .read(streakReminderControllerProvider.notifier)
          .requestPermissionOnce();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
