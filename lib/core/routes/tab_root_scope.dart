import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/routes/route_paths.dart';

/// Handles the system back button on a bottom-nav tab (Home, Versus,
/// Friends, Shop).
///
/// Tabs replace each other instead of stacking (see
/// [RoutePaths.navigateToTab]), so a tab is usually the only route left.
/// Popping it would leave the navigator empty, so back is taken over:
///  * on any tab but Home, it goes to Home — the one way out of the app;
///  * on Home, the first press asks for a second one, and a second press
///    within [exitWindow] closes the app.
///
/// When the tab was pushed over another screen (Home's shortcuts push
/// Versus and Friends), back simply pops back to it, as usual.
class TabRootScope extends StatefulWidget {
  const TabRootScope({super.key, required this.isHome, required this.child});

  final bool isHome;
  final Widget child;

  /// How long the "press back again to exit" offer lasts.
  static const exitWindow = Duration(seconds: 2);

  @override
  State<TabRootScope> createState() => _TabRootScopeState();
}

class _TabRootScopeState extends State<TabRootScope> {
  /// Running while a second back press would close the app.
  Timer? _exitOffer;

  @override
  void dispose() {
    _exitOffer?.cancel();
    super.dispose();
  }

  void _onBack() {
    if (!widget.isHome) {
      RoutePaths.navigateToTab(context, 0);
      return;
    }
    if (_exitOffer?.isActive ?? false) {
      _exitOffer?.cancel();
      SystemNavigator.pop();
      return;
    }
    _exitOffer = Timer(TabRootScope.exitWindow, () {});
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(AppLocale.pressBackAgainToExit.getString(context)),
          duration: TabRootScope.exitWindow,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    // Pushed over another screen, back returns to it. `canPopOf` rebuilds
    // this when the routes below change, unlike reading `isFirst`.
    final hasRouteBelow = ModalRoute.canPopOf(context) ?? false;
    return PopScope(
      canPop: hasRouteBelow,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: widget.child,
    );
  }
}
