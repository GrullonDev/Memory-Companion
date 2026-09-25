import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:memory_companion/features/daily_challenge/model/daily_seed.dart';
import 'package:memory_companion/features/game/board/category/game_categories.dart';
import 'package:memory_companion/features/game/board/category/game_category.dart';
import 'package:memory_companion/features/game/board/difficulty/adaptive_difficulty.dart';
import 'package:memory_companion/features/game/board/difficulty/difficulty_settings.dart';
import 'package:memory_companion/features/game/board/model/shared_board.dart';

/// [open] is a room nobody has joined yet: the host can already play it,
/// and whoever enters its code becomes the opponent.
enum DuelStatus { open, pending, completed, declined }

enum DuelOutcome { won, lost, draw }

/// One side's result in a duel.
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

/// An asynchronous duel: two friends play the same board, each when they
/// can, and the better result wins.
///
/// Both sides are dealt from [seed] with fixed settings, in the challenger's
/// card language, so the boards are identical. That is what lets a duel
/// work without both players being online at the same moment.
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
    this.createdAt,
    this.roomCode,
    this.names = const {},
  });

  /// Only a decline is stored as a status. "Completed" is derived from both
  /// results being in, so each side writes nothing but its own result — a
  /// write that Firestore can queue while offline.
  factory Duel.fromFirestore(String id, Map<String, dynamic> data) {
    final created = data['createdAt'];
    final rawResults = data['results'];
    final challengerUid = data['challengerUid'] as String? ?? '';
    final opponentUid = data['opponentUid'] as String? ?? '';
    final results = <String, DuelScore>{
      if (rawResults is Map)
        for (final entry in rawResults.entries)
          if (entry.value is Map)
            entry.key as String: DuelScore.fromMap(
              Map<String, dynamic>.from(entry.value as Map),
            ),
    };
    final rawNames = data['names'];
    final bothPlayed =
        results.containsKey(challengerUid) && results.containsKey(opponentUid);
    return Duel(
      id: id,
      challengerUid: challengerUid,
      opponentUid: opponentUid,
      friendshipId: data['friendshipId'] as String? ?? '',
      seed: (data['seed'] as num?)?.toInt() ?? 0,
      categoryId: data['categoryId'] as String? ?? '',
      languageCode: data['languageCode'] as String? ?? 'es',
      status: bothPlayed
          ? DuelStatus.completed
          : switch (data['status']) {
              'declined' => DuelStatus.declined,
              'open' => DuelStatus.open,
              _ => DuelStatus.pending,
            },
      results: results,
      createdAt: created is Timestamp ? created.toDate() : null,
      roomCode: data['roomCode'] as String?,
      names: {
        if (rawNames is Map)
          for (final entry in rawNames.entries)
            if (entry.value is String)
              entry.key as String: entry.value as String,
      },
    );
  }

  /// Pairs dealt on a duel board. Same as the daily challenge: a short,
  /// fair board that nobody is locked out of.
  static const pairCount = 6;

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
  final Map<String, DuelScore> results;
  final DateTime? createdAt;

  /// The code others enter to join, for a duel created as a room. Null for
  /// a challenge between friends.
  final String? roomCode;

  /// Display names by uid, written by each player of a room: they need not
  /// be friends, so the friend list cannot name them.
  final Map<String, String> names;

  bool get isRoom => roomCode != null;

  List<String> get members => [challengerUid, opponentUid];

  String rivalOf(String uid) =>
      uid == challengerUid ? opponentUid : challengerUid;

  DuelScore? resultOf(String uid) => results[uid];

  /// Whether [uid] still has to play this duel.
  bool awaitsTurnOf(String uid) =>
      (status == DuelStatus.pending || status == DuelStatus.open) &&
      !results.containsKey(uid);

  /// Neither completed nor declined: someone still has to play.
  bool get isActive =>
      status == DuelStatus.pending || status == DuelStatus.open;

  /// A challenge [uid] received and has not answered yet.
  bool isInvitationFor(String uid) => uid == opponentUid && awaitsTurnOf(uid);

  /// Null until both sides have played.
  DuelOutcome? outcomeFor(String uid) {
    final mine = results[uid];
    final theirs = results[rivalOf(uid)];
    if (mine == null || theirs == null) return null;
    final comparison = mine.compareTo(theirs);
    if (comparison > 0) return DuelOutcome.won;
    if (comparison < 0) return DuelOutcome.lost;
    return DuelOutcome.draw;
  }

  DuelBoard get board => DuelBoard(this);
}

/// The board both sides of a [Duel] are dealt.
class DuelBoard implements SharedBoard {
  DuelBoard(this.duel) : category = GameCategories.byId(duel.categoryId);

  final Duel duel;

  static const _engine = AdaptiveDifficulty();
  static const _fixedSkill = SkillState(skill: 0.35, pairCount: Duel.pairCount);

  @override
  final GameCategory category;

  @override
  DifficultySettings get settings => _engine.settingsFor(category, _fixedSkill);

  @override
  Random get random => SeededRandom(duel.seed);

  @override
  bool operator ==(Object other) =>
      other is DuelBoard && other.duel.id == duel.id;

  @override
  int get hashCode => duel.id.hashCode;
}
