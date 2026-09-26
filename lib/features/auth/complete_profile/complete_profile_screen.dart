import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/routes/route_paths.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/features/auth/complete_profile/complete_profile_controller.dart';
import 'package:memory_companion/features/auth/register/widget/dotted_background.dart';
import 'package:memory_companion/features/auth/util/auth_error_mapper.dart';
import 'package:memory_companion/features/auth/widget/auth_primary_button.dart';
import 'package:memory_companion/features/auth/widget/auth_text_field.dart';
import 'package:memory_companion/features/player/controller/player_controller.dart';

/// Asks a player who signed in by phone for their name, the one step phone
/// sign-in skips. Shown once: the name then lives on the account.
class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _name = TextEditingController();

  @override
  void initState() {
    super.initState();
    // A name already chosen on this device is the natural suggestion.
    ref.read(localPlayerProvider.future).then((player) {
      if (mounted && _name.text.isEmpty) _name.text = player.displayName;
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (!CompleteProfileController.isValid(_name.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocale.displayNameRequired.getString(context)),
        ),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    ref.read(completeProfileControllerProvider.notifier).save(_name.text);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(completeProfileControllerProvider).isLoading;

    ref.listen(completeProfileControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authErrorMessage(context, error))),
        ),
        data: (_) {
          if (previous is AsyncLoading) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(RoutePaths.home, (_) => false);
          }
        },
      );
    });

    final textTheme = Theme.of(context).textTheme;
    return PopScope(
      // The name is what others see: there is no screen to go back to.
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: DottedBackground(
            child: SizedBox.expand(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 32),
                  const Icon(
                    Icons.badge_rounded,
                    size: 64,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocale.completeProfileTitle.getString(context),
                    textAlign: TextAlign.center,
                    style: textTheme.headlineSmall?.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocale.completeProfileMessage.getString(context),
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 28),
                  AuthTextField(
                    icon: Icons.person_outline_rounded,
                    hint: AppLocale.usernameHint.getString(context),
                    controller: _name,
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: 24),
                  AuthPrimaryButton(
                    label: AppLocale.continueLabel.getString(context),
                    trailingIcon: Icons.arrow_forward_rounded,
                    isLoading: isLoading,
                    onTap: isLoading ? null : _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
