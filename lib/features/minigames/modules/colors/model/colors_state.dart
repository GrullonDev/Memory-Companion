import 'dart:math';

import 'package:flutter/painting.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/features/minigames/core/minigame_level.dart';

enum ColorsPhase { intro, playing, feedback, finished }

/// The colours the game names and paints with. Chosen so that every pair
/// is easy to tell apart and each has a one-word name in both languages.
enum InkColor {
  red(Color(0xFFE53935), AppLocale.colorRed),
  blue(Color(0xFF1E88E5), AppLocale.colorBlue),
  green(Color(0xFF43A047), AppLocale.colorGreen),
  yellow(Color(0xFFFDD835), AppLocale.colorYellow),
  purple(Color(0xFF8E24AA), AppLocale.colorPurple),
  orange(Color(0xFFFB8C00), AppLocale.colorOrange);

  const InkColor(this.color, this.nameKey);

  final Color color;
  final String nameKey;
}

/// Items per round.
const colorsItemsPerRound = 12;

/// Right answers that pass a round.
const colorsPassCount = 10;

const colorsFeedbackDuration = Duration(milliseconds: 500);

/// How hard the colour game is at a level: more colours, more items whose
/// word and ink disagree, and less time per item, with no top.
class ColorsDifficulty {
  const ColorsDifficulty({
    required this.level,
    required this.colorCount,
    required this.mismatchPercent,
    required this.timeLimitMs,
  });

  factory ColorsDifficulty.forLevel(int level) {
    final l = level < 1 ? 1 : level;
    return ColorsDifficulty(
      level: l,
      colorCount: levelRamp(l, start: 4, every: 5, max: InkColor.values.length),
      mismatchPercent: levelRamp(l, start: 50, step: 3, max: 90),
      timeLimitMs: levelRamp(l, start: 5000, step: -150, max: 1500),
    );
  }

  final int level;
  final int colorCount;

  /// Share of items (in percent) whose word names another colour than its
  /// ink — the ones that make you stop and think.
  final int mismatchPercent;
  final int timeLimitMs;

  List<InkColor> get colors => InkColor.values.take(colorCount).toList();
  Duration get timeLimit => Duration(milliseconds: timeLimitMs);
}

/// A colour word painted in some ink. The answer is always the ink.
class ColorsItem {
  const ColorsItem(this.word, this.ink);

  factory ColorsItem.deal(ColorsDifficulty difficulty, Random random) {
    final colors = difficulty.colors;
    final ink = colors[random.nextInt(colors.length)];
    if (random.nextInt(100) >= difficulty.mismatchPercent) {
      return ColorsItem(ink, ink);
    }
    final others = colors.where((c) => c != ink).toList();
    return ColorsItem(others[random.nextInt(others.length)], ink);
  }

  final InkColor word;
  final InkColor ink;
}

class ColorsState {
  const ColorsState({
    required this.phase,
    required this.difficulty,
    this.items = const [],
    this.index = 0,
    this.correct = 0,
    this.lastCorrect = false,
  });

  ColorsState.intro({int level = 1})
    : this(
        phase: ColorsPhase.intro,
        difficulty: ColorsDifficulty.forLevel(level),
      );

  final ColorsPhase phase;
  final ColorsDifficulty difficulty;
  final List<ColorsItem> items;
  final int index;
  final int correct;
  final bool lastCorrect;

  int get level => difficulty.level;
  ColorsItem? get current => index < items.length ? items[index] : null;
  bool get won => correct >= colorsPassCount;
  int get score => correct * 10 + (won ? difficulty.level * 5 : 0);

  ColorsState copyWith({
    ColorsPhase? phase,
    int? index,
    int? correct,
    bool? lastCorrect,
  }) {
    return ColorsState(
      phase: phase ?? this.phase,
      difficulty: difficulty,
      items: items,
      index: index ?? this.index,
      correct: correct ?? this.correct,
      lastCorrect: lastCorrect ?? this.lastCorrect,
    );
  }
}
