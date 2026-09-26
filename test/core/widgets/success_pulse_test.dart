import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/core/theme/app_motion.dart';
import 'package:memory_companion/core/widgets/success_pulse.dart';

/// Counts its own `initState`s, to prove the pulse never remounts it.
class _Probe extends StatefulWidget {
  const _Probe(this.mounts);

  final List<int> mounts;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  void initState() {
    super.initState();
    widget.mounts.add(1);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.square(dimension: 40);
}

void main() {
  final mounts = <int>[];

  Future<void> pump(
    WidgetTester tester,
    Object? trigger, {
    bool reduceMotion = false,
  }) {
    return tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SuccessPulse(trigger: trigger, child: _Probe(mounts)),
          ),
        ),
      ),
    );
  }

  double scale(WidgetTester tester) {
    final transform = tester.widget<Transform>(
      find.descendant(
        of: find.byType(SuccessPulse),
        matching: find.byType(Transform),
      ),
    );
    return transform.transform.getMaxScaleOnAxis();
  }

  setUp(mounts.clear);

  testWidgets('pops when the trigger changes, then settles', (tester) async {
    await pump(tester, null);
    expect(scale(tester), 1);

    await pump(tester, 1);
    await tester.pump(const Duration(milliseconds: 150));
    expect(scale(tester), greaterThan(1.05));

    await tester.pump(AppMotion.celebrate);
    expect(scale(tester), 1);
    expect(mounts, hasLength(1), reason: 'the child was never remounted');
  });

  testWidgets('same trigger, or back to null, does not replay', (tester) async {
    await pump(tester, 1);
    await pump(tester, 1);
    await tester.pump(const Duration(milliseconds: 150));
    expect(scale(tester), 1);

    await pump(tester, null);
    await tester.pump(const Duration(milliseconds: 150));
    expect(scale(tester), 1);
  });

  testWidgets('reduce motion keeps the glow but drops the pop', (tester) async {
    await pump(tester, null, reduceMotion: true);
    await pump(tester, 1, reduceMotion: true);
    await tester.pump(const Duration(milliseconds: 100));
    expect(scale(tester), 1);
    final box = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(SuccessPulse),
        matching: find.byType(DecoratedBox),
      ),
    );
    expect((box.decoration as BoxDecoration).boxShadow, isNotEmpty);
    await tester.pumpAndSettle();
  });
}
