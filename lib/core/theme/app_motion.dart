import 'package:flutter/animation.dart';

/// Motion tokens.
///
/// The rule for this app: feedback must land inside 200ms so the interface
/// never feels slower than the player, and celebrations are the only thing
/// allowed to run long. Everything animates position, scale or opacity —
/// never layout — so nothing costs a reflow.
abstract final class AppMotion {
  /// Finger-down acknowledgement. Must be imperceptibly fast.
  static const Duration instant = Duration(milliseconds: 90);

  /// Hover/press release, chip toggles, small state swaps.
  static const Duration fast = Duration(milliseconds: 160);

  /// The default for anything that moves or fades on screen.
  static const Duration normal = Duration(milliseconds: 220);

  /// Progress bars filling, counters counting up.
  static const Duration slow = Duration(milliseconds: 420);

  /// Reward reveals and level-up celebrations.
  static const Duration celebrate = Duration(milliseconds: 700);

  /// Screen-to-screen transitions.
  static const Duration page = Duration(milliseconds: 280);

  /// Press down: decelerating, so the surface "catches" under the finger.
  static const Curve press = Curves.easeOutCubic;

  /// Standard entry for content appearing on screen.
  static const Curve enter = Curves.easeOutCubic;

  /// Standard exit.
  static const Curve exit = Curves.easeInCubic;

  /// Material 3 emphasized easing — used for anything travelling a distance.
  static const Curve emphasized = Cubic(0.2, 0, 0, 1);

  /// Overshoot for rewards and success states. Use sparingly; it is loud.
  static const Curve bounce = Curves.elasticOut;

  /// Gentle overshoot — a card settling after release.
  static const Curve settle = Curves.easeOutBack;

  /// Scale applied to a card while it is held down.
  static const double pressScale = 0.965;

  /// Scale applied to a small control (chip, nav item) while held down.
  static const double pressScaleSmall = 0.92;

  /// Downward travel of a raised surface while held down, in logical px.
  static const double pressDepth = 3;
}
