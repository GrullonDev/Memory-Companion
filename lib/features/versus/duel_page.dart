import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/features/friends/controller/friends_controller.dart';
import 'package:memory_companion/features/friends/widget/friend_tile.dart';
import 'package:memory_companion/features/game/board/board_screen.dart';
import 'package:memory_companion/features/game/board/controller/board_controller.dart';
import 'package:memory_companion/features/game/board/model/board_state.dart';
import 'package:memory_companion/features/versus/controller/versus_controller.dart';
import 'package:memory_companion/features/versus/model/duel.dart';
import 'package:memory_companion/features/versus/widget/duel_result_overlay.dart';

/// Plays one side of a [Duel], or shows its result if that side is done.
///
/// Like the daily challenge it spends no life and offers no retry: both
/// players get the same board, so a second attempt would be played from
/// memory. The result follows the duel live, so the outcome appears the
/// moment the rival finishes.
class DuelPage extends ConsumerStatefulWidget {
  const DuelPage({super.key, required this.duel});

  final Duel duel;

  @override
  ConsumerState<DuelPage> createState() => _DuelPageState();
}

class _DuelPageState extends ConsumerState<DuelPage> {
  /// Read once, so it can still be used from [dispose].
  late final VersusController _versus = ref.read(
    versusControllerProvider.notifier,
  );

  /// Set the moment this visit completes the board, before Firestore
  /// answers.
  DuelScore? _finished;
  bool _submitFailed = false;

  SharedBoardSetup get _setup =>
      (board: widget.duel.board, languageCode: widget.duel.languageCode);

  @override
  void initState() {
    super.initState();
    _versus.setPlaying(playing: true);
  }

  @override
  void dispose() {
    _versus.setPlaying(playing: false);
    super.dispose();
  }

  Future<void> _onCompleted(BoardState board) async {
    final score = DuelScore(
      score: board.score,
      seconds: board.elapsedSeconds,
      moves: board.moves,
    );
    setState(() => _finished = score);
    final sent = await _versus.submitResult(widget.duel, score);
    if (!sent && mounted) setState(() => _submitFailed = true);
  }

  void _exit() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(socialUidProvider).value;
    final live = ref.watch(duelProvider(widget.duel.id));
    final duel = live.value ?? widget.duel;
    final rivalUid = uid == null ? duel.opponentUid : duel.rivalOf(uid);
    final rivalName = displayNameOr(
      context,
      ref.watch(versusControllerProvider).value?.nameOf(rivalUid, duel: duel) ??
          duel.names[rivalUid] ??
          '',
    );

    Widget overlay(DuelScore mine, {required bool celebrate}) =>
        DuelResultOverlay(
          mine: mine,
          theirs: duel.resultOf(rivalUid),
          rivalName: rivalName,
          declined: duel.status == DuelStatus.declined,
          submitFailed: _submitFailed,
          celebrate: celebrate,
          onExit: _exit,
        );

    final finished = _finished;
    // Wait for the live duel before dealing: a side already played must not
    // flash its board, and dealing starts the preview clock.
    if (finished == null && !live.hasValue && !live.hasError) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final earlier = uid == null ? null : duel.resultOf(uid);
    if (finished == null && earlier != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(child: overlay(earlier, celebrate: false)),
      );
    }

    final provider = sharedBoardControllerProvider(_setup);
    ref.listen(provider, (previous, next) {
      if (next.isCompleted && previous?.isCompleted != true) {
        _onCompleted(next);
      }
    });

    final board = ref.watch(provider);
    final controller = ref.read(provider.notifier);

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
      completionOverlay: finished == null
          ? null
          : overlay(finished, celebrate: true),
    );
  }
}
