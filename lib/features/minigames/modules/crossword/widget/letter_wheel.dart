import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/widgets/adaptive_button.dart';

/// Letters in a circle. Swiping across them spells a word, which is
/// entered on lifting the finger; a stroke drawn between the letters shows
/// the path.
///
/// Tapping works too, one letter at a time, with explicit Clear and Enter
/// buttons: for players who find a swipe hard and for screen readers,
/// which activate each letter as a button.
class LetterWheel extends StatefulWidget {
  const LetterWheel({super.key, required this.letters, required this.onWord});

  final List<String> letters;
  final ValueChanged<String> onWord;

  @override
  State<LetterWheel> createState() => _LetterWheelState();
}

class _LetterWheelState extends State<LetterWheel> {
  static const _maxWheelSize = 260.0;
  static const _letterSize = 64.0;

  /// Set from the layout on every build; the hit test reads it.
  double _wheelSize = _maxWheelSize;

  /// Indexes into [LetterWheel.letters], in the order picked.
  final _selected = <int>[];
  Offset? _finger;
  bool _dragging = false;

  /// Where the current touch went down, and the tap-spelt word it
  /// interrupted: a touch that never travels is a tap, not a swipe.
  Offset? _downAt;
  bool _travelled = false;
  List<int> _beforeTouch = const [];

  String get _word => _selected.map((i) => widget.letters[i]).join();

  @override
  void didUpdateWidget(LetterWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A shuffle moves every letter: a half-spelt word would point at the
    // wrong ones.
    if (!_sameLetters(oldWidget.letters, widget.letters)) _selected.clear();
  }

  static bool _sameLetters(List<String> a, List<String> b) =>
      a.length == b.length &&
      Iterable.generate(a.length).every((i) => a[i] == b[i]);

  List<Offset> _centers() {
    final center = Offset(_wheelSize / 2, _wheelSize / 2);
    final radius = (_wheelSize - _letterSize) / 2 - AppSpacing.sm;
    final count = widget.letters.length;
    return [
      for (var i = 0; i < count; i++)
        center + Offset.fromDirection(-pi / 2 + 2 * pi * i / count, radius),
    ];
  }

  int? _letterAt(Offset point) {
    final centers = _centers();
    for (var i = 0; i < centers.length; i++) {
      if ((centers[i] - point).distance <= _letterSize / 2 + AppSpacing.xs) {
        return i;
      }
    }
    return null;
  }

