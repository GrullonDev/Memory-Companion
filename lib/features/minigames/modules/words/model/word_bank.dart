/// Words the recognition game deals from, per app language.
///
/// Concrete, everyday nouns of similar length and familiarity, so no word
/// stands out on its own and the game measures memory, not vocabulary.
/// Each list needs at least `2 × wordsMaxListSize` entries: the studied
/// words plus as many distractors.
abstract final class WordBank {
  static const Map<String, List<String>> _byLanguage = {
    'es': [
      'mesa', 'silla', 'puerta', 'ventana', 'libro', 'lápiz', 'reloj',
      'llave', 'vaso', 'plato', 'cuchara', 'botella', 'zapato', 'camisa',
      'sombrero', 'paraguas', 'espejo', 'cama', 'almohada', 'lámpara',
      'manzana', 'naranja', 'pan', 'queso', 'leche', 'huevo', 'arroz',
      'perro', 'gato', 'caballo', 'pájaro', 'pez', 'vaca', 'conejo',
      'árbol', 'flor', 'río', 'montaña', 'playa', 'nube', 'luna',
      'estrella', 'coche', 'barco', 'tren', 'avión', 'bicicleta',
      'guitarra', 'tambor', 'pelota',
    ],
    'en': [
      'table', 'chair', 'door', 'window', 'book', 'pencil', 'clock', 'key',
      'glass', 'plate', 'spoon', 'bottle', 'shoe', 'shirt', 'hat',
      'umbrella', 'mirror', 'bed', 'pillow', 'lamp', 'apple', 'orange',
      'bread', 'cheese', 'milk', 'egg', 'rice', 'dog', 'cat', 'horse',
      'bird', 'fish', 'cow', 'rabbit', 'tree', 'flower', 'river',
      'mountain', 'beach', 'cloud', 'moon', 'star', 'car', 'boat', 'train',
      'plane', 'bicycle', 'guitar', 'drum', 'ball',
    ],
  };

  /// The list for [languageCode]; Spanish for a language without its own.
  static List<String> forLanguage(String languageCode) =>
      _byLanguage[languageCode] ?? _byLanguage['es']!;

  static Iterable<String> get languages => _byLanguage.keys;
}
