import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/widgets/adaptive_button.dart';
import 'package:memory_companion/core/widgets/app_card.dart';

/// Opens a game room, or joins someone else's with its code. Rooms need no
/// friendship: sharing the code is the invitation.
class PlayRoomCard extends StatefulWidget {
  const PlayRoomCard({super.key, required this.onCreate, required this.onJoin});

  final Future<void> Function() onCreate;

  /// Joins the room behind the typed code. Returns whether it worked, so
  /// the field is only cleared on success.
  final Future<bool> Function(String code) onJoin;

  @override
  State<PlayRoomCard> createState() => _PlayRoomCardState();
}

class _PlayRoomCardState extends State<PlayRoomCard> {
  final _code = TextEditingController();
  var _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() => _run(() async {
    final code = _code.text.trim();
    if (code.isEmpty) return;
    FocusScope.of(context).unfocus();
    if (await widget.onJoin(code)) _code.clear();
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppLocale.playRoomTitle.getString(context),
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            AppLocale.playRoomMessage.getString(context),
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AdaptiveButton(
            label: AppLocale.createRoomLabel.getString(context),
            icon: Icons.add_home_rounded,
            onPressed: _busy ? null : () => _run(widget.onCreate),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _code,
                  enabled: !_busy,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.go,
                  onSubmitted: (_) => _join(),
                  decoration: InputDecoration(
                    hintText: AppLocale.roomCodeHint.getString(context),
                    prefixIcon: const Icon(Icons.meeting_room_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton(
                onPressed: _busy ? null : _join,
                child: _busy
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(AppLocale.joinRoomLabel.getString(context)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
