/// The two visual profiles the whole UI can switch between.
///
/// Lives in `core/theme` — not in the settings feature — because the theme,
/// the database and every adaptive widget need to name it, and `core` must
/// never import from `features`.
///
/// Stored as text (`textEnum`), like every other enum in the local database:
/// reordering or inserting a value must not reinterpret rows already written
/// on a player's device.
enum VisualProfile {
  /// Fluid motion, confetti, the full "Vibrant Kinetic" palette and the
  /// countdown timer. The default for new installs.
  vibrant,

  /// Larger type, stronger contrast, bigger and calmer controls, no
  /// decorative motion and — by default — no countdown timer.
  accessible;

  bool get isAccessible => this == VisualProfile.accessible;

  /// Whether a match runs against the clock when the player picks this
  /// profile. The player can still override it afterwards; this is only the
  /// value applied at the moment the profile is chosen.
  bool get timedMatchesByDefault => this == VisualProfile.vibrant;
}
