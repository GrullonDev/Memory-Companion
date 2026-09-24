import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/features/game_context/controller/game_context_providers.dart';
import 'package:memory_companion/features/history_search/model/search_answer.dart';
import 'package:memory_companion/features/history_search/service/history_search_engine.dart';
import 'package:memory_companion/features/history_search/service/text_embedder.dart';
import 'package:memory_companion/features/statistics/controller/statistics_controller.dart';
import 'package:memory_companion/features/statistics/model/category_title.dart';
import 'package:memory_companion/features/statistics/model/game_stats.dart';

/// The embedder the search runs on. Swapped here for an on-device model,
/// the rest of the search does not change.
final textEmbedderProvider = Provider<TextEmbedder>(
  (_) => const LexicalEmbedder(),
);

final historySearchEngineProvider = Provider<HistorySearchEngine>(
  (_) => const HistorySearchEngine(),
);

final allGamesProvider = StreamProvider.autoDispose<List<GameStats>>(
  (ref) => ref.watch(statsRepositoryProvider).watchAll(),
);

/// Every name a category has, in every language: a question in English
/// still finds a game the player saw in Spanish.
List<String> categoryNamesInAllLanguages(String categoryId) {
  final key = categoryTitleKey(categoryId);
  return {
    for (final language in [AppLocale.es, AppLocale.en])
      if (language[key] case final String name) name,
  }.toList();
}

/// The history, embedded. Rebuilt when a game is stored or a place is
/// renamed; kept while the search screen is open.
final historyIndexProvider = FutureProvider.autoDispose<HistoryIndex>((
  ref,
) async {
  final games = await ref.watch(allGamesProvider.future);
  final places = await ref.watch(placesProvider.future);
  return HistoryIndex(
    games: games,
    places: places,
    categoryNames: categoryNamesInAllLanguages,
    embedder: ref.watch(textEmbedderProvider),
  );
});

class HistorySearchState {
  const HistorySearchState({this.question, this.answer});

  final String? question;

  /// Null before the first question.
  final AsyncValue<SearchAnswer>? answer;
}

class HistorySearchController extends Notifier<HistorySearchState> {
  @override
  HistorySearchState build() {
    // Keeps the index alive for as long as the screen is, without wiping
    // the current answer each time a game is stored.
    ref.listen(historyIndexProvider, (_, _) {});
    return const HistorySearchState();
  }

  Future<void> ask(String question) async {
    final text = question.trim();
    if (text.isEmpty) return;
    state = HistorySearchState(question: text, answer: const AsyncLoading());
    final result = await AsyncValue.guard(() async {
      final index = await ref.read(historyIndexProvider.future);
      final now = ref.read(statsClockProvider)();
      return ref.read(historySearchEngineProvider).answer(text, index, now);
    });
    if (!ref.mounted || state.question != text) return;
    state = HistorySearchState(question: text, answer: result);
  }
}

final historySearchControllerProvider =
    NotifierProvider.autoDispose<HistorySearchController, HistorySearchState>(
      HistorySearchController.new,
    );
