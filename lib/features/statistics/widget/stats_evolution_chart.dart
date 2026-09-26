import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:intl/intl.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/widgets/app_card.dart';
import 'package:memory_companion/features/statistics/model/stats_bucket.dart';
import 'package:memory_companion/features/statistics/widget/stats_format.dart';

enum EvolutionMetric { accuracy, speed, errors }

/// Weekly evolution of one metric, as a single line over the last weeks.
///
/// One series, one hue, one axis. The selected week — the latest one with
/// games, until the player taps another — is the only labelled point, and
/// its value is written out above the plot. Weeks without games leave a gap
/// in the line rather than a misleading zero.
class StatsEvolutionChart extends StatefulWidget {
  const StatsEvolutionChart({super.key, required this.weeks});

  /// Oldest first.
  final List<WeeklyStats> weeks;

  @override
  State<StatsEvolutionChart> createState() => _StatsEvolutionChartState();
}

class _StatsEvolutionChartState extends State<StatsEvolutionChart> {
  EvolutionMetric _metric = EvolutionMetric.accuracy;
  int? _selected;

  static double? _valueOf(StatsBucket stats, EvolutionMetric metric) {
    return switch (metric) {
      EvolutionMetric.accuracy => stats.accuracy,
      EvolutionMetric.speed => stats.secondsPerPair,
      EvolutionMetric.errors => stats.errorsPerPair,
    };
  }

  String _format(BuildContext context, double value) {
    return switch (_metric) {
      EvolutionMetric.accuracy => formatPercent(value),
      EvolutionMetric.speed =>
        '${value.toStringAsFixed(1)} '
            '${AppLocale.statsSecondsPerPairUnit.getString(context)}',
      EvolutionMetric.errors =>
        '${value.toStringAsFixed(2)} '
            '${AppLocale.statsErrorsPerPairUnit.getString(context)}',
    };
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).languageCode;
    final dateLabel = DateFormat.MMMd(locale);
    final values = [
      for (final week in widget.weeks) _valueOf(week.stats, _metric),
    ];
    final lastWithData = values.lastIndexWhere((v) => v != null);
    final selected = _selected != null && values[_selected!] != null
        ? _selected!
        : (lastWithData == -1 ? null : lastWithData);

