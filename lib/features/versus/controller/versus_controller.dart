import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/connectivity/controller/connection_status_controller.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/features/friends/controller/friends_controller.dart';
import 'package:memory_companion/features/friends/model/friend.dart';
import 'package:memory_companion/features/friends/model/friend_code.dart';
import 'package:memory_companion/features/game_context/controller/game_context_providers.dart';
import 'package:memory_companion/features/game/board/category/game_categories.dart';
import 'package:memory_companion/features/player/controller/player_controller.dart';
import 'package:memory_companion/features/player/model/player_level.dart';
import 'package:memory_companion/features/settings/controller/display_preferences_controller.dart';
import 'package:memory_companion/features/versus/cpu/cpu_opponent.dart';
import 'package:memory_companion/features/versus/model/duel.dart';
import 'package:memory_companion/features/versus/model/duel_game.dart';
import 'package:memory_companion/features/versus/model/room_code.dart';
import 'package:memory_companion/features/versus/model/versus_player.dart';
import 'package:memory_companion/features/versus/repository/duel_repository.dart';

final duelRepositoryProvider = Provider<DuelRepository>(
  (ref) => DuelRepository(),
);

/// Source of duel seeds and categories. Overridden in tests.
final duelRandomProvider = Provider<Random>((ref) => Random());

final duelsProvider = StreamProvider.autoDispose.family<List<Duel>, String>(
  (ref, uid) => ref.watch(duelRepositoryProvider).watchDuels(uid),
);

final duelProvider = StreamProvider.autoDispose.family<Duel?, String>(
  (ref, id) => ref.watch(duelRepositoryProvider).watchDuel(id),
);

/// Whether matchmaking may try Firestore. Overridden in tests, where the
/// connectivity plugin is missing.
final versusOnlineProvider = Provider<bool>(
  (ref) =>
      ref.watch(connectionStatusControllerProvider) == ConnectionStatus.online,
);

/// How the player asked to play from the Versus "Play" button.
enum PlayMode { online, nearby }

/// Where matchmaking is looking, for the progress dialog.
enum MatchPhase { online, nearby }

/// What matchmaking settled on: a duel against a real player, or a match
/// against the computer when nobody was found.
sealed class MatchResult {
  const MatchResult();
}

class DuelMatch extends MatchResult {
  const DuelMatch(this.duel);

  final Duel duel;
}

class CpuMatch extends MatchResult {
  const CpuMatch(this.level);

  final CpuLevel level;
}

/// The game the player picked for their next duel.
class SelectedDuelGame extends Notifier<DuelGame> {
  @override
  DuelGame build() => DuelGame.memory;

  void select(DuelGame game) => state = game;
}

final selectedDuelGameProvider = NotifierProvider<SelectedDuelGame, DuelGame>(
  SelectedDuelGame.new,
);

/// The friend the player means to challenge. Null picks the first friend.
class SelectedRival extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? uid) => state = uid;
}

final selectedRivalProvider = NotifierProvider<SelectedRival, String?>(
  SelectedRival.new,
);

class VersusState {
  const VersusState({
    required this.me,
    this.uid,
    this.rivals = const [],
    this.rival,
    this.rivalCard,
    this.toPlay = const [],
    this.waiting = const [],
    this.finished = const [],
  });

  final VersusPlayer me;

  /// Null without an account: duels need one.
  final String? uid;

  /// Friends who can be challenged.
  final List<Friend> rivals;
  final Friend? rival;
  final VersusPlayer? rivalCard;

  /// Duels waiting for the player's turn: challenges received, or their own
  /// that they left before finishing.
  final List<Duel> toPlay;

  /// Duels the player has played, waiting for the rival.
  final List<Duel> waiting;

  /// Completed or declined, newest first.
  final List<Duel> finished;

  bool get isSignedIn => uid != null;

  /// A rival's name, for the duel lists. Rooms carry their players' names;
  /// otherwise it comes from the friend list, and is empty for someone who
  /// is no longer a friend.
  String nameOf(String uid, {Duel? duel}) =>
      rivals.where((friend) => friend.uid == uid).firstOrNull?.name ??
      duel?.names[uid] ??
      '';
}

