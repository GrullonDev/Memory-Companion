import 'package:memory_companion/features/game/board/category/game_category.dart';
import 'package:memory_companion/features/game/board/model/card_face.dart';
import 'package:memory_companion/features/game/board/model/card_pair.dart';

/// The logical link between the two cards of an [Association].
enum AssociationKind {
  /// A picture and the group it belongs to: 🍎 → Fruit.
  category,

  /// Something and what it produces: Fire → Smoke.
  causeEffect,

  /// Two words that mean the same: Fast → Quick.
  synonym,
}

/// One curated pair, written in every app language.
class Association {
  const Association({
    required this.id,
    required this.kind,
    required this.tier,
    required this.faces,
  });

  final String id;
  final AssociationKind kind;
  final ContentTier tier;

  /// Language code → (first card, second card).
  final Map<String, (String, String)> faces;
}

/// Match two cards that are related in meaning, not in looks.
///
/// Gentle boards pair a picture with its group, so a child who cannot read
/// yet can still play by recognising 🐶. Harder boards bring in cause and
/// effect, then synonyms, which lean on vocabulary.
class AssociationCategory extends GameCategory {
  const AssociationCategory({this.deck = associationDeck});

  final List<Association> deck;

  @override
  String get id => 'association';

  @override
  String get nameKey => 'categoryAssociationName';

  @override
  String get descriptionKey => 'categoryAssociationDescription';

  @override
  int get minPairs => 3;

  /// Word cards need room for the text; beyond 16 cards they get too small
  /// to read comfortably.
  @override
  int get maxPairs => 8;

  @override
  double get readingLoad => 1.5;

  @override
  List<CardPair> buildPairs(DeckRequest request) {
    // The player's own tier first, then easier entries to fill the board,
    // so a board is mostly at their level with a few confidence builders.
    final atTier = deck.where((a) => a.tier == request.tier).toList()
      ..shuffle(request.random);
    final below = deck.where((a) => a.tier.index < request.tier.index).toList()
      ..shuffle(request.random);

    return [
      for (final association in [...atTier, ...below].take(request.pairCount))
        _toPair(association, request.languageCode),
    ];
  }

  static CardPair _toPair(Association association, String languageCode) {
    final (first, second) =
        association.faces[languageCode] ?? association.faces['es']!;
    return CardPair(
      pairId: association.id,
      first: TextFace(first),
      second: TextFace(second),
    );
  }
}

