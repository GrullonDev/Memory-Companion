import 'dart:math';

/// Turns a calendar day into the same random sequence on every device.
///
/// Everything here is pure arithmetic on the player's **local** date: no
/// network, no server clock. Two players open the app on their own
/// 2026-09-23 and are dealt the same board, just as Wordle does — whether
/// they are online, offline or in different time zones.
abstract final class DailySeed {
  /// `'YYYY-MM-DD'` for the local calendar day of [now].
  static String dateKey(DateTime now) {
    final local = now.toLocal();
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '${local.year.toString().padLeft(4, '0')}-$m-$d';
  }

  /// 32-bit seed for [dateKey].
  ///
  /// The salt keeps the seed from being the same as any other app that
  /// hashes a bare date. Never change it once shipped: it would re-deal
  /// every past and future challenge and break shared results.
  static int seedFor(String dateKey) => _fnv1a32('memory-companion:$dateKey');

  /// FNV-1a, 32 bits. Written with only 32-bit-safe operations so the web
  /// build (where ints are doubles) computes exactly what the VM does.
  static int _fnv1a32(String input) {
    var hash = 0x811c9dc5;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      // hash * 16777619, split so no intermediate exceeds 2^53.
      hash = (hash * 0x193 + ((hash << 24) & _mask32)) & _mask32;
    }
    return hash;
  }
}

const int _mask32 = 0xFFFFFFFF;

/// A [Random] whose sequence is fixed forever by its seed.
///
/// `dart:math`'s `Random(seed)` is deterministic within one SDK, but its
/// algorithm is not part of the API contract: an SDK upgrade could change
/// it, and two players on different app versions would be dealt different
/// "daily" boards. This xorshift32 is ours, so it cannot drift.
class SeededRandom implements Random {
  SeededRandom(int seed)
    : _state = (seed & _mask32) == 0 ? 0x9E3779B9 : seed & _mask32 {
    // Adjacent days have similar seeds; a few rounds decorrelate them.
    for (var i = 0; i < 8; i++) {
      _next32();
    }
  }

  int _state;

  int _next32() {
    var x = _state;
    x ^= (x << 13) & _mask32;
    x ^= x >> 17;
    x ^= (x << 5) & _mask32;
    return _state = x & _mask32;
  }

  /// In `[0, 1)`. Exact: a 32-bit integer over 2^32 fits a double.
  @override
  double nextDouble() => _next32() / 4294967296.0;

  @override
  int nextInt(int max) {
    if (max <= 0 || max > 0x100000000) {
      throw RangeError.range(max, 1, 0x100000000, 'max');
    }
    // Multiplying doubles rather than 64-bit ints keeps web and VM equal.
    return (nextDouble() * max).floor();
  }

  @override
  bool nextBool() => (_next32() & 1) == 1;
}
