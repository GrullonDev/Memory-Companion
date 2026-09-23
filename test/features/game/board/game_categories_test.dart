import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/features/game/board/category/association_category.dart';
import 'package:memory_companion/features/game/board/category/board_factory.dart';
import 'package:memory_companion/features/game/board/category/game_categories.dart';
import 'package:memory_companion/features/game/board/category/game_category.dart';
import 'package:memory_companion/features/game/board/difficulty/difficulty_settings.dart';
import 'package:memory_companion/features/game/board/model/card_face.dart';

DeckRequest _request(int pairs, ContentTier tier, {int seed = 1}) =>
    DeckRequest(
      pairCount: pairs,
      tier: tier,
      languageCode: 'es',
      random: Random(seed),
    );

/// Evaluates "a + b", "a − b" and "a × b" as dealt by the numeric category.
int _evaluate(String expression) {
  final [a, op, b] = expression.split(' ');
  final (x, y) = (int.parse(a), int.parse(b));
  return switch (op) {
    '+' => x + y,
    '−' => x - y,
    '×' => x * y,
    _ => throw ArgumentError(expression),
  };
}

void main() {
  group('todas las categorías', () {
    for (final category in GameCategories.all) {
      test('${category.id}: da exactamente los pares pedidos, sin repetir id '
          'en todo el rango y en todos los niveles', () {
        for (final tier in ContentTier.values) {
          for (var n = category.minPairs; n <= category.maxPairs; n++) {
            for (var seed = 0; seed < 20; seed++) {
              final pairs = category.buildPairs(_request(n, tier, seed: seed));
              expect(pairs, hasLength(n), reason: '$tier, $n pares');
              expect(pairs.map((p) => p.pairId).toSet(), hasLength(n));
            }
          }
        }
      });

      test('${category.id}: ninguna cara se repite entre pares distintos', () {
        // Si dos pares compartieran una cara, acertar se contaría como error.
        for (final tier in ContentTier.values) {
          for (var seed = 0; seed < 20; seed++) {
            final pairs = category.buildPairs(
              _request(category.maxPairs, tier, seed: seed),
            );
            final seen = <CardFace, String>{};
            for (final pair in pairs) {
              for (final face in {pair.first, pair.second}) {
                expect(
                  seen.putIfAbsent(face, () => pair.pairId),
                  pair.pairId,
                  reason: '$face aparece en dos pares',
                );
              }
            }
          }
        }
      });
    }

    test('un id desconocido cae en el modo clásico', () {
      expect(GameCategories.byId('borrado'), same(GameCategories.classic));
      expect(GameCategories.byId(null), same(GameCategories.classic));
      expect(GameCategories.byId('numeric'), same(GameCategories.numeric));
    });
  });

  group('números', () {
    test('cada operación da el resultado de su pareja', () {
      for (final tier in ContentTier.values) {
        for (var seed = 0; seed < 50; seed++) {
          for (final pair in GameCategories.numeric.buildPairs(
            _request(8, tier, seed: seed),
          )) {
            final expression = (pair.first as TextFace).text;
            final result = int.parse((pair.second as TextFace).text);
            expect(_evaluate(expression), result, reason: expression);
          }
        }
      }
    });

    test('el nivel suave solo suma, con operandos positivos', () {
      for (var seed = 0; seed < 50; seed++) {
        for (final pair in GameCategories.numeric.buildPairs(
          _request(8, ContentTier.gentle, seed: seed),
        )) {
          final [a, op, b] = (pair.first as TextFace).text.split(' ');
          expect(op, '+');
          expect(int.parse(a), greaterThan(0));
          expect(int.parse(b), greaterThan(0));
        }
      }
    });
  });

  group('asociación', () {
    test('cada entrada está en todos los idiomas y ninguna palabra se repite',
        () {
      for (final language in ['es', 'en']) {
        final words = <String>[];
        for (final entry in associationDeck) {
          final faces = entry.faces[language];
          expect(faces, isNotNull, reason: '${entry.id} sin "$language"');
          words
            ..add(faces!.$1)
            ..add(faces.$2);
        }
        expect(words.toSet(), hasLength(words.length), reason: language);
      }
      expect(associationDeck.map((e) => e.id).toSet(),
          hasLength(associationDeck.length));
    });

    test('las palabras siguen el idioma de la app', () {
      final request = DeckRequest(
        pairCount: 3,
        tier: ContentTier.gentle,
        languageCode: 'en',
        random: Random(1),
      );
      final english = {
        for (final e in associationDeck) e.faces['en']!.$2,
      };
      for (final pair in GameCategories.association.buildPairs(request)) {
        expect(english, contains((pair.second as TextFace).text));
      }
    });

    test('prefiere entradas del nivel del jugador', () {
      final pairs = GameCategories.association.buildPairs(
        _request(4, ContentTier.challenging),
      );
      final challenging = {
        for (final e in associationDeck)
          if (e.tier == ContentTier.challenging) e.id,
      };
      expect(pairs.every((p) => challenging.contains(p.pairId)), isTrue);
    });
  });

  test('la fábrica reparte cada par exactamente dos veces', () {
    const settings = DifficultySettings(
      pairCount: 6,
      previewSeconds: 3,
      timeLimitSeconds: 60,
      mismatchRevealMs: 800,
      tier: ContentTier.standard,
    );
    for (final category in GameCategories.all) {
      final cards = BoardFactory.deal(
        category: category,
        settings: settings,
        languageCode: 'es',
        random: Random(3),
      );
      expect(cards, hasLength(12));
      expect(cards.map((c) => c.id).toSet(), hasLength(12));
      final byPair = <String, int>{};
      for (final c in cards) {
        byPair[c.pairId] = (byPair[c.pairId] ?? 0) + 1;
      }
      expect(byPair.values, everyElement(2), reason: category.id);
      expect(cards.every((c) => !c.isFaceUp && !c.isMatched), isTrue);
    }
  });
}
