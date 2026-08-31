import 'package:memory_companion/features/player/model/player_level.dart';

/// Todo lo que la cabecera de la Home necesita saber del jugador, en una
/// instantánea inmutable: quién es, cuánto ha avanzado y cuántos días
/// seguidos ha aparecido.
///
/// Vista de solo lectura sobre el perfil: no calcula nada que el backend no
/// tenga ya, así que nada de aquí puede inventar progreso.
///
/// [level], [targetXp], [xpProgress] y [xpRemaining] son **derivados** de
/// [totalXp]. Antes eran campos independientes y nadie escribía el nivel; ver
/// `player_level.dart`.
class HomeSummary {
  const HomeSummary({
    required this.playerName,
    required this.totalXp,
    required this.streakDays,
    required this.isLoading,
  });

  const HomeSummary.empty({this.isLoading = false})
      : playerName = '',
        totalXp = 0,
        streakDays = 0;

  /// Nombre visible, o cadena vacía mientras el perfil no ha cargado.
  final String playerName;

  /// XP acumulado de por vida.
  final int totalXp;

  /// Días consecutivos jugados. 0 significa que no hay racha que proteger,
  /// que la UI trata como una invitación y no como un fracaso.
  final int streakDays;

  final bool isLoading;

  int get level => levelFromTotalXp(totalXp);

  /// XP que pide el nivel actual para completarse.
  int get targetXp => xpForLevel(level);

  /// Progreso dentro del nivel actual, de 0.0 a 1.0.
  double get xpProgress => levelProgress(totalXp);

  /// XP que falta para subir de nivel.
  int get xpRemaining => xpToNextLevel(totalXp);

  int get nextLevel => level + 1;

  bool get hasStreak => streakDays > 0;
}