/// The Versus screen: who the player is up against, and their duels.
class VersusController extends AsyncNotifier<VersusState> {
  /// How many results the form dots show.
  static const formLength = 5;

  @override
  Future<VersusState> build() async {
    final player = await ref.watch(localPlayerProvider.future);
    final uid = await ref.watch(socialUidProvider.future);

    VersusPlayer meCard(List<bool> form) => VersusPlayer(
      name: player.displayName,
      level: levelFromTotalXp(player.totalXp),
      totalXp: player.totalXp,
      levelProgress: levelProgress(player.totalXp),
      formWins: form,
      accentColor: AppColors.secondaryContainer,
    );

    if (uid == null) return VersusState(me: meCard(const []));

    final friends = await ref.watch(friendsControllerProvider.future);
    final duels = await ref.watch(duelsProvider(uid).future);
    final selected = ref.watch(selectedRivalProvider);

    final rivals = friends.friends;
    final rival =
        rivals.where((f) => f.uid == selected).firstOrNull ??
        rivals.firstOrNull;

    final completed = [
      for (final duel in duels)
        if (duel.status == DuelStatus.completed) duel,
    ];

    VersusPlayer? rivalCard;
    if (rival != null) {
      final headToHead = completed.where((d) => d.rivalOf(uid) == rival.uid);
      rivalCard = VersusPlayer(
        name: rival.name,
        level: rival.level,
        totalXp: rival.totalXp,
        levelProgress: levelProgress(rival.totalXp),
        formWins: _form(headToHead, rival.uid),
        accentColor: AppColors.error,
        reversed: true,
      );
    }

    return VersusState(
      me: meCard(_form(completed, uid)),
      uid: uid,
      rivals: rivals,
      rival: rival,
      rivalCard: rivalCard,
      toPlay: [
        for (final duel in duels)
          if (duel.awaitsTurnOf(uid)) duel,
      ],
      waiting: [
        for (final duel in duels)
          if (duel.isActive && !duel.awaitsTurnOf(uid)) duel,
      ],
      finished: [
        for (final duel in duels)
          if (!duel.isActive) duel,
      ],
    );
  }

  /// [uid]'s latest results in [duels] (newest first), oldest first.
  static List<bool> _form(Iterable<Duel> duels, String uid) => [
    for (final duel in duels.take(formLength).toList().reversed)
      duel.outcomeFor(uid) == DuelOutcome.won,
  ];

  void selectRival(String uid) =>
      ref.read(selectedRivalProvider.notifier).select(uid);

  /// Finds someone to play, falling back step by step so the player always
  /// gets a match: an online opponent (for [PlayMode.online], when there is
  /// a connection), then a friend within Bluetooth range, then the
  /// computer at a level suited to the player's.
  Future<MatchResult> findMatch({
    required PlayMode mode,
    required String languageCode,
    void Function(MatchPhase phase)? onPhase,
  }) async {
    final uid = await ref.read(socialUidProvider.future);
    if (uid != null) {
      if (mode == PlayMode.online && ref.read(versusOnlineProvider)) {
        onPhase?.call(MatchPhase.online);
        final duel = await _findOnline(uid, languageCode);
        if (duel != null) return DuelMatch(duel);
      }
      onPhase?.call(MatchPhase.nearby);
      final duel = await _findNearby(uid, languageCode);
      if (duel != null) return DuelMatch(duel);
    }
    final player = await ref.read(localPlayerProvider.future);
    return CpuMatch(cpuLevelFor(levelFromTotalXp(player.totalXp)));
  }

  /// The computer's level for a player at [level].
  static CpuLevel cpuLevelFor(int level) {
    if (level >= 10) return CpuLevel.hard;
    if (level >= 5) return CpuLevel.normal;
    return CpuLevel.easy;
  }

