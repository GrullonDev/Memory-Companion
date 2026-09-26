/// Layout tokens: spacing, radii, sizes and breakpoints.
///
/// Nothing in the UI should hard-code a number that belongs here. If a value
/// is missing, add it here rather than inlining a literal in a widget.
library;

/// 4px baseline rhythm. Vertical and horizontal gaps both come from here.
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;

  /// Horizontal page margin. Screens breathe at 20 on phones.
  static const double screenMargin = 20;

  /// Gap between sibling cards in a grid or row.
  static const double gutter = 14;

  /// Gap between a section header and its content.
  static const double sectionGap = 28;
}

/// Corner radii. Bigger containers get bigger radii so the visual "softness"
/// stays constant regardless of the element's size.
abstract final class AppRadius {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 28;
  static const double hero = 32;
  static const double pill = 999;
}

/// Sizes for icons and touch targets.
abstract final class AppSize {
  /// Absolute minimum tappable square (WCAG 2.5.5 / Material).
  static const double touchMin = 48;

  /// What we actually aim for on primary controls — comfortable for a
  /// 4-year-old's aim and for an adult with reduced dexterity alike.
  static const double touchComfortable = 56;

  static const double iconXs = 16;
  static const double iconSm = 20;
  static const double iconMd = 24;
  static const double iconLg = 30;
  static const double iconXl = 38;

  /// Icon "well" — the rounded square an icon sits inside on a card.
  static const double wellSm = 40;
  static const double wellMd = 52;
  static const double wellLg = 64;

  /// Height of the primary action card, before text scaling.
  static const double primaryCardMinHeight = 148;

  /// Height of a secondary mode card, before text scaling.
  static const double secondaryCardMinHeight = 132;

  static const double progressBarHeight = 14;
  static const double avatarSm = 40;
  static const double avatarMd = 52;
}

/// Width thresholds used to adapt layout. Measured in logical pixels against
/// the *available* width, never against the raw screen size.
abstract final class AppBreakpoints {
  /// Small phones (iPhone SE, 5" Androids). Below this, drop to one column
  /// and trim optional decoration.
  static const double compact = 360;

  /// Comfortable phone width.
  static const double medium = 400;

  /// Tablets and foldables — grids may gain a column.
  static const double expanded = 600;
}
