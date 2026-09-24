import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Source of randomness for the mini-game modules. Overridden in tests with
/// a seeded [Random] so a round is dealt the same way every run.
final minigameRandomProvider = Provider<Random>((ref) => Random());
