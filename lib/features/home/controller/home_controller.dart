import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/features/home/model/recent_match.dart';

/// Loads the data the home screen shows beyond the static mode grid: the
/// player's most recent match.
class HomeController extends AsyncNotifier<RecentMatch> {
  @override
  Future<RecentMatch> build() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return const RecentMatch(
      titleKey: AppLocale.sampleMatchTitle,
      score: '14,200',
      timeAgoKey: AppLocale.sampleMatchTimeAgo,
    );
  }
}

final homeControllerProvider =
    AsyncNotifierProvider<HomeController, RecentMatch>(HomeController.new);
