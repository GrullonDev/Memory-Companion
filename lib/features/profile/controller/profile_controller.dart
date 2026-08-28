import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/features/profile/model/achievement.dart';
import 'package:memory_companion/features/profile/model/profile_data.dart';
import 'package:memory_companion/features/profile/model/profile_match.dart';

class ProfileController extends AsyncNotifier<ProfileData> {
  @override
  Future<ProfileData> build() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return const ProfileData(
      name: 'Alex "Spark" Rossi',
      rank: 'Master Rank',
      level: 42,
      currentXp: 1250,
      targetXp: 2000,
      gamesWon: 142,
      totalMoves: '4.5k',
      bestStreak: 12,
      totalCoins: '8.2k',
      achievements: [
        Achievement(
          icon: Icons.emoji_events_rounded,
          title: 'Racha x10',
          unlocked: true,
        ),
        Achievement(
          icon: Icons.flash_on_rounded,
          title: 'Velocista',
          unlocked: true,
        ),
        Achievement(
          icon: Icons.psychology_rounded,
          title: 'Mente Ágil',
          unlocked: true,
        ),
        Achievement(
          icon: Icons.military_tech_rounded,
          title: 'Maestro',
          unlocked: false,
        ),
        Achievement(
          icon: Icons.diamond_rounded,
          title: 'Coleccionista',
          unlocked: false,
        ),
        Achievement(
          icon: Icons.groups_rounded,
          title: 'Social',
          unlocked: false,
        ),
      ],
      matches: [
        ProfileMatch(
          title: 'Venciste a "Memory Master"',
          score: '14,200',
          moves: 28,
          timeAgo: 'Hace 2h',
          result: MatchResult.win,
        ),
        ProfileMatch(
          title: 'Reto Diario',
          score: '9,800',
          moves: 34,
          timeAgo: 'Ayer',
          result: MatchResult.win,
        ),
        ProfileMatch(
          title: 'Duelo vs "PinkFox"',
          score: '5,400',
          moves: 41,
          timeAgo: 'Hace 3 días',
          result: MatchResult.loss,
        ),
      ],
      performancePoints: [
        PerformancePoint(label: 'Lun', value: 0.6),
        PerformancePoint(label: 'Mar', value: 0.72),
        PerformancePoint(label: 'Mié', value: 0.65),
        PerformancePoint(label: 'Jue', value: 0.85),
        PerformancePoint(label: 'Vie', value: 0.78),
        PerformancePoint(label: 'Sáb', value: 0.92),
        PerformancePoint(label: 'Dom', value: 0.88),
      ],
    );
  }

  /// Simulates rolling a new avatar look — no illustrated avatar art exists
  /// yet, so this only changes which stand-in seed is stored.
  void randomizeAvatar() {
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(
      current.copyWith(avatarSeed: current.avatarSeed + 1),
    );
  }
}

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, ProfileData>(
      ProfileController.new,
    );