/// Every word appears once in the whole deck, per language, and no card
/// plausibly matches a card from another entry: one fruit, one animal, one
/// vehicle… A test enforces the first rule; the second needs a human eye
/// whenever an entry is added.
const associationDeck = <Association>[
  // --- Gentle: picture → group, and concrete cause → effect -------------
  Association(
    id: 'apple-fruit',
    kind: AssociationKind.category,
    tier: ContentTier.gentle,
    faces: {'es': ('🍎', 'Fruta'), 'en': ('🍎', 'Fruit')},
  ),
  Association(
    id: 'dog-animal',
    kind: AssociationKind.category,
    tier: ContentTier.gentle,
    faces: {'es': ('🐶', 'Animal'), 'en': ('🐶', 'Animal')},
  ),
  Association(
    id: 'car-vehicle',
    kind: AssociationKind.category,
    tier: ContentTier.gentle,
    faces: {'es': ('🚗', 'Vehículo'), 'en': ('🚗', 'Vehicle')},
  ),
  Association(
    id: 'shirt-clothing',
    kind: AssociationKind.category,
    tier: ContentTier.gentle,
    faces: {'es': ('👕', 'Ropa'), 'en': ('👕', 'Clothing')},
  ),
  Association(
    id: 'guitar-instrument',
    kind: AssociationKind.category,
    tier: ContentTier.gentle,
    faces: {'es': ('🎸', 'Instrumento'), 'en': ('🎸', 'Instrument')},
  ),
  Association(
    id: 'hammer-tool',
    kind: AssociationKind.category,
    tier: ContentTier.gentle,
    faces: {'es': ('🔨', 'Herramienta'), 'en': ('🔨', 'Tool')},
  ),
  Association(
    id: 'fire-smoke',
    kind: AssociationKind.causeEffect,
    tier: ContentTier.gentle,
    faces: {'es': ('🔥 Fuego', 'Humo'), 'en': ('🔥 Fire', 'Smoke')},
  ),
  Association(
    id: 'rain-puddle',
    kind: AssociationKind.causeEffect,
    tier: ContentTier.gentle,
    faces: {'es': ('🌧 Lluvia', 'Charco'), 'en': ('🌧 Rain', 'Puddle')},
  ),
  Association(
    id: 'seed-tree',
    kind: AssociationKind.causeEffect,
    tier: ContentTier.gentle,
    faces: {'es': ('🌱 Semilla', 'Árbol'), 'en': ('🌱 Seed', 'Tree')},
  ),

  // --- Standard: everyday cause → effect and first synonyms -------------
  Association(
    id: 'carrot-vegetable',
    kind: AssociationKind.category,
    tier: ContentTier.standard,
    faces: {'es': ('🥕', 'Verdura'), 'en': ('🥕', 'Vegetable')},
  ),
  Association(
    id: 'ball-sport',
    kind: AssociationKind.category,
    tier: ContentTier.standard,
    faces: {'es': ('⚽', 'Deporte'), 'en': ('⚽', 'Sport')},
  ),
  Association(
    id: 'hunger-eat',
    kind: AssociationKind.causeEffect,
    tier: ContentTier.standard,
    faces: {'es': ('Hambre', 'Comer'), 'en': ('Hunger', 'Eat')},
  ),
  Association(
    id: 'thirst-drink',
    kind: AssociationKind.causeEffect,
    tier: ContentTier.standard,
    faces: {'es': ('Sed', 'Beber'), 'en': ('Thirst', 'Drink')},
  ),
  Association(
    id: 'happy-glad',
    kind: AssociationKind.synonym,
    tier: ContentTier.standard,
    faces: {'es': ('Feliz', 'Contento'), 'en': ('Happy', 'Glad')},
  ),
  Association(
    id: 'fast-quick',
    kind: AssociationKind.synonym,
    tier: ContentTier.standard,
    faces: {'es': ('Rápido', 'Veloz'), 'en': ('Fast', 'Quick')},
  ),
  Association(
    id: 'begin-start',
    kind: AssociationKind.synonym,
    tier: ContentTier.standard,
    faces: {'es': ('Empezar', 'Comenzar'), 'en': ('Begin', 'Start')},
  ),
  Association(
    id: 'pretty-beautiful',
    kind: AssociationKind.synonym,
    tier: ContentTier.standard,
    faces: {'es': ('Bonito', 'Hermoso'), 'en': ('Pretty', 'Beautiful')},
  ),

  // --- Challenging: abstract synonyms and less obvious causes -----------
  Association(
    id: 'exercise-sweat',
    kind: AssociationKind.causeEffect,
    tier: ContentTier.challenging,
    faces: {'es': ('Ejercicio', 'Sudor'), 'en': ('Exercise', 'Sweat')},
  ),
  Association(
    id: 'study-learning',
    kind: AssociationKind.causeEffect,
    tier: ContentTier.challenging,
    faces: {'es': ('Estudio', 'Aprendizaje'), 'en': ('Study', 'Learning')},
  ),
  Association(
    id: 'cold-shiver',
    kind: AssociationKind.causeEffect,
    tier: ContentTier.challenging,
    faces: {'es': ('Frío', 'Escalofrío'), 'en': ('Cold', 'Shiver')},
  ),
  Association(
    id: 'ancient-old',
    kind: AssociationKind.synonym,
    tier: ContentTier.challenging,
    faces: {'es': ('Antiguo', 'Viejo'), 'en': ('Ancient', 'Old')},
  ),
  Association(
    id: 'brave-bold',
    kind: AssociationKind.synonym,
    tier: ContentTier.challenging,
    faces: {'es': ('Valiente', 'Audaz'), 'en': ('Brave', 'Bold')},
  ),
  Association(
    id: 'calm-serene',
    kind: AssociationKind.synonym,
    tier: ContentTier.challenging,
    faces: {'es': ('Tranquilo', 'Sereno'), 'en': ('Calm', 'Serene')},
  ),
  Association(
    id: 'wise-sensible',
    kind: AssociationKind.synonym,
    tier: ContentTier.challenging,
    faces: {'es': ('Sabio', 'Sensato'), 'en': ('Wise', 'Sensible')},
  ),
];
