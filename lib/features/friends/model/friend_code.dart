/// The short code a player shares so others can add them as a friend.
///
/// Derived from the Firebase uid, so it needs no server to hand it out and
/// never changes. The alphabet leaves out look-alikes (0/O, 1/I/L) because
/// people read these codes aloud and type them by hand.
abstract final class FriendCode {
  static const int length = 6;

  static const String _alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  static String fromUid(String uid) {
    var hash = _fnv1a32('friend-code:$uid');
    final buffer = StringBuffer();
    for (var i = 0; i < length; i++) {
      buffer.write(_alphabet[hash % _alphabet.length]);
      hash ~/= _alphabet.length;
    }
    return buffer.toString();
  }

  /// [input] as a well-formed code — upper case, spaces and dashes removed —
  /// or null if it cannot be one.
  static String? normalize(String input) {
    final code = input.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');
    if (code.length != length) return null;
    for (final char in code.split('')) {
      if (!_alphabet.contains(char)) return null;
    }
    return code;
  }

  /// FNV-1a, 32 bits, with only 32-bit-safe operations so web and VM agree.
  static int _fnv1a32(String input) {
    const mask = 0xFFFFFFFF;
    var hash = 0x811c9dc5;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x193 + ((hash << 24) & mask)) & mask;
    }
    return hash;
  }
}
