import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/routes/route_paths.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/features/friends/controller/friends_controller.dart';
import 'package:memory_companion/features/friends/widget/friend_tile.dart';
import 'package:memory_companion/features/player/controller/player_controller.dart';
import 'package:memory_companion/features/versus/controller/versus_controller.dart';
import 'package:memory_companion/features/versus/duel_round_host.dart';
import 'package:memory_companion/features/versus/model/duel.dart';
import 'package:memory_companion/features/versus/widget/duel_presence_bar.dart';
import 'package:memory_companion/features/versus/widget/duel_series_view.dart';
import 'package:memory_companion/features/versus/widget/opponent_mirror.dart';

/// A duel: the series between rounds, and each round as it is played,
/// always under the face-off with the rival.
///
/// Like the daily challenge it spends no life and offers no retry: both
/// players get the same rounds, so a second attempt would be played from
/// memory. The duel follows Firestore live, so the rival's rounds, their
/// progress and the final result appear the moment they happen.
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

  /// The round being played on this device, if any.
  int? _round;

  /// This player's latest report, shown in their own race lane and sent
  /// to the rival.
  DuelProgress? _myProgress;
  int _seq = 0;
  DateTime _lastSent = DateTime.fromMillisecondsSinceEpoch(0);

  /// Rounds finished here, shown before Firestore echoes them back.
  final _finished = <int, DuelScore>{};
  bool _submitFailed = false;
  bool _rematchBusy = false;

  Timer? _progressTimer;

  /// How often a plain score change is sent while a round is played.
  static const _progressInterval = Duration(seconds: 2);

  /// Hits and misses go out at once, but never closer than this: a burst
  /// of moves becomes one write carrying the latest.
  static const _eventGap = Duration(milliseconds: 350);

  @override
  void initState() {
    super.initState();
    _versus.setPlaying(playing: true);
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _versus.setPlaying(playing: false);
    super.dispose();
  }

  void _playRound(Duel duel, int round) {
    final start = DuelProgress(round: round, score: 0, seq: ++_seq);
    setState(() {
      _round = round;
      _myProgress = start;
    });
    _send(duel);
  }

  /// Keeps [update] as this player's latest, and gets it to the rival:
  /// straight away for a hit or a miss, batched for a plain score change.
  void _onProgress(Duel duel, DuelProgress update) {
    final round = _round;
    if (round == null) return;
    final urgent = update.event != DuelEvent.none;
    setState(() {
      _myProgress = update.copyWith(round: round, seq: urgent ? ++_seq : _seq);
    });
    if (urgent) {
      _progressTimer?.cancel();
      final wait = _eventGap - DateTime.now().difference(_lastSent);
      if (wait <= Duration.zero) {
        _send(duel);
      } else {
        _progressTimer = Timer(wait, () => _send(duel));
      }
    } else if (!(_progressTimer?.isActive ?? false)) {
      _progressTimer = Timer(_progressInterval, () => _send(duel));
    }
  }

  void _send(Duel duel) {
    final progress = _myProgress;
    if (!mounted || progress == null) return;
    _lastSent = DateTime.now();
    // Not awaited: offline, Firestore queues it and the round goes on.
    _versus.reportProgress(duel, progress);
  }

  Future<void> _onRoundFinished(Duel duel, int round, DuelScore score) async {
    // The last hit goes out before the round closes, so the rival sees it.
    if (_progressTimer?.isActive ?? false) _send(duel);
    _progressTimer?.cancel();
    setState(() {
      _finished[round] = score;
      _round = null;
    });
    final sent = await _versus.submitResult(duel, score, round: round);
    if (!sent && mounted) setState(() => _submitFailed = true);
  }

  Future<void> _rematch(Duel duel) async {
    setState(() => _rematchBusy = true);
    final next = await _versus.rematch(
      duel,
      languageCode: Localizations.localeOf(context).languageCode,
    );
    if (!mounted) return;
    setState(() => _rematchBusy = false);
    if (next == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocale.duelCreateFailed.getString(context))),
      );
      return;
    }
    if (next.roomCode case final code?) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocale.rematchRoomCreated
                .getString(context)
                .replaceAll('{code}', code),
          ),
        ),
      );
    }
    Navigator.of(
      context,
    ).pushReplacementNamed(RoutePaths.duel, arguments: next);
  }

  void _exit() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(socialUidProvider).value;
    final live = ref.watch(duelProvider(widget.duel.id));

    // Wait for the live duel: a round already played must not be offered
    // again, and dealing a board starts its preview clock.
    if (uid == null || (!live.hasValue && !live.hasError)) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    var duel = live.value ?? widget.duel;
    for (final MapEntry(key: round, value: score) in _finished.entries) {
      if (duel.scoreOf(uid, round) == null) {
        duel = duel.withRound(uid, round, score);
      }
    }

    final rivalUid = duel.rivalOf(uid);
    final myName = displayNameOr(
      context,
      ref.watch(localPlayerProvider).value?.displayName ?? '',
    );
    final rivalName = displayNameOr(
      context,
      ref.watch(versusControllerProvider).value?.nameOf(rivalUid, duel: duel) ??
          duel.names[rivalUid] ??
          '',
    );
    final rivalStatus = ref
        .watch(friendsControllerProvider)
        .value
        ?.friends
        .where((friend) => friend.uid == rivalUid)
        .firstOrNull
        ?.status;

    final round = _round;
    if (round != null) {
      // The rival's report counts here only for this same round.
      final report = duel.progress[rivalUid];
      final rivalRound = report?.round == round ? report : null;
      final rivalLive =
          rivalRound != null &&
          rivalRound.isLive(DateTime.now()) &&
          duel.scoreOf(rivalUid, round) == null;
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            SafeArea(
              bottom: false,
              child: DuelPresenceBar(
                duel: duel,
                uid: uid,
                myName: myName,
                rivalName: rivalName,
                rivalStatus: rivalStatus,
                round: round,
                myProgress: _myProgress,
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    child: DuelRoundHost(
                      duel: duel,
                      round: round,
                      onProgress: (update) => _onProgress(duel, update),
                      onFinished: (score) =>
                          _onRoundFinished(duel, round, score),
                      onExit: _exit,
                    ),
                  ),
                  // Below the game's own app bar, clear of its title.
                  Positioned(
                    top: kToolbarHeight + 8,
                    right: 12,
                    child: OpponentMirror(
                      game: duel.game,
                      rivalName: rivalName,
                      progress: rivalRound,
                      live: rivalLive,
                      finishedScore: duel.scoreOf(rivalUid, round)?.score,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: RivalEventBanner(
                        progress: rivalRound,
                        rivalName: rivalName,
                        game: duel.game,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: DuelSeriesView(
          duel: duel,
          uid: uid,
          myName: myName,
          rivalName: rivalName,
          rivalStatus: rivalStatus,
          submitFailed: _submitFailed,
          rematchBusy: _rematchBusy,
          onPlayRound: (next) => _playRound(duel, next),
          onRematch: () => _rematch(duel),
          onExit: _exit,
        ),
      ),
    );
  }
}