  /// Takes a seat in a stranger's open room, or else challenges the
  /// selected friend.
  Future<Duel?> _findOnline(String uid, String languageCode) async {
    final repository = ref.read(duelRepositoryProvider);
    try {
      final room = await repository
          .findAnyOpenRoom(excludingUid: uid)
          .timeout(_networkTimeout);
      if (room != null) {
        final player = await ref.read(localPlayerProvider.future);
        final joined = await repository
            .joinRoom(room: room, uid: uid, name: player.displayName)
            .timeout(_networkTimeout);
        if (joined != null) return joined;
      }
    } on Exception {
      // Falls through to the friend, then to the next step.
    }
    final rival = state.value?.rival;
    if (rival == null) return null;
    return _challenge(uid, rival, languageCode);
  }

  /// Challenges the first friend heard over Bluetooth. Strangers are not
  /// matched: a duel is only shared with a friend or through a room.
  Future<Duel?> _findNearby(String uid, String languageCode) async {
    final radio = ref.read(nearbyRadioProvider);
    final own = FriendCode.fromUid(uid);
    try {
      if (!await radio.requestPermission()) return null;
      await radio.startAdvertising(own);
      final Set<String>? heard;
      try {
        heard = await radio.scan(nearbyScanDuration);
      } finally {
        if (!ref.read(displayPreferencesProvider).contextNearby) {
          await radio.stopAdvertising();
        }
      }
      if (heard == null || !ref.mounted) return null;
      final rival = state.value?.rivals
          .where((friend) => heard!.contains(FriendCode.fromUid(friend.uid)))
          .firstOrNull;
      if (rival == null) return null;
      return await _challenge(uid, rival, languageCode);
    } on Exception {
      return null;
    }
  }

  /// How long the nearby step listens.
  static const nearbyScanDuration = Duration(seconds: 8);

  /// Firestore waits forever offline; matchmaking moves on instead.
  static const _networkTimeout = Duration(seconds: 8);

  /// Challenges the selected rival to a new duel, dealt in [languageCode].
  /// Returns the duel to play, or null if it could not be created.
  Future<Duel?> startDuel({required String languageCode}) async {
    final current = state.value;
    final uid = current?.uid;
    final rival = current?.rival;
    if (uid == null || rival == null) return null;
    return _challenge(uid, rival, languageCode);
  }

  Future<Duel?> _challenge(
    String uid,
    Friend rival,
    String languageCode, {
    DuelGame? game,
  }) async {
    final random = ref.read(duelRandomProvider);
    final categories = GameCategories.all;
    try {
      return await ref
          .read(duelRepositoryProvider)
          .create(
            challengerUid: uid,
            opponentUid: rival.uid,
            friendshipId: rival.friendshipId,
            seed: Duel.newSeed(random),
            categoryId: categories[random.nextInt(categories.length)].id,
            languageCode: languageCode,
            game: game ?? ref.read(selectedDuelGameProvider),
          )
          .timeout(_networkTimeout);
    } on Exception {
      return null;
    }
  }

  /// Opens a room for anyone with its code, dealt in [languageCode].
  /// Returns the room to play, or null if it could not be created.
  Future<Duel?> createRoom({
    required String languageCode,
    DuelGame? game,
  }) async {
    final uid = await ref.read(socialUidProvider.future);
    if (uid == null) return null;
    final player = await ref.read(localPlayerProvider.future);
    final repository = ref.read(duelRepositoryProvider);
    final random = ref.read(duelRandomProvider);
    final categories = GameCategories.all;
    try {
      // A clash with another open room is unlikely (31^6 codes), but a
      // shared code would send the guest to a stranger's room.
      var code = RoomCode.generate(random);
      for (
        var i = 0;
        i < 3 && await repository.findOpenRoom(code) != null;
        i++
      ) {
        code = RoomCode.generate(random);
      }
      return await repository.createRoom(
        hostUid: uid,
        hostName: player.displayName,
        roomCode: code,
        seed: Duel.newSeed(random),
        categoryId: categories[random.nextInt(categories.length)].id,
        languageCode: languageCode,
        game: game ?? ref.read(selectedDuelGameProvider),
      );
    } on Exception {
      return null;
    }
  }

