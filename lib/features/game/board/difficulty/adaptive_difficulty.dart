import 'dart:math';

import 'package:memory_companion/features/game/board/category/game_category.dart';
import 'package:memory_companion/features/game/board/difficulty/difficulty_settings.dart';

/// How a finished round went, as far as difficulty is concerned.
class RoundPerformance {
  const RoundPerformance({
    required this.pairCount,
    required this.matchedPairs,
    required this.memoryErrors,
    required this.hintsUsed,
    required this.secondsRemaining,
    required this.timeLimitSeconds,
    required this.won,
  });

  final int pairCount;
  final int matchedPairs;

  /// Only mistakes on cards already seen. See `RoundTracker`.
  final int memoryErrors;

  final int hintsUsed;
  final int secondsRemaining;
  final int timeLimitSeconds;
  final bool won;
}

/// The player's standing in one category, carried from round to round.
class SkillState {
  const SkillState({
    required this.skill,
    required this.pairCount,
    this.consecutiveLosses = 0,
    this.roundsPlayed = 0,
    this.level = 1,
  });

  /// 0 = needs the gentlest board, 1 = ready for the hardest one.
  final double skill;

  /// Current board size. Kept here rather than derived from [skill] so it
  /// can change by at most one pair per round (see [AdaptiveDifficulty]).
  final int pairCount;

  final int consecutiveLosses;
  final int roundsPlayed;

  /// The explicit level the player sees: 1 plus every board won.
  ///
  /// A progress counter, not a difficulty input. It never goes down — a
  /// lost board is replayed at the same level — while the board itself
  /// keeps following [skill] and [pairCount]. That way the number always
  /// rewards the player, and the relief rules above still apply to a
  /// struggling one.
  final int level;
}

/// Turns round results into the next board's settings.
///
/// Built around players over 60, who leave a game that feels like it is
/// testing them, and children, who leave one that is too easy:
///
///  * **One continuous skill value.** Preview time, time limit and reveal
///    time are derived from it by interpolation, so they drift a little each
///    round instead of jumping between discrete "levels".
///  * **Easier comes faster than harder.** A bad round lowers skill at more
///    than twice the rate a good round raises it, and a single round can
///    only raise it a little. Nobody gets a sudden hard board after one
///    lucky game.
///  * **The board only grows or shrinks by one pair at a time,** with a
///    dead band so it does not flip back and forth between two sizes.
///  * **Two losses in a row always shrink the board,** whatever the skill
///    value says. Being stuck is the moment people give up.
///  * **Only memory errors count.** Missing a card nobody had seen yet is
///    exploring, not failing.
class AdaptiveDifficulty {
  const AdaptiveDifficulty();

  /// Where a new player starts: below the middle, so the first boards are
  /// small and the preview is long.
  static const initialSkill = 0.25;

  /// Performance that keeps skill where it is. Slightly above half, so a
  /// round with a few mistakes and a comfortable finish holds steady.
  static const _flowTarget = 0.6;

  static const _riseRate = 0.12;
  static const _fallRate = 0.3;
  static const _maxRise = 0.06;
  static const _maxFall = 0.15;

  /// How far the ideal board size must be from the current one before it
  /// changes. Smaller when shrinking: relief should come sooner.
  static const _growBand = 0.6;
  static const _shrinkBand = 0.4;

  SkillState initialState(GameCategory category) => SkillState(
    skill: initialSkill,
    pairCount: _idealPairs(category, initialSkill).round(),
  );

  /// Scores a round from 0 (overwhelmed) to 1 (effortless).
  double performanceScore(RoundPerformance round) {
    if (round.pairCount == 0) return _flowTarget;

    if (!round.won) {
      // Losing always lands below the flow target, but getting most of the
      // way there softens the drop.
      return 0.3 * round.matchedPairs / round.pairCount;
    }

    // 1.5 memory errors per pair or more is as bad as accuracy gets.
    final errorRate = round.memoryErrors / round.pairCount;
    final accuracy = (1 - errorRate / 1.5).clamp(0.0, 1.0);

    // Finishing with half the time left already counts as fully fluent;
    // speed matters less than memory for this audience.
    final timeLeft = round.timeLimitSeconds == 0
        ? 0.0
        : round.secondsRemaining / round.timeLimitSeconds;
    final pace = (timeLeft / 0.5).clamp(0.0, 1.0);

    final hintPenalty = 0.1 * round.hintsUsed;

    return (0.75 * accuracy + 0.25 * pace - hintPenalty).clamp(0.0, 1.0);
  }

  SkillState update(
    GameCategory category,
    SkillState state,
    RoundPerformance round,
  ) {
    final delta = performanceScore(round) - _flowTarget;
    final change = delta >= 0
        ? min(delta * _riseRate, _maxRise)
        : max(delta * _fallRate, -_maxFall);
    final skill = (state.skill + change).clamp(0.0, 1.0);

    final losses = round.won ? 0 : state.consecutiveLosses + 1;

    var pairs = state.pairCount;
    final ideal = _idealPairs(category, skill);
    if (losses >= 2) {
      pairs--;
    } else if (ideal >= pairs + _growBand) {
      pairs++;
    } else if (ideal <= pairs - _shrinkBand) {
      pairs--;
    }

    return SkillState(
      skill: skill,
      pairCount: pairs.clamp(category.minPairs, category.maxPairs),
      // A forced shrink counts as the relief: the next loss starts afresh.
      consecutiveLosses: losses >= 2 ? 0 : losses,
      roundsPlayed: state.roundsPlayed + 1,
      level: round.won ? state.level + 1 : state.level,
    );
  }

  DifficultySettings settingsFor(GameCategory category, SkillState state) {
    final s = state.skill;
    final load = category.readingLoad;
    final pairs = state.pairCount.clamp(category.minPairs, category.maxPairs);

    // Per-card time: generous at low skill, never rushed at high skill.
    final preview = (pairs * _lerp(0.9, 0.35, s) * load).round().clamp(2, 12);
    final rawLimit = pairs * _lerp(16, 9, s) * load;
    final timeLimit = max(45, (rawLimit / 5).round() * 5);
    final reveal = (_lerp(1100, 650, s) * load).round().clamp(600, 1800);

    return DifficultySettings(
      pairCount: pairs,
      previewSeconds: preview,
      timeLimitSeconds: timeLimit,
      mismatchRevealMs: reveal,
      tier: _tierFor(s),
    );
  }

  static double _idealPairs(GameCategory category, double skill) =>
      _lerp(category.minPairs.toDouble(), category.maxPairs.toDouble(), skill);

  /// Content gets harder after board size has had a chance to: a player
  /// has to be comfortable with bigger boards before the cards themselves
  /// become more demanding.
  static ContentTier _tierFor(double skill) {
    if (skill < 0.4) return ContentTier.gentle;
    if (skill < 0.75) return ContentTier.standard;
    return ContentTier.challenging;
  }

  static double _lerp(double from, double to, double t) =>
      from + (to - from) * t;
}
