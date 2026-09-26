import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/features/level_map/controller/map_navigator_controller.dart';
import 'package:memory_companion/features/level_map/model/level_node.dart';
import 'package:memory_companion/features/level_map/widget/forest_backdrop.dart';
import 'package:memory_companion/features/level_map/widget/level_path.dart';
import 'package:memory_companion/features/level_map/widget/map_navigator_button.dart';
import 'package:memory_companion/features/level_map/widget/map_navigator_sheet.dart';
import 'package:memory_companion/features/versus/widget/versus_top_bar.dart';

/// Level-select map shown before a solo match: a winding path of level
/// nodes (locked / current / completed) over a stylized forest backdrop.
///
/// The map button at the foot opens the navigator (progress, next reward,
/// play or return to the current level). When the player scrolls the
/// current level out of sight, a "Go to my level" chip offers the way back.
class LevelMapScreen extends StatefulWidget {
  const LevelMapScreen({
    super.key,
    required this.regionName,
    required this.levels,
    required this.onSelectLevel,
    this.progress = const MapProgress(currentLevel: 1),
    this.showNavigatorHint = false,
    this.onNavigatorHintSeen,
    this.coins = 0,
  });

  final String regionName;
  final List<LevelNode> levels;
  final ValueChanged<LevelNode> onSelectLevel;
  final MapProgress progress;

  /// Shows the one-time bubble explaining the map button.
  final bool showNavigatorHint;
  final VoidCallback? onNavigatorHintSeen;
  final int coins;

  @override
  State<LevelMapScreen> createState() => _LevelMapScreenState();
}

class _LevelMapScreenState extends State<LevelMapScreen> {
  final _scroll = ScrollController();
  final _currentNodeKey = GlobalKey();

  /// Bumped to pulse the current node after the map returns to it.
  int? _focusPulse;
  bool _currentVisible = true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_checkCurrentVisible);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  LevelNode? get _currentNode => widget.levels
      .where((node) => node.status == LevelStatus.current)
      .firstOrNull;

  /// Whether most of the current node is inside the map's viewport.
  void _checkCurrentVisible() {
    final node = _currentNodeKey.currentContext?.findRenderObject();
    final viewport = _scroll.position.context.notificationContext
        ?.findRenderObject();
    if (node is! RenderBox || viewport is! RenderBox || !node.attached) return;
    final nodeRect =
        node.localToGlobal(Offset.zero, ancestor: viewport) & node.size;
    final visible =
        (Offset.zero & viewport.size).intersect(nodeRect).height >
        node.size.height / 2;
    if (visible != _currentVisible) setState(() => _currentVisible = visible);
  }

  Future<void> _goToCurrent() async {
    final context = _currentNodeKey.currentContext;
    if (context != null) {
      await Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: MediaQuery.disableAnimationsOf(this.context)
            ? Duration.zero
            : const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    }
    if (mounted) setState(() => _focusPulse = (_focusPulse ?? 0) + 1);
  }

  Future<void> _openNavigator() async {
    if (widget.showNavigatorHint) widget.onNavigatorHintSeen?.call();
    final action = await MapNavigatorSheet.show(
      context,
      regionName: widget.regionName,
      progress: widget.progress,
    );
    if (!mounted) return;
    switch (action) {
      case MapNavigatorAction.goToMyLevel:
        await _goToCurrent();
      case MapNavigatorAction.playCurrent:
        if (_currentNode case final node?) widget.onSelectLevel(node);
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const ForestBackdrop(),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: VersusTopBar(coins: widget.coins),
              ),
              Expanded(
                child: Stack(
                  children: [
                    ListView(
                      controller: _scroll,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      children: [
                        LevelPath(
                          levels: widget.levels,
                          onSelectLevel: widget.onSelectLevel,
                          currentNodeKey: _currentNodeKey,
                          focusPulse: _focusPulse,
                        ),
                      ],
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 12,
                      child: Center(
                        child: AnimatedSlide(
                          offset: _currentVisible
                              ? const Offset(0, 1.5)
                              : Offset.zero,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          child: AnimatedOpacity(
                            opacity: _currentVisible ? 0 : 1,
                            duration: const Duration(milliseconds: 160),
                            child: IgnorePointer(
                              ignoring: _currentVisible,
                              child: ActionChip(
                                avatar: const Icon(
                                  Icons.my_location_rounded,
                                  size: 18,
                                ),
                                label: Text(
                                  AppLocale.mapGoToMyLevel.getString(context),
                                ),
                                onPressed: _goToCurrent,
                                backgroundColor:
                                    AppColors.surfaceContainerLowest,
                                elevation: 4,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (widget.showNavigatorHint)
                      Positioned(
                        right: 20,
                        bottom: 4,
                        child: MapNavigatorHint(
                          onDismiss: () => widget.onNavigatorHintSeen?.call(),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  children: [
                    Expanded(child: _RegionPill(name: widget.regionName)),
                    const SizedBox(width: 12),
                    MapNavigatorButton(
                      onTap: _openNavigator,
                      showBadge: widget.progress.rewardWithinReach,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RegionPill extends StatelessWidget {
  const _RegionPill({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
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
        name,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppColors.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
