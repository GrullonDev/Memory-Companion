import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/features/auth/controller/user_controller.dart';
import 'package:memory_companion/features/game/controller/game_controller.dart';
import 'package:memory_companion/features/profile/model/achievement.dart';
import 'package:memory_companion/features/profile/model/profile_data.dart';
import 'package:memory_companion/features/player/model/player_level.dart';
import 'package:memory_companion/features/profile/model/profile_match.dart';
import 'package:memory_companion/core/localization/app_locale.dart';

class ProfileController extends AsyncNotifier<ProfileData> {
  @override
  Future<ProfileData> build() async {
    // Watch the current user from Firestore
    final appUser = await ref.watch(currentUserProvider.future);

    if (appUser == null) {
      // Fallback if no user is logged in
      return const ProfileData(
        name: 'Guest',
        rank: 'Novice',
        level: 1,
        currentXp: 0,
        targetXp: 1000,
        gamesWon: 0,
        totalMoves: '0',
        bestStreak: 0,
        totalCoins: '0',
        achievements: [],
        matches: [],
        avatarSeed: 0,
      );
    }

    // Fetch match history from Firestore
    final matches = await ref.watch(userMatchHistoryProvider.future);

    // Convert Match objects to ProfileMatch objects
    final profileMatches = matches.map((match) {
      return ProfileMatch(
        title: '${match.gameMode.toUpperCase()} - ${match.score}',
        score: match.score.toString(),
        moves: match.moves,
        playedAt: match.playedAt,
        result: match.won ? MatchResult.win : MatchResult.loss,
      );
    }).toList();

    // Format numbers for display
    final totalCoinsFormatted = _formatNumber(appUser.totalCoins);
    final totalMovesFormatted = _formatNumber(appUser.totalMoves);

    return ProfileData(
      name: appUser.displayName ?? appUser.email,
      rank: appUser.rank,
      // Nivel y progreso se derivan del acumulado, en lugar de leer un
      // campo `level` que nadie escribía nunca.
      level: levelFromTotalXp(appUser.totalXp),
      currentXp: xpIntoLevel(appUser.totalXp),
      targetXp: xpForLevel(levelFromTotalXp(appUser.totalXp)),
      gamesWon: appUser.gamesWon,
      totalMoves: totalMovesFormatted,
      bestStreak: appUser.bestStreak,
      totalCoins: totalCoinsFormatted,
      achievements: _getUnlockedAchievements(appUser),
      matches: profileMatches,
      avatarSeed: appUser.avatarSeed,
    );
  }

  /// Format large numbers (e.g., 1000 -> "1k")
  String _formatNumber(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return '$value';
  }

  /// Get achievements based on stats
  List<Achievement> _getUnlockedAchievements(
    dynamic appUser, // Use dynamic to avoid circular dependency
  ) {
    final achievements = [
      Achievement(
        icon: Icons.emoji_events_rounded,
        titleKey: AppLocale.achievementStreak10,
        unlocked: appUser.bestStreak >= 10,
      ),
      Achievement(
        icon: Icons.flash_on_rounded,
        titleKey: AppLocale.achievementSprinter,
        unlocked: appUser.gamesWon >= 5,
      ),
      Achievement(
        icon: Icons.psychology_rounded,
        titleKey: AppLocale.achievementQuickMind,
        unlocked: appUser.level >= 5,
      ),
      Achievement(
        icon: Icons.military_tech_rounded,
        titleKey: AppLocale.achievementMaster,
        unlocked: appUser.level >= 20,
      ),
      Achievement(
        icon: Icons.diamond_rounded,
        titleKey: AppLocale.achievementCollector,
        unlocked: appUser.totalCoins >= 10000,
      ),
      Achievement(
        icon: Icons.groups_rounded,
        titleKey: AppLocale.achievementSocial,
        unlocked: false, // Will be tied to multiplayer features
      ),
    ];
    return achievements;
  }

  /// Randomize avatar and save to Firestore
  Future<void> randomizeAvatar() async {
    final current = state.value;
    if (current == null) return;

    final newSeed = current.avatarSeed + 1;
    state = AsyncValue.data(current.copyWith(avatarSeed: newSeed));

    // Save to Firestore
    await ref
        .read(userControllerProvider.notifier)
        .updateProfile(avatarSeed: newSeed);
  }
}

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, ProfileData>(
      ProfileController.new,
    );