  /// Joins the room behind [input]. The player's own open room is returned
  /// as is, so the host can enter their code to go back to it.
  Future<JoinRoomResult> joinRoom(String input) async {
    final uid = await ref.read(socialUidProvider.future);
    if (uid == null) return const JoinRoomResult(JoinRoomStatus.signedOut);
    final code = RoomCode.normalize(input);
    if (code == null) return const JoinRoomResult(JoinRoomStatus.invalidCode);

    final repository = ref.read(duelRepositoryProvider);
    try {
      final room = await repository.findOpenRoom(code);
      if (room == null) return const JoinRoomResult(JoinRoomStatus.notFound);
      if (room.challengerUid == uid) {
        return JoinRoomResult(JoinRoomStatus.joined, room);
      }
      final player = await ref.read(localPlayerProvider.future);
      final joined = await repository.joinRoom(
        room: room,
        uid: uid,
        name: player.displayName,
      );
      return joined == null
          ? const JoinRoomResult(JoinRoomStatus.notFound)
          : JoinRoomResult(JoinRoomStatus.joined, joined);
    } on Exception {
      return const JoinRoomResult(JoinRoomStatus.failed);
    }
  }

  /// Saves the player's result for [round] of [duel]. Returns false if it
  /// could not be sent; Firestore retries queued writes once the
  /// connection returns.
  Future<bool> submitResult(Duel duel, DuelScore score, {int round = 0}) async {
    final uid = await ref.read(socialUidProvider.future);
    if (uid == null) return false;
    final repository = ref.read(duelRepositoryProvider);
    try {
      if (duel.isSeries) {
        await repository.submitRound(
          duelId: duel.id,
          uid: uid,
          round: round,
          score: score,
        );
      } else {
        await repository.submitResult(duelId: duel.id, uid: uid, score: score);
      }
      return true;
    } on Exception {
      return false;
    }
  }

  /// Lets the rival follow a round of [duel] as it is played. Best effort,
  /// like [setPlaying].
  Future<void> reportProgress(Duel duel, DuelProgress progress) async {
    try {
      final uid = await ref.read(socialUidProvider.future);
      if (uid == null || !duel.isSeries) return;
      await ref
          .read(duelRepositoryProvider)
          .reportProgress(duelId: duel.id, uid: uid, progress: progress);
    } on Exception {
      // Ignored on purpose.
    }
  }

  /// A new duel against the same rival on the same game. Friends are
  /// challenged straight away; anyone else gets a fresh room to share,
  /// since only friends can be challenged directly.
  Future<Duel?> rematch(Duel duel, {required String languageCode}) async {
    final uid = await ref.read(socialUidProvider.future);
    if (uid == null) return null;
    final rivalUid = duel.rivalOf(uid);
    final friend = state.value?.rivals
        .where((f) => f.uid == rivalUid)
        .firstOrNull;
    if (friend != null) {
      return _challenge(uid, friend, languageCode, game: duel.game);
    }
    return createRoom(languageCode: languageCode, game: duel.game);
  }

  /// Shows the player as "in game" to their friends while they duel.
  /// Best effort: presence is decoration, never worth an error.
  Future<void> setPlaying({required bool playing}) async {
    try {
      final uid = await ref.read(socialUidProvider.future);
      if (uid == null) return;
      await ref
          .read(socialRepositoryProvider)
          .setPlaying(uid, playing: playing);
    } on Exception {
      // Ignored on purpose.
    }
  }

  /// Turns down a challenge. Returns false if it could not be saved.
  Future<bool> decline(Duel duel) async {
    try {
      await ref.read(duelRepositoryProvider).decline(duel.id);
      return true;
    } on Exception {
      return false;
    }
  }
}

enum JoinRoomStatus { joined, invalidCode, notFound, signedOut, failed }

class JoinRoomResult {
  const JoinRoomResult(this.status, [this.duel]);

  final JoinRoomStatus status;

  /// The room to play, when [status] is [JoinRoomStatus.joined].
  final Duel? duel;
}

final versusControllerProvider =
    AsyncNotifierProvider<VersusController, VersusState>(VersusController.new);
