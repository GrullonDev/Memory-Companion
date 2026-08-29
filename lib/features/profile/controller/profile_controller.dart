import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/features/auth/controller/user_controller.dart';
import 'package:memory_companion/features/game/controller/game_controller.dart';
import 'package:memory_companion/features/profile/model/achievement.dart';
import 'package:memory_companion/features/profile/model/profile_data.dart';
import 'package:memory_companion/features/profile/model/profile_match.dart';

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
        performancePoints: [],
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
        timeAgo: _getTimeAgoString(match.playedAt),
        result: match.won ? MatchResult.win : MatchResult.loss,
      );
    }).toList();

    // Format numbers for display
    final totalCoinsFormatted = _formatNumber(appUser.totalCoins);
    final totalMovesFormatted = _formatNumber(appUser.totalMoves);

    return ProfileData(
      name: appUser.displayName ?? appUser.email,
      rank: appUser.rank,
      level: appUser.level,
      currentXp: appUser.currentXp,
      targetXp: 1000 * appUser.level, // XP needed for next level
      gamesWon: appUser.gamesWon,
      totalMoves: totalMovesFormatted,
      bestStreak: appUser.bestStreak,
      totalCoins: totalCoinsFormatted,
      achievements: _getUnlockedAchievements(appUser),
      matches: profileMatches,
      performancePoints: _getPerformancePoints(),
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

  /// Convert datetime to "time ago" format
  String _getTimeAgoString(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Hace unos segundos';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays}d';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'Hace ${weeks}w';
    } else {
      final months = (difference.inDays / 30).floor();
      return 'Hace ${months}m';
    }
  }

  /// Get achievements based on stats
  List<Achievement> _getUnlockedAchievements(
    dynamic appUser, // Use dynamic to avoid circular dependency
  ) {
    final achievements = [
      Achievement(
        icon: Icons.emoji_events_rounded,
        title: 'Racha x10',
        unlocked: appUser.bestStreak >= 10,
      ),
      Achievement(
        icon: Icons.flash_on_rounded,
        title: 'Velocista',
        unlocked: appUser.gamesWon >= 5,
      ),
      Achievement(
        icon: Icons.psychology_rounded,
        title: 'Mente Ágil',
        unlocked: appUser.level >= 5,
      ),
      Achievement(
        icon: Icons.military_tech_rounded,
        title: 'Maestro',
        unlocked: appUser.level >= 20,
      ),
      Achievement(
        icon: Icons.diamond_rounded,
        title: 'Coleccionista',
        unlocked: appUser.totalCoins >= 10000,
      ),
      Achievement(
        icon: Icons.groups_rounded,
        title: 'Social',
        unlocked: false, // Will be tied to multiplayer features
      ),
    ];
    return achievements;
  }

  /// Get performance points for the week
  List<PerformancePoint> _getPerformancePoints() {
    // Placeholder - will be updated with real data
    return [
      PerformancePoint(label: 'Lun', value: 0.6),
      PerformancePoint(label: 'Mar', value: 0.72),
      PerformancePoint(label: 'Mié', value: 0.65),
      PerformancePoint(label: 'Jue', value: 0.85),
      PerformancePoint(label: 'Vie', value: 0.78),
      PerformancePoint(label: 'Sáb', value: 0.92),
      PerformancePoint(label: 'Dom', value: 0.88),
    ];
  }

  /// Randomize avatar and save to Firestore
  Future<void> randomizeAvatar() async {
    final current = state.value;
    if (current == null) return;

    final newSeed = current.avatarSeed + 1;
    state = AsyncValue.data(current.copyWith(avatarSeed: newSeed));

    // Save to Firestore
    await ref.read(userControllerProvider.notifier).updateProfile(
      avatarSeed: newSeed,
    );
  }
}

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, ProfileData>(
      ProfileController.new,
    );
