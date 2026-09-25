import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/widgets/app_card.dart';
import 'package:memory_companion/features/game_context/controller/game_context_providers.dart';
import 'package:memory_companion/features/game_context/model/place.dart';
import 'package:memory_companion/features/history_search/controller/history_search_controller.dart';
import 'package:memory_companion/features/history_search/model/search_answer.dart';
import 'package:memory_companion/features/history_search/model/search_query.dart';
import 'package:memory_companion/features/statistics/model/category_title.dart';
import 'package:memory_companion/features/statistics/model/game_stats.dart';
import 'package:memory_companion/features/statistics/widget/game_history_tile.dart';
import 'package:memory_companion/features/statistics/widget/stats_format.dart';

/// The label a place is shown under: its name, or "Lugar N" by age.
String placeLabel(BuildContext context, List<Place> places, int? id) {
  if (id == null) return '';
  final index = places.indexWhere((p) => p.id == id);
  if (index < 0) return '';
  final place = places[index];
  if (place.isNamed) return place.name!;
  return fill(AppLocale.placeUnnamed.getString(context), index + 1);
}

/// Questions about the history in plain language, answered on the device.
class HistorySearchScreen extends ConsumerStatefulWidget {
  const HistorySearchScreen({super.key});

  @override
  ConsumerState<HistorySearchScreen> createState() =>
      _HistorySearchScreenState();
}

class _HistorySearchScreenState extends ConsumerState<HistorySearchScreen> {
  final _question = TextEditingController();

  static const _examples = [
    AppLocale.searchExampleBestFriday,
    AppLocale.searchExampleImproved,
    AppLocale.searchExampleWhoPark,
    AppLocale.searchExampleWhere,
    AppLocale.searchExampleWhen,
  ];

  @override
  void dispose() {
    _question.dispose();
    super.dispose();
  }

