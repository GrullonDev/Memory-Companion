import 'package:flutter/material.dart';

import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/routes/route_paths.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/widgets/avatar_picker.dart';
import 'package:memory_companion/features/auth/register/widget/dotted_background.dart';
import 'package:memory_companion/features/auth/widget/auth_primary_button.dart';
import 'package:memory_companion/features/auth/widget/auth_text_field.dart';

/// Kept as a [StatefulWidget] only for the local avatar-seed toggle — no
/// account is actually created yet, so this is otherwise a static form.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int _avatarSeed = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: DottedBackground(
          child: SizedBox.expand(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              children: [
                Text(
                  AppLocale.appTitle.getString(context),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocale.registerSubtitle.getString(context),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.all(Radius.circular(28)),
                    border: Border(
                      top: BorderSide(
                        color: AppColors.secondaryContainer,
                        width: 6,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x14000000),
                        offset: Offset(0, 8),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      AvatarPicker(
                        seed: _avatarSeed,
                        onRandomize: () =>
                            setState(() => _avatarSeed = _avatarSeed + 1),
                      ),
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          AppLocale.usernameLabel.getString(context),
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      AuthTextField(
                        icon: Icons.person_outline_rounded,
                        hint: AppLocale.usernameHint.getString(context),
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          AppLocale.emailLabel.getString(context),
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      AuthTextField(
                        icon: Icons.mail_outline_rounded,
                        hint: AppLocale.emailHint.getString(context),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          AppLocale.passwordLabel.getString(context),
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      AuthTextField(
                        icon: Icons.lock_outline_rounded,
                        hint: AppLocale.passwordHintStrong.getString(context),
                        isPassword: true,
                      ),
                      const SizedBox(height: 24),
                      AuthPrimaryButton(
                        label: AppLocale.createAccountLabel.getString(context),
                        trailingIcon: Icons.arrow_forward_rounded,
                        onTap: () => Navigator.of(
                          context,
                        ).pushReplacementNamed(RoutePaths.home),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      Text(
                        '${AppLocale.alreadyHaveAccountLabel.getString(context)} ',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(
                          context,
                        ).pushReplacementNamed(RoutePaths.login),
                        child: Text(
                          AppLocale.loginLabel.getString(context),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                                decoration: TextDecoration.underline,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