    final summary = [
      for (var i = 0; i < values.length; i++)
        '${dateLabel.format(widget.weeks[i].start)}: '
            '${values[i] == null ? AppLocale.statsNoGamesThatWeek.getString(context) : _format(context, values[i]!)}',
    ].join('; ');

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocale.statsEvolutionTitle.getString(context),
            style: textTheme.titleMedium,
          ),
          Text(
            AppLocale.statsEvolutionSubtitle.getString(context),
            style: textTheme.bodySmall?.copyWith(color: AppColors.outline),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<EvolutionMetric>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: EvolutionMetric.accuracy,
                  label: Text(AppLocale.statsAccuracyLabel.getString(context)),
                ),
                ButtonSegment(
                  value: EvolutionMetric.speed,
                  label: Text(AppLocale.statsSpeedLabel.getString(context)),
                ),
                ButtonSegment(
                  value: EvolutionMetric.errors,
                  label: Text(
                    AppLocale.statsErrorsShortLabel.getString(context),
                  ),
                ),
              ],
              selected: {_metric},
              onSelectionChanged: (s) => setState(() => _metric = s.first),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // The readout doubles as the tooltip: always visible, so nothing
          // depends on hovering, which a touch screen does not have.
          Text(
            selected == null
                ? AppLocale.statsNoGamesThatWeek.getString(context)
                : _format(context, values[selected]!),
            style: textTheme.headlineSmall?.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            [
              if (selected != null)
                dateLabel.format(widget.weeks[selected].start),
              if (_metric != EvolutionMetric.accuracy)
                AppLocale.statsLowerIsBetter.getString(context),
            ].join(' · '),
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            label: summary,
            excludeSemantics: true,
            child: LayoutBuilder(
              builder: (context, constraints) {
                void select(Offset position) {
                  final step = constraints.maxWidth / values.length;
                  final index = (position.dx / step).floor().clamp(
                    0,
                    values.length - 1,
                  );
                  if (values[index] != null && index != _selected) {
                    setState(() => _selected = index);
                  }
                }

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) => select(d.localPosition),
                  onHorizontalDragUpdate: (d) => select(d.localPosition),
                  child: SizedBox(
                    height: 160,
                    width: constraints.maxWidth,
                    child: CustomPaint(
                      painter: _LinePainter(
                        values: values,
                        selected: selected,
                        fixedMax: _metric == EvolutionMetric.accuracy
                            ? 1.0
                            : null,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ExcludeSemantics(
            child: Row(
              children: [
                for (var i = 0; i < widget.weeks.length; i++)
                  Expanded(
                    // Every other week, ending on the current one: eight
                    // dates do not fit a phone at a large text size.
                    child: (widget.weeks.length - 1 - i).isEven
                        ? Text(
                            dateLabel.format(widget.weeks[i].start),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.visible,
                            softWrap: false,
                            style: textTheme.labelSmall?.copyWith(
                              color: i == selected
                                  ? AppColors.onSurface
                                  : AppColors.outline,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({required this.values, required this.selected, this.fixedMax});

  final List<double?> values;
  final int? selected;

  /// Top of the scale; derived from the data when null.
  final double? fixedMax;

  static const _topPadding = 12.0;
  static const _bottomPadding = 8.0;

  @override
  void paint(Canvas canvas, Size size) {
    final present = values.whereType<double>();
    final dataMax = present.isEmpty ? 1.0 : present.reduce(math.max);
    final maxValue = fixedMax ?? (dataMax <= 0 ? 1.0 : dataMax * 1.15);

    final step = size.width / values.length;
    final plotHeight = size.height - _topPadding - _bottomPadding;
    double x(int i) => step * i + step / 2;
    double y(double v) =>
        _topPadding + plotHeight * (1 - (v / maxValue).clamp(0.0, 1.0));

    // Recessive grid: baseline, middle and top.
    final grid = Paint()
      ..color = AppColors.outlineVariant
      ..strokeWidth = 1;
    for (final fraction in const [0.0, 0.5, 1.0]) {
      final gy = _topPadding + plotHeight * fraction;
      canvas.drawLine(Offset(0, gy), Offset(size.width, gy), grid);
    }

    // The line, broken wherever a week has no games.
    final line = Paint()
      ..color = AppColors.skyStrong
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    Path? path;
    for (var i = 0; i < values.length; i++) {
      final v = values[i];
      if (v == null) {
        if (path != null) canvas.drawPath(path, line);
        path = null;
        continue;
      }
      path == null
          ? path = (Path()..moveTo(x(i), y(v)))
          : path.lineTo(x(i), y(v));
    }
    if (path != null) canvas.drawPath(path, line);

    if (selected != null && values[selected!] != null) {
      final sx = x(selected!);
      canvas.drawLine(
        Offset(sx, _topPadding),
        Offset(sx, size.height - _bottomPadding),
        Paint()
          ..color = AppColors.outline.withValues(alpha: 0.5)
          ..strokeWidth = 1,
      );
    }

    // Markers: 8 px, ringed in the surface colour so they sit cleanly on
    // top of the line; the selected one is larger.
    final ring = Paint()..color = AppColors.surfaceContainerLowest;
    final dot = Paint()..color = AppColors.skyStrong;
    for (var i = 0; i < values.length; i++) {
      final v = values[i];
      if (v == null) continue;
      final center = Offset(x(i), y(v));
      final radius = i == selected ? 6.0 : 4.0;
      canvas
        ..drawCircle(center, radius + 2, ring)
        ..drawCircle(center, radius, dot);
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) {
    return old.selected != selected ||
        old.fixedMax != fixedMax ||
        !_sameValues(old.values, values);
  }

  static bool _sameValues(List<double?> a, List<double?> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