  void _ask(String question) {
    FocusScope.of(context).unfocus();
    ref.read(historySearchControllerProvider.notifier).ask(question);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historySearchControllerProvider);
    final places = ref.watch(placesProvider).value ?? const <Place>[];
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(AppLocale.searchTitle.getString(context))),
      body: SafeArea(
        top: false,
        // The question stays pinned: a long answer scrolls under it, so a
        // follow-up question is always one tap away.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenMargin,
                AppSpacing.sm,
                AppSpacing.screenMargin,
                AppSpacing.md,
              ),
              child: TextField(
                controller: _question,
                autofocus: state.question == null,
                textInputAction: TextInputAction.search,
                onSubmitted: _ask,
                decoration: InputDecoration(
                  hintText: AppLocale.searchHint.getString(context),
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    tooltip: AppLocale.searchTitle.getString(context),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    onPressed: () => _ask(_question.text),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.lg),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenMargin,
                  0,
                  AppSpacing.screenMargin,
                  AppSpacing.xxl,
                ),
                // Scrolling the results puts the keyboard away.
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final example in _examples)
                        ActionChip(
                          label: Text(example.getString(context)),
                          onPressed: () {
                            _question.text = example.getString(context);
                            _ask(_question.text);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (state.answer case final answer?)
                    answer.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, _) => AppCard(
                        child: Text(AppLocale.searchFailed.getString(context)),
                      ),
                      data: (answer) =>
                          _AnswerView(answer: answer, places: places),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lock_outline_rounded,
                        size: AppSize.iconXs,
                        color: AppColors.outline,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          AppLocale.searchPrivacyNote.getString(context),
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.outline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnswerView extends StatelessWidget {
  const _AnswerView({required this.answer, required this.places});

  final SearchAnswer answer;
  final List<Place> places;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    String t(String key) => key.getString(context);
    String place(int? id) => placeLabel(context, places, id);
    String category(String id) => t(categoryTitleKey(id));
    String accuracyGames(Tally<Object?> tally) =>
        t(AppLocale.searchAccuracyGames)
            .replaceAll('{accuracy}', formatPercent(tally.accuracy))
            .replaceAll('{n}', '${tally.games}');

    Widget title(String text) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(text, style: textTheme.titleMedium),
    );
    Widget line(String text) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(
        text,
        style: textTheme.bodyMedium?.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
    Widget tile(GameStats game) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GameHistoryTile(
        game: game,
        placeLabel: game.placeId == null ? null : place(game.placeId),
      ),
    );

    final body = <Widget>[
      ...switch (answer) {
        GameAnswer(:final game, :final best) => [
          title(
            t(
              best
                  ? AppLocale.searchBestGameTitle
                  : AppLocale.searchWorstGameTitle,
            ),
          ),
          tile(game),
        ],
        final ImprovementAnswer a => [
          title(
            t(
              a.delta > 0
                  ? AppLocale.searchImprovedTitle
                  : AppLocale.searchNotImprovedTitle,
            ).replaceAll('{category}', category(a.categoryId)),
          ),
          line(
            t(AppLocale.searchImprovedDetail)
                .replaceAll('{before}', formatPercent(a.before.accuracy))
                .replaceAll('{after}', formatPercent(a.after.accuracy)),
          ),
        ],
        final PeopleAnswer a =>
          a.people.isEmpty
              ? [line(t(AppLocale.searchNobodyNearby))]
              : [
                  title(t(AppLocale.searchPeopleTitle)),
                  for (final person in a.people)
                    line(
                      '${a.names[person.key] ?? t(AppLocale.searchUnknownPlayer).replaceAll('{code}', person.key)}'
                      ' — ${fill(t(AppLocale.searchGamesCount), person.games)}',
                    ),
                ],
        final PlaceAnswer a => [
          title(
            t(
              AppLocale.searchPlaceTitle,
            ).replaceAll('{place}', place(a.places.first.key)),
          ),
          for (final tally in a.places)
            line('${place(tally.key)}: ${accuracyGames(tally)}'),
        ],
        final TimeAnswer a => [
          title(
            t(
              AppLocale.searchTimeTitle,
            ).replaceAll('{slot}', t(_slotKey(a.slots.first.key))),
          ),
          for (final tally in a.slots)
            line('${t(_slotKey(tally.key))}: ${accuracyGames(tally)}'),
        ],
        final CountAnswer a => [
          title(
            t(AppLocale.searchCountTitle)
                .replaceAll('{n}', '${a.gamesConsidered}')
                .replaceAll('{wins}', '${a.wins}'),
          ),
        ],
        GamesAnswer(:final games) => [
          title(t(AppLocale.searchGamesTitle)),
          for (final game in games) tile(game),
        ],
        MissingAnswer(:final missing) => [
          line(
            t(switch (missing) {
              MissingData.noGames => AppLocale.searchNoGames,
              MissingData.noNearby => AppLocale.searchNoNearby,
              MissingData.noPlaces => AppLocale.searchNoPlaces,
              MissingData.noComparison => AppLocale.searchNoComparison,
            }),
          ),
        ],
      },
    ];

    final understood = _understood(context, answer, place, category);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...body,
          if (answer.unmatchedPlace case final missingPlace?)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                t(
                  AppLocale.searchUnmatchedPlace,
                ).replaceAll('{place}', missingPlace),
                style: textTheme.bodySmall?.copyWith(color: AppColors.outline),
              ),
            ),
          if (understood.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                t(
                  AppLocale.searchUnderstood,
                ).replaceAll('{filters}', understood.join(' · ')),
                style: textTheme.bodySmall?.copyWith(color: AppColors.outline),
              ),
            ),
        ],
      ),
    );
  }

  /// What the question was read as, so a misread shows.
  static List<String> _understood(
    BuildContext context,
    SearchAnswer answer,
    String Function(int?) place,
    String Function(String) category,
  ) {
    final locale = Localizations.localeOf(context).languageCode;
    final query = answer.query;
    return [
      if (query.range case final DateRange range) _formatRange(range, locale),
      if (query.weekday case final int weekday)
        AppLocale.searchEveryWeekday
            .getString(context)
            .replaceAll(
              '{day}',
              // 2024-01-01 was a Monday.
              DateFormat.EEEE(locale).format(DateTime(2024, 1, weekday)),
            ),
      if (answer.placeFilter case final int id) place(id),
      if (answer.categoryFilter case final String id) category(id),
    ];
  }

  static String _formatRange(DateRange range, String locale) {
    final last = range.end.subtract(const Duration(days: 1));
    final format = DateFormat.MMMd(locale);
    if (last.year == range.start.year &&
        last.month == range.start.month &&
        last.day == range.start.day) {
      return DateFormat.MMMEd(locale).format(range.start);
    }
    return '${format.format(range.start)} – ${format.format(last)}';
  }

  static String _slotKey(DaySlot slot) => switch (slot) {
    DaySlot.morning => AppLocale.slotMorning,
    DaySlot.afternoon => AppLocale.slotAfternoon,
    DaySlot.evening => AppLocale.slotEvening,
    DaySlot.night => AppLocale.slotNight,
  };
}
