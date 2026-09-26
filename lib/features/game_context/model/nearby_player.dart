import 'dart:convert';

/// A player whose phone was advertising Memory Arcade within Bluetooth
/// range.
///
/// [name] is what this device knew them as when they were seen (a friend's
/// display name). Kept as it was then, so the history still says who it
/// was after a friendship ends.
class NearbyPlayer {
  const NearbyPlayer({required this.code, this.name});

  /// Their friend code, the only thing the advertisement carries.
  final String code;
  final String? name;

  Map<String, Object?> toJson() => {'code': code, 'name': ?name};

  factory NearbyPlayer.fromJson(Map<String, Object?> json) => NearbyPlayer(
    code: json['code']! as String,
    name: json['name'] as String?,
  );

  /// The `game_stats.nearby` column: null when nobody was looked for.
  static String? encodeList(List<NearbyPlayer>? players) => players == null
      ? null
      : jsonEncode([for (final player in players) player.toJson()]);

  static List<NearbyPlayer>? decodeList(String? column) {
    if (column == null) return null;
    try {
      return [
        for (final item in jsonDecode(column) as List)
          NearbyPlayer.fromJson((item as Map).cast<String, Object?>()),
      ];
    } on FormatException {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is NearbyPlayer && other.code == code && other.name == name;

  @override
  int get hashCode => Object.hash(code, name);

  @override
  String toString() => 'NearbyPlayer($code, $name)';
}
