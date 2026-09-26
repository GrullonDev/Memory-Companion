import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/theme/profile_tokens.dart';
import 'package:memory_companion/core/widgets/app_card.dart';
import 'package:memory_companion/features/game_context/controller/game_context_providers.dart';
import 'package:memory_companion/features/game_context/model/place.dart';
import 'package:memory_companion/features/history_search/history_search_screen.dart';
import 'package:memory_companion/features/settings/controller/display_preferences_controller.dart';

/// The automatic game context: two opt-in switches, and the places found so
/// far so the player can name them.
///
/// A switch turns on only after its permission is granted; turning it off
/// never asks anything. Nothing here needs a connection.
class ContextSettingsSection extends ConsumerWidget {
  const ContextSettingsSection({super.key});

  Future<void> _setLocation(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    final controller = ref.read(displayPreferencesControllerProvider.notifier);
    if (enabled &&
        !await ref.read(locationSourceProvider).requestPermission()) {
      if (context.mounted) _denied(context);
      return;
    }
    await controller.setContextLocation(enabled);
  }

  Future<void> _setNearby(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    final controller = ref.read(displayPreferencesControllerProvider.notifier);
    if (enabled && !await ref.read(nearbyRadioProvider).requestPermission()) {
      if (context.mounted) _denied(context);
      return;
    }
    await controller.setContextNearby(enabled);
  }

  void _denied(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(AppLocale.contextPermissionDenied.getString(context)),
        ),
      );
  }

  Future<void> _rename(BuildContext context, WidgetRef ref, Place place) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _RenamePlaceDialog(initial: place.name ?? ''),
    );
    if (name == null) return;
    await ref.read(placeRepositoryProvider).rename(place.id, name);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(displayPreferencesProvider);
    final places = ref.watch(placesProvider).value ?? const <Place>[];
    final tokens = ProfileTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final supporting = textTheme.bodyMedium?.copyWith(
      color: tokens.supportingTextColor,
    );

    Widget toggle({
      required bool value,
      required ValueChanged<bool> onChanged,
      required IconData icon,
      required String titleKey,
      required String subtitleKey,
    }) => SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeTrackColor: AppColors.sunStrong,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      secondary: Icon(icon),
      title: Text(titleKey.getString(context), style: textTheme.titleMedium),
      subtitle: Text(subtitleKey.getString(context), style: supporting),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            AppLocale.contextSectionTitle.getString(context),
            style: textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          AppLocale.contextSectionSubtitle.getString(context),
          style: supporting,
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          padding: EdgeInsets.zero,
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              children: [
                toggle(
                  value: preferences.contextLocation,
                  onChanged: (on) => _setLocation(context, ref, on),
                  icon: Icons.place_outlined,
                  titleKey: AppLocale.contextLocationTitle,
                  subtitleKey: AppLocale.contextLocationSubtitle,
                ),
                const Divider(height: 1),
                toggle(
                  value: preferences.contextNearby,
                  onChanged: (on) => _setNearby(context, ref, on),
                  icon: Icons.bluetooth_searching_rounded,
                  titleKey: AppLocale.contextNearbyTitle,
                  subtitleKey: AppLocale.contextNearbySubtitle,
                ),
              ],
            ),
          ),
        ),
        if (preferences.contextLocation || places.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            AppLocale.placesTitle.getString(context),
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: EdgeInsets.zero,
            child: places.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      AppLocale.placesEmpty.getString(context),
                      style: supporting,
                    ),
                  )
                // The card paints its own background; the tiles need a
                // Material above them for their ink splashes to show.
                : Material(
                    type: MaterialType.transparency,
                    child: Column(
                      children: [
                        for (final place in places)
                          Builder(
                            builder: (context) {
                              final label = placeLabel(
                                context,
                                places,
                                place.id,
                              );
                              return ListTile(
                                leading: const Icon(Icons.place_rounded),
                                title: Text(label),
                                trailing: const Icon(Icons.edit_outlined),
                                onTap: () => _rename(context, ref, place),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ],
    );
  }
}

class _RenamePlaceDialog extends StatefulWidget {
  const _RenamePlaceDialog({required this.initial});

  final String initial;

  @override
  State<_RenamePlaceDialog> createState() => _RenamePlaceDialogState();
}

class _RenamePlaceDialogState extends State<_RenamePlaceDialog> {
  late final _name = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    void save() => Navigator.of(context).pop(_name.text);
    return AlertDialog(
      title: Text(AppLocale.placeRenameTitle.getString(context)),
      content: TextField(
        controller: _name,
        autofocus: true,
        maxLength: 40,
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (_) => save(),
        decoration: InputDecoration(
          hintText: AppLocale.placeRenameHint.getString(context),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocale.cancelLabel.getString(context)),
        ),
        FilledButton(
          onPressed: save,
          child: Text(AppLocale.saveLabel.getString(context)),
        ),
      ],
    );
  }
}
