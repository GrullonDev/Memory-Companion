import 'package:memory_companion/core/theme/visual_profile.dart';

/// The player's presentation choices on this device.
///
/// Holds only *what was chosen*. How each profile looks lives in
/// `ProfileTokens`; how it plays lives in the getters below, so the game
/// controller can read gameplay tuning without a `BuildContext`.
class DisplayPreferences {
  const DisplayPreferences({
    this.visualProfile = VisualProfile.vibrant,
    this.timedMatches = true,
  });

  /// What a fresh install — and the first frame before the database
  /// answers — uses.
  static const DisplayPreferences defaults = DisplayPreferences();

  final VisualProfile visualProfile;

  /// Whether a match runs against a countdown. When false the clock still
  /// counts up (for the result screen), but running out of time never ends
  /// the match.
  final bool timedMatches;

  bool get isAccessible => visualProfile.isAccessible;

  /// The shortest time a wrong pair may stay face up before flipping back.
  ///
  /// A floor, not a value: the adaptive difficulty still decides the reveal
  /// and may give *more* time, never less than this. The accessible profile
  /// guarantees 1.2s — the point of the game is to remember the cards, and
  /// many players need longer than a fast round allows just to read them.
  Duration get mismatchRevealFloor =>
      isAccessible ? const Duration(milliseconds: 1200) : Duration.zero;

  DisplayPreferences copyWith({
    VisualProfile? visualProfile,
    bool? timedMatches,
  }) {
    return DisplayPreferences(
      visualProfile: visualProfile ?? this.visualProfile,
      timedMatches: timedMatches ?? this.timedMatches,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DisplayPreferences &&
        other.visualProfile == visualProfile &&
        other.timedMatches == timedMatches;
  }

  @override
  int get hashCode => Object.hash(visualProfile, timedMatches);
}
