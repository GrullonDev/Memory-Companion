import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:memory_companion/features/daily_challenge/model/daily_seed.dart';
import 'package:memory_companion/features/game/board/category/game_categories.dart';
import 'package:memory_companion/features/game/board/category/game_category.dart';
import 'package:memory_companion/features/game/board/difficulty/adaptive_difficulty.dart';
import 'package:memory_companion/features/game/board/difficulty/difficulty_settings.dart';
import 'package:memory_companion/features/game/board/model/shared_board.dart';
import 'package:memory_companion/features/versus/model/duel_game.dart';

/// [open] is a room nobody has joined yet: the host can already play it,
/// and whoever enters its code becomes the opponent.
enum DuelStatus { open, pending, completed, declined }

enum DuelOutcome { won, lost, draw }

/// One side's result in a duel round.
class DuelScore {
  const DuelScore({
    required this.score,
    required this.seconds,
    required this.moves,
  });

  factory DuelScore.fromMap(Map<String, dynamic> data) => DuelScore(
    score: (data['score'] as num?)?.toInt() ?? 0,
    seconds: (data['seconds'] as num?)?.toInt() ?? 0,
    moves: (data['moves'] as num?)?.toInt() ?? 0,
  );

  final int score;
  final int seconds;
  final int moves;

  Map<String, Object> toMap() => {
    'score': score,
    'seconds': seconds,
    'moves': moves,
  };

  /// Higher score wins; on equal scores, the faster player; then the one
  /// with fewer moves.
  int compareTo(DuelScore other) {
    if (score != other.score) return score.compareTo(other.score);
    if (seconds != other.seconds) return other.seconds.compareTo(seconds);
    return other.moves.compareTo(moves);
  }
}

/// The last thing a player did in a round, as the rival sees it.
enum DuelEvent {
  none,

  /// A pair matched, or an answer right.
  hit,

  /// A pair that did not match, or an answer wrong.
  miss;

  static DuelEvent byName(Object? name) =>
      values.where((event) => event.name == name).firstOrNull ?? none;
}

/// Where a player stands in a duel right now, written while they play so
/// the rival can follow along. Decoration only: results are what count.
///
/// Boards are dealt identically on both sides, so card positions ([cards],
/// [matched]) mean the same card on the rival's thumbnail.
class DuelProgress {
  const DuelProgress({
    required this.round,
    required this.score,
    this.solved = 0,
    this.total = 0,
    this.event = DuelEvent.none,
    this.seq = 0,
    this.cards = const [],
    this.matched = const [],
    this.at,
  });

  factory DuelProgress.fromMap(Map<String, dynamic> data) {
    final at = data['at'];
    List<int> ints(Object? value) => [
      if (value is List)
        for (final item in value)
          if (item is num) item.toInt(),
    ];
    return DuelProgress(
      round: (data['round'] as num?)?.toInt() ?? 0,
      score: (data['score'] as num?)?.toInt() ?? 0,
      solved: (data['solved'] as num?)?.toInt() ?? 0,
      total: (data['total'] as num?)?.toInt() ?? 0,
      event: DuelEvent.byName(data['event']),
      seq: (data['seq'] as num?)?.toInt() ?? 0,
      cards: ints(data['cards']),
      matched: ints(data['matched']),
      at: at is Timestamp ? at.toDate() : null,
    );
  }

  /// Zero-based round being played.
  final int round;
  final int score;

  /// Pairs found, answers right or words found, out of [total].
  final int solved;
  final int total;

  /// What happened with report [seq]. Each report with an event gets a new
  /// [seq], so the rival animates it once even if it repeats.
  final DuelEvent event;
  final int seq;

  /// Board positions of the pair behind [event].
  final List<int> cards;

  /// Board positions already matched.
  final List<int> matched;
  final DateTime? at;

  /// How long a report still means "playing right now".
  static const liveWindow = Duration(seconds: 45);

  bool isLive(DateTime now) {
    final at = this.at;
    return at != null && now.difference(at) < liveWindow;
  }

  double get fraction => total <= 0 ? 0 : (solved / total).clamp(0.0, 1.0);

  DuelProgress copyWith({int? round, int? seq}) => DuelProgress(
    round: round ?? this.round,
    score: score,
    solved: solved,
    total: total,
    event: event,
    seq: seq ?? this.seq,
    cards: cards,
    matched: matched,
    at: at,
  );

  /// Written under `progress.<uid>`; the time is the server's.
  Map<String, Object> toMap() => {
    'round': round,
    'score': score,
    'solved': solved,
    'total': total,
    'event': event.name,
    'seq': seq,
    'cards': cards,
    'matched': matched,
  };
}

/// An asynchronous duel: two players play the same game, each when they
/// can, over a series of rounds. Whoever wins more rounds wins the duel.
///
/// Both sides are dealt from [seed] (and the round) with fixed settings, in
/// the challenger's card language, so their rounds are identical. That is
/// what lets a duel work without both players being online at the same
/// moment.
class Duel {
  const Duel({
    required this.id,
    required this.challengerUid,
    required this.opponentUid,
    required this.friendshipId,
    required this.seed,
    required this.categoryId,
    required this.languageCode,
    required this.status,
    this.results = const {},
    this.roundResults = const {},
    this.rounds = 1,
    this.gameId,
    this.progress = const {},
    this.createdAt,
    this.roomCode,
    this.names = const {},
  });