  void _onPanStart(DragStartDetails details) {
    _downAt = details.localPosition;
    _travelled = false;
    _beforeTouch = List.of(_selected);
    setState(() {
      _selected.clear();
      _dragging = true;
      _finger = details.localPosition;
      final hit = _letterAt(details.localPosition);
      if (hit != null) _selected.add(hit);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_travelled &&
        (details.localPosition - _downAt!).distance > kTouchSlop) {
      _travelled = true;
    }
    setState(() {
      _finger = details.localPosition;
      final hit = _letterAt(details.localPosition);
      if (hit == null) return;
      // Sliding back onto the previous letter undoes the last one.
      if (_selected.length > 1 && hit == _selected[_selected.length - 2]) {
        _selected.removeLast();
      } else if (!_selected.contains(hit)) {
        _selected.add(hit);
      }
    });
  }

  void _onPanEnd(DragEndDetails _) {
    // The wheel claims every touch on a letter (see [_LetterGrabRecognizer]),
    // taps included; one that never moved spells by tapping instead.
    if (!_travelled && _selected.length == 1) {
      final tapped = _selected.single;
      setState(() {
        _dragging = false;
        _finger = null;
        _selected
          ..clear()
          ..addAll(_beforeTouch);
      });
      _tap(tapped);
      return;
    }
    final word = _word;
    setState(() {
      _selected.clear();
      _dragging = false;
      _finger = null;
    });
    if (word.isNotEmpty) widget.onWord(word);
  }

  void _tap(int index) {
    setState(() {
      if (_selected.isNotEmpty && _selected.last == index) {
        _selected.removeLast();
      } else if (!_selected.contains(index)) {
        _selected.add(index);
      }
    });
  }

  void _clear() => setState(_selected.clear);

  void _enter() {
    final word = _word;
    _clear();
    widget.onWord(word);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _wheelSize = constraints.maxWidth < _maxWheelSize
            ? constraints.maxWidth
            : _maxWheelSize;
        return _buildWheel(context);
      },
    );
  }

  Widget _buildWheel(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final centers = _centers();
    final tapping = !_dragging && _selected.isNotEmpty;

    return Column(
      children: [
        // The word being spelt. Fixed height, so the wheel never jumps.
        SizedBox(
          height: 48,
          child: Center(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: _selected.isEmpty ? 0 : 1,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.streak,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  _word,
                  style: textTheme.titleLarge?.copyWith(
                    color: AppColors.onStreak,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        RawGestureDetector(
          gestures: {
            _LetterGrabRecognizer:
                GestureRecognizerFactoryWithHandlers<_LetterGrabRecognizer>(
                  () => _LetterGrabRecognizer(
                    grabs: (point) => _letterAt(point) != null,
                  ),
                  (recognizer) => recognizer
                    // Start where the finger lands, not where the drag is
                    // recognised a few pixels later — by then it may have
                    // left the first letter.
                    ..dragStartBehavior = DragStartBehavior.down
                    ..onStart = _onPanStart
                    ..onUpdate = _onPanUpdate
                    ..onEnd = _onPanEnd,
                ),
          },
          child: SizedBox.square(
            dimension: _wheelSize,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: AppColors.streakSoft,
                      shape: BoxShape.circle,
                    ),
                    child: CustomPaint(
                      painter: _PathPainter(
                        points: [
                          for (final i in _selected) centers[i],
                          if (_dragging && _finger != null) _finger!,
                        ],
                      ),
                    ),
                  ),
                ),
                for (var i = 0; i < widget.letters.length; i++)
                  Positioned(
                    left: centers[i].dx - _letterSize / 2,
                    top: centers[i].dy - _letterSize / 2,
                    child: _LetterTile(
                      letter: widget.letters[i],
                      selected: _selected.contains(i),
                      size: _letterSize,
                      onTap: () => _tap(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Only for words spelt by tapping; a swipe enters on release.
        Visibility(
          visible: tapping,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: Row(
            children: [
              Expanded(
                child: AdaptiveButton(
                  label: AppLocale.crosswordClearLabel.getString(context),
                  icon: Icons.backspace_outlined,
                  variant: AdaptiveButtonVariant.neutral,
                  onPressed: tapping ? _clear : null,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AdaptiveButton(
                  label: AppLocale.crosswordSubmitLabel.getString(context),
                  icon: Icons.keyboard_return_rounded,
                  onPressed: tapping ? _enter : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A pan that wins at once when the finger lands on a letter.
///
/// The wheel sits in a scrolling screen. A plain pan only wins after 36px
/// of travel, but the screen's vertical drag claims the gesture after 18px,
/// so a mostly vertical stroke scrolled the page instead of spelling. A
/// touch that starts on a letter is always meant for the wheel; one on the
/// wheel's background still scrolls the page.
class _LetterGrabRecognizer extends PanGestureRecognizer {
  _LetterGrabRecognizer({required this.grabs});

  final bool Function(Offset localPosition) grabs;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    if (grabs(event.localPosition)) {
      resolvePointer(event.pointer, GestureDisposition.accepted);
    }
  }
}

class _LetterTile extends StatelessWidget {
  const _LetterTile({
    required this.letter,
    required this.selected,
    required this.size,
    required this.onTap,
  });

  final String letter;
  final bool selected;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: letter,
      onTap: onTap,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.streak : AppColors.surfaceContainerLowest,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.streakDeep, width: 2),
        ),
        child: FittedBox(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Text(
              letter,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: selected ? AppColors.onStreak : AppColors.streakStrong,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The stroke through the picked letters, ending at the finger.
class _PathPainter extends CustomPainter {
  const _PathPainter({required this.points});

  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final paint = Paint()
      ..color = AppColors.streak
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(Path()..addPolygon(points, false), paint);
  }

  @override
  bool shouldRepaint(_PathPainter oldDelegate) =>
      oldDelegate.points.length != points.length ||
      Iterable.generate(
        points.length,
      ).any((i) => oldDelegate.points[i] != points[i]);
}
