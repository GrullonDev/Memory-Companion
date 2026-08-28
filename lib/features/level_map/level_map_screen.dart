import 'package:flutter/material.dart';

import 'package:memory_companion/core/routes/route_paths.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/features/home/widget/home_bottom_nav.dart';
import 'package:memory_companion/features/level_map/model/level_node.dart';
import 'package:memory_companion/features/level_map/widget/forest_backdrop.dart';
import 'package:memory_companion/features/level_map/widget/level_path.dart';
import 'package:memory_companion/features/versus/widget/versus_top_bar.dart';

/// Level-select map shown before a solo match: a winding path of level
/// nodes (locked / current / completed) over a stylized forest backdrop.
class LevelMapScreen extends StatelessWidget {
  const LevelMapScreen({
    super.key,
    required this.regionName,
    required this.levels,
    required this.onSelectLevel,
  });

  final String regionName;
  final List<LevelNode> levels;
  final ValueChanged<LevelNode> onSelectLevel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: HomeBottomNav(
        onTap: (index) => RoutePaths.navigateToTab(context, index),
      ),
      body: Stack(
        children: [
          const ForestBackdrop(),
          SafeArea(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: VersusTopBar(coins: 1250),
                ),
                Expanded(
                  child: ListView(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    children: [
                      LevelPath(levels: levels, onSelectLevel: onSelectLevel),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1F000000),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            regionName,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppColors.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x1F000000),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.map_rounded,
                          color: AppColors.onSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
