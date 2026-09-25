import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/features/game/board/board_screen.dart';
import 'package:memory_companion/features/game/board/category/game_categories.dart';
import 'package:memory_companion/features/game/board/controller/board_controller.dart';
import 'package:memory_companion/features/game/board/model/board_state.dart';
import 'package:memory_companion/features/versus/cpu/cpu_opponent.dart';
import 'package:memory_companion/features/versus/model/duel.dart';
import 'package:memory_companion/features/versus/widget/duel_result_overlay.dart';

/// A duel against the computer. Entirely on the device: it needs neither an
/// account nor a connection, and saves nothing to the cloud.
///
/// The board is dealt like a friend duel's, so the computer plays by the
/// same rules; its result is revealed when the player finishes.
class CpuDuelPage extends ConsumerStatefulWidget {
  const CpuDuelPage({super.key, required this.level});

  final CpuLevel level;

  @override
  ConsumerState<CpuDuelPage> createState() => _CpuDuelPageState();
}

class _CpuDuelPageState extends ConsumerState<CpuDuelPage> {
  late final Duel _duel = _newDuel();
  DuelScore? _mine;
  DuelScore? _cpu;

  Duel _newDuel() {
    final random = Random();
    final categories = GameCategories.all;
    final seed = Duel.newSeed(random);
    return Duel(
      id: 'cpu-$seed',
      challengerUid: 'me',
      opponentUid: 'cpu',
      friendshipId: '',
      seed: seed,
      categoryId: categories[random.nextInt(categories.length)].id,
      languageCode: 'es',
      status: DuelStatus.pending,
    );
  }

  SharedBoardSetup _setup(BuildContext context) => (
    board: _duel.board,
    languageCode: Localizations.localeOf(context).languageCode,
  );

  void _onCompleted(BoardState board) {
    setState(() {
      _mine = DuelScore(
        score: board.score,
        seconds: board.elapsedSeconds,
        moves: board.moves,
      );
      _cpu = CpuOpponent.play(
        seed: _duel.seed,
        pairCount: board.pairCount,
        timeLimitSeconds: board.totalSeconds,
        level: widget.level,
      );
    });
  }

  void _exit() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final provider = sharedBoardControllerProvider(_setup(context));
    ref.listen(provider, (previous, next) {
      if (next.isCompleted && previous?.isCompleted != true) {
        _onCompleted(next);
      }
    });

    final board = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final mine = _mine;

    return BoardScreen(
      state: board,
      onCardTap: controller.flipCard,
      onTogglePause: controller.togglePause,
      onHint: controller.useHint,
      // Unreachable: the duel result replaces the overlay that offers it.
      onRestart: () {},
      onExit: _exit,
      lives: 0,
      isLivesUnlimited: true,
      completionOverlay: mine == null
          ? null
          : DuelResultOverlay(
              mine: mine,
              theirs: _cpu,
              rivalName: AppLocale.cpuName
                  .getString(context)
                  .replaceAll('{level}', widget.level.labelKey.getString(context)),
              celebrate: true,
              onExit: _exit,
            ),
    );
  }
}
