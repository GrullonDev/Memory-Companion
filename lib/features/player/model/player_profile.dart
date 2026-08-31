import 'package:memory_companion/core/database/app_database.dart';

/// El jugador, con o sin cuenta.
///
/// Modelo de dominio inmutable sobre [PlayerProfileRow]. La UI y los
/// controladores hablan con esta clase; nadie fuera de la capa de datos
/// toca una fila de Drift.
///
/// Un jugador local **no es un jugador de segunda**: tiene exactamente los
/// mismos campos que uno con cuenta. La única diferencia es [cloudUid], que
/// es null hasta que decide registrarse — y registrarse no crea un perfil
/// nuevo, rellena ese campo sobre este mismo.
class PlayerProfile {
  const PlayerProfile({
    required this.localId,
    required this.cloudUid,
    required this.displayName,
    required this.avatarSeed,
    required this.totalXp,
    required this.totalCoins,
    required this.gamesWon,
    required this.totalMoves,
    required this.currentStreak,
    required this.longestStreak,
    required this.lastPlayedDate,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });

  factory PlayerProfile.fromRow(PlayerProfileRow row) {
    return PlayerProfile(
      localId: row.localId,
      cloudUid: row.cloudUid,
      displayName: row.displayName,
      avatarSeed: row.avatarSeed,
      totalXp: row.totalXp,
      totalCoins: row.totalCoins,
      gamesWon: row.gamesWon,
      totalMoves: row.totalMoves,
      currentStreak: row.currentStreak,
      longestStreak: row.longestStreak,
      lastPlayedDate: row.lastPlayedDate,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
      version: row.version,
    );
  }

  /// UUID generado en este dispositivo el primer día. Nunca cambia, ni
  /// siquiera al crear una cuenta.
  final String localId;

  /// UID de Firebase, o null mientras el jugador no tenga cuenta.
  final String? cloudUid;

  final String displayName;
  final int avatarSeed;

  /// XP acumulado de por vida. Monótono.
  final int totalXp;
  final int totalCoins;
  final int gamesWon;
  final int totalMoves;

  final int currentStreak;
  final int longestStreak;

  /// `'YYYY-MM-DD'` en zona local, o null si nunca ha jugado.
  final String? lastPlayedDate;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Contador para resolver conflictos en los campos de identidad.
  final int version;

  /// Si su progreso viaja a la nube o vive solo en este teléfono.
  bool get isLinkedToCloud => cloudUid != null;

  /// Si ya ha terminado alguna partida.
  bool get hasPlayed => lastPlayedDate != null;

  @override
  String toString() {
    return 'PlayerProfile(localId: $localId, cloudUid: $cloudUid, '
        'totalXp: $totalXp, streak: $currentStreak)';
  }
}
