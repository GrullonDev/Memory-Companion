import 'dart:math';

import 'package:memory_companion/features/friends/model/friend_code.dart';

/// The code a room's host shares so someone else can join it.
///
/// Same shape as a [FriendCode] (six characters, no look-alikes) so players
/// read and type both the same way, but random: a room is one game, not an
/// identity.
abstract final class RoomCode {
  static const int length = FriendCode.length;

  static const String _alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  static String generate(Random random) => String.fromCharCodes([
    for (var i = 0; i < length; i++)
      _alphabet.codeUnitAt(random.nextInt(_alphabet.length)),
  ]);

  /// [input] as a well-formed code, or null if it cannot be one.
  static String? normalize(String input) => FriendCode.normalize(input);
}