  /// Only a decline is stored as a status. "Completed" is derived from the
  /// results, so each side writes nothing but its own rounds — writes that
  /// Firestore can queue while offline.
  factory Duel.fromFirestore(String id, Map<String, dynamic> data) {
    final created = data['createdAt'];
    final rawResults = data['results'];
    final rawRounds = data['roundResults'];
    final rawProgress = data['progress'];
    final rawNames = data['names'];

    DuelScore? score(Object? value) => value is Map
        ? DuelScore.fromMap(Map<String, dynamic>.from(value))
        : null;

    final duel = Duel(
      id: id,
      challengerUid: data['challengerUid'] as String? ?? '',
      opponentUid: data['opponentUid'] as String? ?? '',
      friendshipId: data['friendshipId'] as String? ?? '',
      seed: (data['seed'] as num?)?.toInt() ?? 0,
      categoryId: data['categoryId'] as String? ?? '',
      languageCode: data['languageCode'] as String? ?? 'es',
      status: switch (data['status']) {
        'declined' => DuelStatus.declined,
        'open' => DuelStatus.open,
        _ => DuelStatus.pending,
      },
      results: {
        if (rawResults is Map)
          for (final entry in rawResults.entries)
            entry.key as String: ?score(entry.value),
      },
      roundResults: {
        if (rawRounds is Map)
          for (final player in rawRounds.entries)
            if (player.value is Map)
              player.key as String: {
                for (final round in (player.value as Map).entries)
                  if ((int.tryParse('${round.key}'), score(round.value)) case (
                    final index?,
                    final value?,
                  ))
                    index: value,
              },
      },
      rounds: (data['rounds'] as num?)?.toInt() ?? 1,
      gameId: data['gameId'] as String?,
      progress: {
        if (rawProgress is Map)
          for (final entry in rawProgress.entries)
            if (entry.value is Map)
              entry.key as String: DuelProgress.fromMap(
                Map<String, dynamic>.from(entry.value as Map),
              ),
      },
      createdAt: created is Timestamp ? created.toDate() : null,
      roomCode: data['roomCode'] as String?,
      names: {
        if (rawNames is Map)
          for (final entry in rawNames.entries)
            if (entry.value is String)
              entry.key as String: entry.value as String,
      },
    );
    return duel.isComplete ? duel.withStatus(DuelStatus.completed) : duel;
  }

  /// Pairs dealt on a duel board. Same as the daily challenge: a short,
  /// fair board that nobody is locked out of.
  static const pairCount = 6;

  /// Rounds in a new duel: best of three.
  static const seriesRounds = 3;

  /// A new seed for a duel, fitting in 32 bits like [DailySeed]'s.
  static int newSeed(Random random) => random.nextInt(1 << 32);

  final String id;
  final String challengerUid;
  final String opponentUid;
  final String friendshipId;
  final int seed;
  final String categoryId;
  final String languageCode;
  final DuelStatus status;

  /// Single-round duels stored before series existed: one result per uid.
  final Map<String, DuelScore> results;

  /// Series duels: each uid's result per zero-based round.
  final Map<String, Map<int, DuelScore>> roundResults;

  /// How many rounds the duel is played over. 1 for older duels.
  final int rounds;

  /// The [DuelGame] id. Null for older duels, which were memory boards.
  final String? gameId;

  /// What each side last reported while playing.
  final Map<String, DuelProgress> progress;
  final DateTime? createdAt;

  /// The code others enter to join, for a duel created as a room. Null for
  /// a challenge between friends.
  final String? roomCode;

  /// Display names by uid, written by each player of a room: they need not
  /// be friends, so the friend list cannot name them.
  final Map<String, String> names;

  bool get isRoom => roomCode != null;

  /// Whether results are stored per round rather than as one result.
  bool get isSeries => gameId != null;

  DuelGame get game => DuelGame.byId(gameId);

  List<String> get members => [challengerUid, opponentUid];

  String rivalOf(String uid) =>
      uid == challengerUid ? opponentUid : challengerUid;

  /// [uid]'s result in [round], if they played it.
  DuelScore? scoreOf(String uid, int round) => isSeries
      ? (roundResults[uid]?[round])
      : (round == 0 ? results[uid] : null);

  /// Who won [round]: a uid, `''` for a tie, null while a side is missing.
  String? roundWinner(int round) {
    final challenger = scoreOf(challengerUid, round);
    final opponent = scoreOf(opponentUid, round);
    if (challenger == null || opponent == null) return null;
    final comparison = challenger.compareTo(opponent);
    if (comparison == 0) return '';
    return comparison > 0 ? challengerUid : opponentUid;
  }

