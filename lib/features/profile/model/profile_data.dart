import 'package:memory_companion/features/profile/model/achievement.dart';
import 'package:memory_companion/features/profile/model/profile_match.dart';

/// Everything the Profile screen renders beyond the shared coin balance.
class ProfileData {
  const ProfileData({
    required this.name,
    required this.rank,
    required this.level,
    required this.currentXp,
    required this.targetXp,
    required this.gamesWon,
    required this.totalMoves,
    required this.bestStreak,
    required this.totalCoins,
    required this.achievements,
    required this.matches,
    this.avatarSeed = 0,
  });

  final String name;
  final String rank;
  final int level;
  final int currentXp;
  final int targetXp;
  final int gamesWon;
  final String totalMoves;
  final int bestStreak;
  final String totalCoins;
  final List<Achievement> achievements;
  final List<ProfileMatch> matches;
  final int avatarSeed;

  ProfileData copyWith({int? avatarSeed}) {
    return ProfileData(
      name: name,
      rank: rank,
      level: level,
      currentXp: currentXp,
      targetXp: targetXp,
      gamesWon: gamesWon,
      totalMoves: totalMoves,
      bestStreak: bestStreak,
      totalCoins: totalCoins,
      achievements: achievements,
      matches: matches,
      avatarSeed: avatarSeed ?? this.avatarSeed,
    );
  }
}
