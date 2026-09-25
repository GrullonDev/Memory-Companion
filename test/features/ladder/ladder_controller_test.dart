import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/core/database/app_database.dart';
import 'package:memory_companion/core/database/database_provider.dart';
import 'package:memory_companion/features/game/board/category/game_categories.dart';
import 'package:memory_companion/features/game/board/difficulty/adaptive_difficulty.dart';
import 'package:memory_companion/features/game/board/difficulty/adaptive_difficulty_controller.dart';
import 'package:memory_companion/features/game/board/difficulty/skill_repository.dart';
import 'package:memory_companion/features/ladder/game_ladder.dart';
import 'package:memory_companion/features/ladder/ladder_controller.dart';
import 'package:memory_companion/features/minigames/core/minigame_result.dart';
import 'package:memory_companion/features/minigames/core/minigame_result_reporter.dart';
import 'package:memory_companion/features/minigames/modules/crossword/crossword_game_module.dart';
import 'package:memory_companion/features/minigames/modules/digits/digits_game_module.dart';
import 'package:memory_companion/features/player/controller/player_controller.dart';
import 'package:memory_companion/features/statistics/controller/statistics_controller.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        statsClockProvider.overrideWithValue(() => DateTime(2026, 9, 25)),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  MinigameResult round({required bool won}) => MinigameResult(
    variantId: 'es',
    itemCount: 3,
    itemsSolved: won ? 3 : 1,
    attempts: 4,
    errors: 1,
    hintsUsed: 0,
    secondsElapsed: 30,
    timeLimitSeconds: 0,
    timed: false,
    won: won,
    score: 100,
  );

  Future<int> coins() async =>
      (await container.read(playerRepositoryProvider).readLocalProfile())
          ?.totalCoins ??
      0;

  GameLadder ladderFor(String id) =>
      container.read(gameLaddersProvider).firstWhere((l) => l.id == id);

  Future<GameLadder> waitForLadder(String id, int level) async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (DateTime.now().isBefore(deadline)) {
      final ladder = ladderFor(id);
      if (ladder.level == level) return ladder;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    fail('la escalera $id nunca llegó al nivel $level');
  }

  test('hay una escalera por modo de tablero y por minijuego', () {
    final ids = container.read(gameLaddersProvider).map((l) => l.id);
    expect(ids, [
      'classic',
      'numeric',
      'association',
      'game:digits',
      'game:words',
      'game:crossword',
    ]);
  });

  test('cada ronda ganada de un minijuego sube un peldaño', () async {
    container.listen(gameLaddersProvider, (_, _) {});
    container.listen(winsByStatsKeyProvider, (_, _) {});
    final reporter = container.read(minigameResultReporterProvider);
    const game = CrosswordGameModule();
    final id = GameLadder.minigameId(game);

    await reporter.report(game, round(won: true));
    await reporter.report(game, round(won: false));
    await reporter.report(game, round(won: true));

    await waitForLadder(id, 3);
    // Los demás juegos no se mueven.
    expect(ladderFor(GameLadder.minigameId(const DigitsGameModule())).level, 1);
  });

  test('el quinto nivel de un minijuego paga su regalo y lo anuncia', () async {
    final reporter = container.read(minigameResultReporterProvider);
    const game = CrosswordGameModule();
    final id = GameLadder.minigameId(game);

    for (var i = 0; i < 4; i++) {
      await reporter.report(game, round(won: true));
    }
    expect(container.read(ladderRoundNoticesProvider)[id]!.rewards, isEmpty);
    expect(await coins(), 0);

    await reporter.report(game, round(won: true));
    final notice = container.read(ladderRoundNoticesProvider)[id]!;
    expect(notice.completedLevel, 5);
    expect(notice.rewards.single.level, 5);
    expect(await coins(), 100);

    // La ronda siguiente no repite el premio ni el anuncio.
    await reporter.report(game, round(won: false));
    expect(container.read(ladderRoundNoticesProvider)[id]!.rewards, isEmpty);
    expect(
      container.read(ladderRoundNoticesProvider)[id]!.completedLevel,
      isNull,
    );
    expect(await coins(), 100);
  });

  test('al arrancar se pagan los premios ganados antes de existir', () async {
    // Un jugador que ya iba por el nivel 7 del clásico al actualizar.
    await SkillRepository(database: db).save(
      GameCategories.classic.id,
      const SkillState(skill: 0.5, pairCount: 6, level: 7),
    );

    container.read(adaptiveDifficultyProvider);
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (await coins() != 100 && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(await coins(), 100);
    expect(ladderFor('classic').level, 7);
  });
}
