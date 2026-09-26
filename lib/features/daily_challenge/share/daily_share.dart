import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

import 'package:memory_companion/features/daily_challenge/model/daily_result.dart';

/// The words in the share text, already in the player's language.
///
/// Passed in rather than looked up here so [DailyShareText.build] stays a
/// pure function that tests can pin down character by character.
class DailyShareStrings {
  const DailyShareStrings({
    required this.challenge,
    required this.moves,
    required this.streakDays,
    required this.callToAction,
  });

  /// e.g. `'Challenge'` → "Challenge #266".
  final String challenge;

  /// e.g. `'moves'` → "14 moves".
  final String moves;

  /// e.g. `'day streak'` → "🔥 5 day streak".
  final String streakDays;

  /// e.g. `'Try it today!'`.
  final String callToAction;
}

/// Builds the Wordle-style text a player pastes into WhatsApp.
abstract final class DailyShareText {
  static const appName = 'Memory Companion';

  /// Where the share text sends people. Replace with a smart link (one URL
  /// that routes to the right store) once one exists.
  static const downloadUrl =
      'https://play.google.com/store/apps/details?id=com.grullondev.memory_arcade';

  /// ```
  /// 🧠 Memory Companion - Challenge #266
  /// ⏱️ 42s | 🔄 14 moves
  /// 🟩🟩🟨🟩
  /// 🟩🟩🟩🟥
  /// 🔥 5 day streak
  /// Try it today! https://…
  /// ```
  ///
  /// Hints and the streak only appear when there is something to say:
  /// "💡 0" is noise, and a one-day streak is not worth bragging about.
  static String build({
    required DailyResult result,
    required int streak,
    required DailyShareStrings strings,
  }) {
    final stats = [
      '⏱️ ${formatDuration(result.elapsedSeconds)}',
      '🔄 ${result.moves} ${strings.moves}',
      if (result.hintsUsed > 0) '💡 ${result.hintsUsed}',
    ].join(' | ');

    return [
      '🧠 $appName - ${strings.challenge} #${result.number}',
      stats,
      ...result.emojiRows,
      if (streak >= 2) '🔥 $streak ${strings.streakDays}',
      '${strings.callToAction} $downloadUrl',
    ].join('\n');
  }

  /// `42s` under a minute, `1m 05s` after: short enough for a chat line.
  static String formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '${seconds ~/ 60}m ${s}s';
  }
}

/// Opens the platform share sheet with [text].
///
/// [origin] anchors the popover on iPad, where the sheet is not full-screen
/// and throws without a position; pass the share button's context.
Future<void> shareDailyResult(String text, {BuildContext? origin}) async {
  final box = origin?.findRenderObject() as RenderBox?;
  await SharePlus.instance.share(
    ShareParams(
      text: text,
      sharePositionOrigin: box == null || !box.hasSize
          ? null
          : box.localToGlobal(Offset.zero) & box.size,
    ),
  );
}