  /// Rounds [uid] has won so far.
  int winsOf(String uid) {
    var wins = 0;
    for (var round = 0; round < rounds; round++) {
      if (roundWinner(round) == uid) wins++;
    }
    return wins;
  }

  /// Rounds needed to take the series: 2 of 3.
  int get winsNeeded => rounds ~/ 2 + 1;

  /// Someone already won enough rounds that the rest cannot change it.
  bool get isDecided =>
      winsOf(challengerUid) >= winsNeeded || winsOf(opponentUid) >= winsNeeded;

  /// Decided, or every round played by both.
  bool get isComplete {
    if (opponentUid.isEmpty) return false;
    if (isDecided) return true;
    for (var round = 0; round < rounds; round++) {
      if (roundWinner(round) == null) return false;
    }
    return true;
  }

  /// The next round [uid] has to play, or null when they are done: all
  /// played, or the series already decided.
  int? nextRoundFor(String uid) {
    if (!isActive || isDecided) return null;
    for (var round = 0; round < rounds; round++) {
      if (scoreOf(uid, round) == null) return round;
    }
    return null;
  }

  /// [uid]'s rounds added up, or null if they played none.
  DuelScore? resultOf(String uid) {
    final played = [
      for (var round = 0; round < rounds; round++) ?scoreOf(uid, round),
    ];
    if (played.isEmpty) return null;
    return DuelScore(
      score: played.fold(0, (total, s) => total + s.score),
      seconds: played.fold(0, (total, s) => total + s.seconds),
      moves: played.fold(0, (total, s) => total + s.moves),
    );
  }

  /// Whether [uid] still has to play this duel.
  bool awaitsTurnOf(String uid) => nextRoundFor(uid) != null;

  /// Neither completed nor declined: someone still has to play.
  bool get isActive =>
      status == DuelStatus.pending || status == DuelStatus.open;

  /// A challenge [uid] received and has not started yet.
  bool isInvitationFor(String uid) =>
      uid == opponentUid && awaitsTurnOf(uid) && resultOf(uid) == null;

  /// Null until the duel is complete. More rounds won wins; equal rounds
  /// fall back to the points of every round played.
  DuelOutcome? outcomeFor(String uid) {
    if (!isComplete) return null;
    final rival = rivalOf(uid);
    var comparison = winsOf(uid).compareTo(winsOf(rival));
    if (comparison == 0) {
      final mine = resultOf(uid);
      final theirs = resultOf(rival);
      if (mine != null && theirs != null) comparison = mine.compareTo(theirs);
    }
    if (comparison > 0) return DuelOutcome.won;
    if (comparison < 0) return DuelOutcome.lost;
    return DuelOutcome.draw;
  }

  /// This duel with [uid]'s [score] for [round] already in, as it will be
  /// once Firestore confirms it.
  Duel withRound(String uid, int round, DuelScore score) {
    final updated = Duel(
      id: id,
      challengerUid: challengerUid,
      opponentUid: opponentUid,
      friendshipId: friendshipId,
      seed: seed,
      categoryId: categoryId,
      languageCode: languageCode,
      status: status,
      results: isSeries ? results : {...results, uid: score},
      roundResults: isSeries
          ? {
              ...roundResults,
              uid: {...?roundResults[uid], round: score},
            }
          : roundResults,
      rounds: rounds,
      gameId: gameId,
      progress: progress,
      createdAt: createdAt,
      roomCode: roomCode,
      names: names,
    );
    return updated.isComplete && updated.isActive
        ? updated.withStatus(DuelStatus.completed)
        : updated;
  }

  Duel withStatus(DuelStatus status) => Duel(
    id: id,
    challengerUid: challengerUid,
    opponentUid: opponentUid,
    friendshipId: friendshipId,
    seed: seed,
    categoryId: categoryId,
    languageCode: languageCode,
    status: status,
    results: results,
    roundResults: roundResults,
    rounds: rounds,
    gameId: gameId,
    progress: progress,
    createdAt: createdAt,
    roomCode: roomCode,
    names: names,
  );

  /// Seed for [round]: each round is dealt differently, but the same for
  /// both sides. Round 0 keeps [seed], as single-round duels did.
  int seedFor(int round) => (seed + round * 7919) & 0xFFFFFFFF;

  DuelBoard get board => DuelBoard(this);

  DuelBoard boardFor(int round) => DuelBoard(this, round: round);
}

/// The board both sides of a [Duel] are dealt for a round.
class DuelBoard implements SharedBoard {
  DuelBoard(this.duel, {this.round = 0})
    : category = GameCategories.byId(duel.categoryId);

  final Duel duel;
  final int round;

  static const _engine = AdaptiveDifficulty();
  static const _fixedSkill = SkillState(skill: 0.35, pairCount: Duel.pairCount);

  @override
  final GameCategory category;

  @override
  DifficultySettings get settings => _engine.settingsFor(category, _fixedSkill);

  @override
  Random get random => SeededRandom(duel.seedFor(round));

  @override
  bool operator ==(Object other) =>
      other is DuelBoard && other.duel.id == duel.id && other.round == round;

  @override
  int get hashCode => Object.hash(duel.id, round);
}
