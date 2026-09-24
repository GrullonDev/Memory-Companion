import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/features/friends/controller/friends_controller.dart';
import 'package:memory_companion/features/friends/model/friend.dart';
import 'package:memory_companion/features/game/board/category/game_categories.dart';
import 'package:memory_companion/features/player/controller/player_controller.dart';
import 'package:memory_companion/features/player/model/player_level.dart';
import 'package:memory_companion/features/versus/model/duel.dart';
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

  /// A rival's name, for the duel lists. Empty if they are no longer a
  /// friend.
  String nameOf(String uid) =>
      rivals.where((friend) => friend.uid == uid).firstOrNull?.name ?? '';
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
          if (duel.status == DuelStatus.pending && !duel.awaitsTurnOf(uid))
            duel,
      ],
      finished: [
        for (final duel in duels)
          if (duel.status != DuelStatus.pending) duel,
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

  /// Challenges the selected rival to a new duel, dealt in [languageCode].
  /// Returns the duel to play, or null if it could not be created.
  Future<Duel?> startDuel({required String languageCode}) async {
    final current = state.value;
    final uid = current?.uid;
    final rival = current?.rival;
    if (uid == null || rival == null) return null;

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
          );
    } on Exception {
      return null;
    }
  }

  /// Saves the player's result for [duel]. Returns false if it could not be
  /// sent; Firestore retries queued writes once the connection returns.
  Future<bool> submitResult(Duel duel, DuelScore score) async {
    final uid = await ref.read(socialUidProvider.future);
    if (uid == null) return false;
    try {
      await ref
          .read(duelRepositoryProvider)
          .submitResult(duelId: duel.id, uid: uid, score: score);
      return true;
    } on Exception {
      return false;
    }
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

final versusControllerProvider =
    AsyncNotifierProvider<VersusController, VersusState>(VersusController.new);
