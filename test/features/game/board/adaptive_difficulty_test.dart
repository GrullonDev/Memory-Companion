import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/features/game/board/category/game_categories.dart';
import 'package:memory_companion/features/game/board/category/game_category.dart';
import 'package:memory_companion/features/game/board/difficulty/adaptive_difficulty.dart';

const _engine = AdaptiveDifficulty();

RoundPerformance _round({
  int pairs = 6,
  int? matched,
  int memoryErrors = 0,
  int hints = 0,
  int secondsRemaining = 50,
  int timeLimit = 100,
  bool won = true,
}) => RoundPerformance(
  pairCount: pairs,
  matchedPairs: matched ?? (won ? pairs : pairs ~/ 2),
  memoryErrors: memoryErrors,
  hintsUsed: hints,
  secondsRemaining: won ? secondsRemaining : 0,
  timeLimitSeconds: timeLimit,
  won: won,
);

/// A perfect round sized to the current board.
RoundPerformance _perfect(SkillState s) => _round(pairs: s.pairCount);

/// A round won with plenty of memory errors and little time left.
RoundPerformance _struggle(SkillState s) =>
    _round(pairs: s.pairCount, memoryErrors: s.pairCount, secondsRemaining: 5);

SkillState _play(
  GameCategory category,
  SkillState start,
  RoundPerformance Function(SkillState) round,
  int times,
) {
  var state = start;
  for (var i = 0; i < times; i++) {
    state = _engine.update(category, state, round(state));
  }
  return state;
}

void main() {
  const classic = GameCategories.classic;

  group('puntuación de una ronda', () {
    test('una ronda perfecta y holgada puntúa el máximo', () {
      expect(_engine.performanceScore(_round()), 1.0);
    });

    test('perder siempre queda por debajo de una victoria regular', () {
      final loss = _engine.performanceScore(_round(won: false, matched: 5));
      final messyWin = _engine.performanceScore(
        _round(memoryErrors: 6, secondsRemaining: 5),
      );
      expect(loss, lessThan(messyWin));
    });

    test('las pistas restan', () {
      expect(
        _engine.performanceScore(_round(hints: 2)),
        lessThan(_engine.performanceScore(_round())),
      );
    });
  });

  group('evolución de la habilidad', () {
    test('bajar es más rápido que subir', () {
      final start = SkillState(skill: 0.5, pairCount: 6);
      final up = _engine.update(classic, start, _perfect(start)).skill - 0.5;
      final down = 0.5 - _engine.update(classic, start, _struggle(start)).skill;
      expect(down, greaterThan(up * 2));
    });

    test('una sola ronda brillante no dispara la dificultad', () {
      final start = _engine.initialState(classic);
      final after = _engine.update(classic, start, _perfect(start));
      expect(after.skill - start.skill, lessThanOrEqualTo(0.06 + 1e-9));
      expect(after.pairCount - start.pairCount, lessThanOrEqualTo(1));
    });

    test('el tablero cambia como mucho un par por ronda', () {
      var state = _engine.initialState(classic);
      for (var i = 0; i < 40; i++) {
        final next = _engine.update(
          classic,
          state,
          i.isEven ? _perfect(state) : _struggle(state),
        );
        expect((next.pairCount - state.pairCount).abs(), lessThanOrEqualTo(1));
        state = next;
      }
    });

    test('jugar bien de forma sostenida llega al tablero más grande', () {
      final state = _play(
        classic,
        _engine.initialState(classic),
        _perfect,
        40,
      );
      expect(state.pairCount, classic.maxPairs);
      expect(_engine.settingsFor(classic, state).tier, ContentTier.challenging);
    });

    test('dos derrotas seguidas siempre encogen el tablero', () {
      final start = SkillState(skill: 0.9, pairCount: 9);
      final one = _engine.update(classic, start, _round(pairs: 9, won: false));
      final two = _engine.update(classic, one, _round(pairs: 9, won: false));
      expect(two.pairCount, lessThan(start.pairCount));
    });

    test('nunca sale de los límites de la categoría', () {
      for (final category in GameCategories.all) {
        final floor = _play(
          category,
          _engine.initialState(category),
          (s) => _round(pairs: s.pairCount, won: false),
          30,
        );
        expect(floor.pairCount, category.minPairs);
        expect(floor.skill, greaterThanOrEqualTo(0));

        final ceiling = _play(category, floor, _perfect, 80);
        expect(ceiling.pairCount, category.maxPairs);
        expect(ceiling.skill, lessThanOrEqualTo(1));
      }
    });

    test('una ronda en la zona cómoda no mueve el tablero', () {
      // Unos pocos errores y un final sin apuros: ni subir ni bajar.
      // A 0.5 el tablero ideal del clásico es de 6,5 pares.
      final start = SkillState(skill: 0.5, pairCount: 6);
      final after = _engine.update(
        classic,
        start,
        _round(pairs: 6, memoryErrors: 3, secondsRemaining: 30),
      );
      expect(after.pairCount, 6);
      expect((after.skill - 0.5).abs(), lessThan(0.02));
    });
  });

  group('ajustes derivados', () {
    test('más habilidad, menos vista previa y menos tiempo por par', () {
      final low = _engine.settingsFor(
        classic,
        const SkillState(skill: 0.1, pairCount: 8),
      );
      final high = _engine.settingsFor(
        classic,
        const SkillState(skill: 0.9, pairCount: 8),
      );
      expect(high.previewSeconds, lessThan(low.previewSeconds));
      expect(high.timeLimitSeconds, lessThan(low.timeLimitSeconds));
      expect(high.mismatchRevealMs, lessThan(low.mismatchRevealMs));
    });

    test('las categorías de lectura dan más tiempo que las de imágenes', () {
      const state = SkillState(skill: 0.5, pairCount: 6);
      final pictures = _engine.settingsFor(classic, state);
      final sums = _engine.settingsFor(GameCategories.numeric, state);
      expect(sums.previewSeconds, greaterThan(pictures.previewSeconds));
      expect(sums.timeLimitSeconds, greaterThan(pictures.timeLimitSeconds));
    });

    test('los mínimos protegen al jugador más rápido', () {
      for (final category in GameCategories.all) {
        final s = _engine.settingsFor(
          category,
          SkillState(skill: 1, pairCount: category.minPairs),
        );
        expect(s.previewSeconds, greaterThanOrEqualTo(2));
        expect(s.timeLimitSeconds, greaterThanOrEqualTo(45));
        expect(s.mismatchRevealMs, greaterThanOrEqualTo(600));
      }
    });

    test('los fallos seguidos alargan la revelación, con tope', () {
      const s = SkillState(skill: 0.5, pairCount: 6);
      final settings = _engine.settingsFor(classic, s);
      final base = settings.mismatchRevealFor(0);
      expect(settings.mismatchRevealFor(2), base);
      expect(settings.mismatchRevealFor(3), greaterThan(base));
      expect(
        settings.mismatchRevealFor(50),
        base + const Duration(milliseconds: 900),
      );
    });
  });
}
