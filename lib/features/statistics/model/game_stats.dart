import 'package:drift/drift.dart' show Value;

import 'package:memory_companion/core/database/app_database.dart';

/// Metrics of one finished game, as the statistics panel sees it.
///
/// Built by the board when a round ends (won, or lost to the clock) and
/// stored only on this device. Abandoned rounds are never recorded: leaving
/// a board half-played says nothing reliable about memory.
class GameStats {
  const GameStats({
    required this.date,
    required this.categoryId,
    required this.pairCount,
    required this.matchedPairs,
    required this.moves,
    required this.memoryErrors,
    required this.hintsUsed,
    required this.timeSeconds,
    required this.timeLimitSeconds,
    required this.timed,
    required this.won,
    required this.score,
    this.id,
  });

  /// Null until the row is stored.
  final int? id;
  final DateTime date;
  final String categoryId;
  final int pairCount;
  final int matchedPairs;
  final int moves;
  final int memoryErrors;
  final int hintsUsed;
  final int timeSeconds;
  final int timeLimitSeconds;
  final bool timed;
  final bool won;
  final int score;

  /// Share of turns that found a pair: 1.0 is a perfect game, one turn per
  /// pair. A game with no turns (lost before the first flip) scores 0.
  double get accuracy => moves == 0 ? 0 : matchedPairs / moves;

  /// Seconds per pair on the board. Board size grows as the player improves,
  /// so raw time alone would read progress as getting slower.
  double get secondsPerPair => pairCount == 0 ? 0 : timeSeconds / pairCount;

  factory GameStats.fromRow(GameStatsRow row) {
    return GameStats(
      id: row.id,
      date: DateTime.fromMillisecondsSinceEpoch(row.playedAt),
      categoryId: row.categoryId,
      pairCount: row.pairCount,
      matchedPairs: row.matchedPairs,
      moves: row.moves,
      memoryErrors: row.memoryErrors,
      hintsUsed: row.hintsUsed,
      timeSeconds: row.secondsElapsed,
      timeLimitSeconds: row.timeLimitSeconds,
      timed: row.timed,
      won: row.won,
      score: row.score,
    );
  }

  GameStatsCompanion toCompanion() {
    return GameStatsCompanion.insert(
      playedAt: date.millisecondsSinceEpoch,
      playedDay: dayKey(date),
      categoryId: categoryId,
      pairCount: pairCount,
      matchedPairs: matchedPairs,
      moves: moves,
      memoryErrors: memoryErrors,
      hintsUsed: hintsUsed,
      secondsElapsed: timeSeconds,
      timeLimitSeconds: timeLimitSeconds,
      timed: timed,
      won: won,
      score: score,
    ).copyWith(id: id == null ? const Value.absent() : Value(id!));
  }

  /// Plain-map form, for a local export or a debug dump. Never sent anywhere.
  Map<String, Object?> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'categoryId': categoryId,
      'pairCount': pairCount,
      'matchedPairs': matchedPairs,
      'moves': moves,
      'memoryErrors': memoryErrors,
      'hintsUsed': hintsUsed,
      'timeSeconds': timeSeconds,
      'timeLimitSeconds': timeLimitSeconds,
      'timed': timed,
      'won': won,
      'score': score,
      'accuracy': accuracy,
    };
  }

  factory GameStats.fromJson(Map<String, Object?> json) {
    return GameStats(
      id: json['id'] as int?,
      date: DateTime.parse(json['date']! as String),
      categoryId: json['categoryId']! as String,
      pairCount: json['pairCount']! as int,
      matchedPairs: json['matchedPairs']! as int,
      moves: json['moves']! as int,
      memoryErrors: json['memoryErrors']! as int,
      hintsUsed: json['hintsUsed']! as int,
      timeSeconds: json['timeSeconds']! as int,
      timeLimitSeconds: json['timeLimitSeconds']! as int,
      timed: json['timed']! as bool,
      won: json['won']! as bool,
      score: json['score']! as int,
    );
  }
}

/// `'YYYY-MM-DD'` in local time: the key games are grouped and streaks
/// counted by.
String dayKey(DateTime date) {
  final local = date.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

/// Inverse of [dayKey], at local midnight.
DateTime parseDayKey(String key) {
  final [year, month, day] = key.split('-').map(int.parse).toList();
  return DateTime(year, month, day);
}
