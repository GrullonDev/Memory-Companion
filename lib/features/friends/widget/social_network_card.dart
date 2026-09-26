import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/features/friends/controller/friends_controller.dart';
import 'package:memory_companion/features/friends/model/friend.dart';
import 'package:memory_companion/features/friends/model/friend_code.dart';
import 'package:memory_companion/features/friends/widget/friend_tile.dart';

/// The friend list: add by code, answer requests, and challenge or remove
/// friends.
class SocialNetworkCard extends StatefulWidget {
  const SocialNetworkCard({
    super.key,
    required this.state,
    required this.onAdd,
    required this.onAccept,
    required this.onRemove,
    required this.onChallenge,
  });

  final FriendsState state;

  /// Sends a request to the code typed. Resolves to true when the field
  /// can be cleared.
  final Future<bool> Function(String code) onAdd;
  final ValueChanged<Friend> onAccept;

  /// Declines, cancels or removes, depending on the relation.
  final ValueChanged<Friend> onRemove;
  final ValueChanged<Friend> onChallenge;

  @override
  State<SocialNetworkCard> createState() => _SocialNetworkCardState();
}

class _SocialNetworkCardState extends State<SocialNetworkCard> {
  final _code = TextEditingController();
  bool _adding = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (_adding || _code.text.trim().isEmpty) return;
    setState(() => _adding = true);
    final clear = await widget.onAdd(_code.text);
    if (!mounted) return;
    setState(() => _adding = false);
    if (clear) _code.clear();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final state = widget.state;

    Widget section(String titleKey) => Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        titleKey.getString(context),
        style: textTheme.labelLarge?.copyWith(
          color: AppColors.onSurfaceVariant,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    Widget tile(Friend friend, List<Widget> actions) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FriendTile(friend: friend, actions: actions),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: const Border(
          top: BorderSide(color: AppColors.tertiaryFixed, width: 4),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            offset: Offset(0, 6),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.hub_rounded, color: AppColors.tertiary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocale.socialNetworkTitle.getString(context),
                  style: textTheme.titleLarge?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.send,
                  autocorrect: false,
                  enableSuggestions: false,
                  maxLength: FriendCode.length,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                    // Shown the way codes are shared: upper case.
                    TextInputFormatter.withFunction(
                      (_, value) =>
                          value.copyWith(text: value.text.toUpperCase()),
                    ),
                  ],
                  onSubmitted: (_) => _add(),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: AppLocale.findByUsernameHint.getString(context),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.outline,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: const BorderSide(
                        color: AppColors.outlineVariant,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: const BorderSide(
                        color: AppColors.outlineVariant,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _adding ? null : _add,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  backgroundColor: AppColors.primaryFixed,
                  foregroundColor: AppColors.onPrimaryFixed,
                ),
                child: _adding
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(AppLocale.addFriendLabel.getString(context)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (state.incoming.isNotEmpty) ...[
            section(AppLocale.friendRequestsTitle),
            for (final friend in state.incoming)
              tile(friend, [
                FriendTileAction(
                  icon: Icons.check_rounded,
                  tooltip: AppLocale.acceptLabel.getString(context),
                  background: AppColors.mintGreen,
                  foreground: AppColors.onSurface,
                  onTap: () => widget.onAccept(friend),
                ),
                FriendTileAction(
                  icon: Icons.close_rounded,
                  tooltip: AppLocale.declineLabel.getString(context),
                  onTap: () => widget.onRemove(friend),
                ),
              ]),
          ],
          if (state.friends.isEmpty &&
              state.incoming.isEmpty &&
              state.outgoing.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                AppLocale.noFriendsYet.getString(context),
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          if (state.friends.isNotEmpty) ...[
            if (state.incoming.isNotEmpty) section(AppLocale.navFriends),
            for (final friend in state.friends)
              tile(friend, [
                FriendTileAction(
                  icon: Icons.sports_esports_rounded,
                  tooltip: AppLocale.challengeLabel.getString(context),
                  background: AppColors.primaryFixed,
                  foreground: AppColors.onPrimaryFixed,
                  onTap: () => widget.onChallenge(friend),
                ),
                FriendTileAction(
                  icon: Icons.person_remove_rounded,
                  tooltip: AppLocale.removeFriendLabel.getString(context),
                  onTap: () => widget.onRemove(friend),
                ),
              ]),
          ],
          if (state.outgoing.isNotEmpty) ...[
            section(AppLocale.sentRequestsTitle),
            for (final friend in state.outgoing)
              tile(friend, [
                FriendTileAction(
                  icon: Icons.close_rounded,
                  tooltip: AppLocale.cancelRequestLabel.getString(context),
                  onTap: () => widget.onRemove(friend),
                ),
              ]),
          ],
        ],
      ),
    );
  }
}
