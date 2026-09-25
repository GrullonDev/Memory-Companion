import 'package:memory_companion/features/friends/model/friend_code.dart';

/// How a friend code travels in a Bluetooth advertisement.
///
/// The code is packed into a 128-bit service UUID: a fixed Memory Arcade
/// prefix, then the code's six ASCII characters. A service UUID is the one
/// field every platform both advertises (iOS broadcasts only service UUIDs
/// and a name while in the foreground) and reports back when scanning, and
/// it fits in a legacy advertisement with room to spare. No name or other
/// data is broadcast.
abstract final class NearbyBeacon {
  /// `memarcad` in ASCII, then version 1.
  static const String prefix = '6d656d61-7263-6164-0001-';

  /// The service UUID that advertises [code].
  static String uuidFor(String code) {
    assert(code.length == FriendCode.length);
    final hex = [
      for (final unit in code.codeUnits) unit.toRadixString(16).padLeft(2, '0'),
    ].join();
    return '$prefix$hex';
  }

  /// The friend code inside [uuid], or null if it is not one of ours.
  static String? codeFrom(String uuid) {
    final lower = uuid.toLowerCase();
    if (!lower.startsWith(prefix)) return null;
    final hex = lower.substring(prefix.length);
    if (hex.length != FriendCode.length * 2) return null;
    final units = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      final unit = int.tryParse(hex.substring(i, i + 2), radix: 16);
      if (unit == null) return null;
      units.add(unit);
    }
    return FriendCode.normalize(String.fromCharCodes(units));
  }
}
