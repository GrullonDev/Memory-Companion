import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/routes/route_paths.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/features/home/widget/home_bottom_nav.dart';
import 'package:memory_companion/features/profile/model/achievement.dart';
import 'package:memory_companion/features/profile/model/profile_match.dart';
import 'package:memory_companion/features/profile/widget/achievements_grid.dart';
import 'package:memory_companion/features/profile/widget/match_history_tile.dart';
import 'package:memory_companion/features/profile/widget/next_level_card.dart';
import 'package:memory_companion/features/profile/widget/performance_chart_card.dart';
import 'package:memory_companion/features/profile/widget/profile_header.dart';
import 'package:memory_companion/features/profile/widget/profile_stat_grid.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _matches = [
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
  ];

  static const _achievements = [
    Achievement(icon: Icons.emoji_events_rounded, title: 'Racha x10', unlocked: true),
    Achievement(icon: Icons.flash_on_rounded, title: 'Velocista', unlocked: true),
    Achievement(icon: Icons.psychology_rounded, title: 'Mente Ágil', unlocked: true),
    Achievement(icon: Icons.military_tech_rounded, title: 'Maestro', unlocked: false),
    Achievement(icon: Icons.diamond_rounded, title: 'Coleccionista', unlocked: false),
    Achievement(icon: Icons.groups_rounded, title: 'Social', unlocked: false),
  ];

  static const _performancePoints = [
    (label: 'Lun', value: 0.6),
    (label: 'Mar', value: 0.72),
    (label: 'Mié', value: 0.65),
    (label: 'Jue', value: 0.85),
    (label: 'Vie', value: 0.78),
    (label: 'Sáb', value: 0.92),
    (label: 'Dom', value: 0.88),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: HomeBottomNav(
        onTap: (index) => RoutePaths.navigateToTab(context, index),
      ),
      body: SafeArea(
        bottom: true,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
                ),
                Expanded(
                  child: Text(
                    AppLocale.profileTitle.getString(context),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 8),
            ProfileHeader(
              name: 'Alex "Spark" Rossi',
              rank: 'Master Rank',
              level: 42,
              onEditAvatar: () {},
            ),
            const SizedBox(height: 24),
            const NextLevelCard(currentXp: 1250, targetXp: 2000),
            const SizedBox(height: 16),
            const ProfileStatGrid(
              gamesWon: 142,
              totalMoves: '4.5k',
              bestStreak: 12,
              totalCoins: '8.2k',
            ),
            const SizedBox(height: 24),
            Text(
              AppLocale.achievementsTitle.getString(context),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            const AchievementsGrid(achievements: _achievements),
            const SizedBox(height: 24),
            const PerformanceChartCard(points: _performancePoints),
            const SizedBox(height: 24),
            Text(
              AppLocale.matchHistoryTitle.getString(context),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            for (final match in _matches) ...[
              MatchHistoryTile(match: match),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}
