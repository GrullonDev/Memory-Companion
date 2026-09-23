import 'package:flutter/widgets.dart';

import 'package:memory_companion/core/theme/app_colors.dart';

/// Tile colours for a mini-game, always one whole brand ramp from
/// [AppColors] so the fill/foreground pair keeps its checked contrast.
class MinigamePalette {
  const MinigamePalette({
    required this.background,
    required this.foreground,
    required this.shadow,
  });

  final Color background;

  /// Text and icon colour on [background] (>= 4.5:1).
  final Color foreground;

  /// Hue of the tinted drop shadow.
  final Color shadow;

  static const sun = MinigamePalette(
    background: AppColors.sun,
    foreground: AppColors.onSun,
    shadow: AppColors.sunDeep,
  );
  static const sky = MinigamePalette(
    background: AppColors.sky,
    foreground: AppColors.onSky,
    shadow: AppColors.skyDeep,
  );
  static const mint = MinigamePalette(
    background: AppColors.mint,
    foreground: AppColors.onMint,
    shadow: AppColors.mintDeep,
  );
  static const violet = MinigamePalette(
    background: AppColors.violet,
    foreground: AppColors.onViolet,
    shadow: AppColors.violetDeep,
  );
  static const streak = MinigamePalette(
    background: AppColors.streak,
    foreground: AppColors.onStreak,
    shadow: AppColors.streakDeep,
  );
}

/// The contract every mini-game of the platform fulfils.
///
/// A mini-game is a self-contained module: the hub only knows what is
/// declared here (how to show the tile, where to navigate) and the
/// statistics only know what it reports through `MinigameResultReporter`.
/// Nothing outside the module depends on its internals, so adding one never
/// touches the hub, the router, the `game_stats` table or the daily
/// challenge.
///
/// Implementations are `const` and stateless: game state lives in the
/// module's own controllers, not here.
abstract class BaseMinigame {
  const BaseMinigame();

  /// Stable identifier. Keys the route and the player's statistics, so
  /// never rename it once shipped.
  String get id;

  /// `AppLocale` keys for the tile's name and one-line description.
  String get titleKey;
  String get descriptionKey;

  /// Glyph for the tile. Always required: it is the fallback when
  /// [iconAsset] is absent and what players who cannot read yet aim at.
  IconData get icon;

  /// Optional illustration shown instead of [icon]. Must be declared under
  /// `flutter.assets` in `pubspec.yaml`.
  String? get iconAsset => null;

  MinigamePalette get palette;

  /// Named route the module is served on. `RouteSwitch` resolves it through
  /// the registry, so no route table needs a new `case`.
  String get routeName => '/games/$id';

  /// The module's entry screen. The route's `RouteSettings` are preserved,
  /// so the screen can still read `ModalRoute.of(context)!.settings.arguments`.
  Widget buildGameScreen();

  /// Opens the game. Override to gate entry (a tutorial, a paywall);
  /// [arguments] reach the screen through the route.
  Future<void> start(BuildContext context, {Object? arguments}) {
    return Navigator.of(context).pushNamed(routeName, arguments: arguments);
  }

  /// Value written to `game_stats.category_id` for a result of this game.
  ///
  /// Namespaced by default (`'sequence'`, `'sequence:reverse'`) so two games
  /// can never mix their rows.
  String statsKeyFor(String? variantId) =>
      variantId == null ? id : '$id:$variantId';

  /// Whether a stored `category_id` belongs to this game. Must agree with
  /// [statsKeyFor].
  bool ownsStatsKey(String key) => key == id || key.startsWith('$id:');
}
