import 'package:flutter/material.dart';

import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/routes/route_paths.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/widgets/avatar_picker.dart';
import 'package:memory_companion/features/auth/controller/auth_controller.dart';
import 'package:memory_companion/features/auth/login/widget/social_login_row.dart';
import 'package:memory_companion/features/auth/register/widget/dotted_background.dart';
import 'package:memory_companion/features/auth/util/auth_error_mapper.dart';
import 'package:memory_companion/features/auth/widget/auth_primary_button.dart';
import 'package:memory_companion/features/auth/widget/auth_text_field.dart';
import 'package:memory_companion/features/auth/widget/phone_sign_in_dialog.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  int _avatarSeed = 0;
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitRegister() {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocale.fieldsRequiredMessage.getString(context))),
      );
      return;
    }
    ref.read(authControllerProvider.notifier).register(
      email: email,
      password: password,
      displayName: username,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    ref.listen(authControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authErrorMessage(context, error))),
        ),
        data: (_) {
          if (previous is AsyncLoading) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocale.accountCreatedMessage.getString(context)),
              ),
            );
          }
        },
      );
    });

    ref.listen(authStateChangesProvider, (previous, next) {
      final user = next.value;
      if (user != null) {
        Navigator.of(context).pushReplacementNamed(RoutePaths.home);
      }
    });

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
                        controller: _usernameController,
                        enabled: !isLoading,
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
                        controller: _emailController,
                        enabled: !isLoading,
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
                        controller: _passwordController,
                        enabled: !isLoading,
                      ),
                      const SizedBox(height: 24),
                      AuthPrimaryButton(
                        label: AppLocale.createAccountLabel.getString(context),
                        trailingIcon: Icons.arrow_forward_rounded,
                        isLoading: isLoading,
                        onTap: _submitRegister,
                      ),
                      const SizedBox(height: 24),
                      SocialLoginRow(
                        onGoogleTap: isLoading
                            ? null
                            : () => ref
                                .read(authControllerProvider.notifier)
                                .signInWithGoogle(),
                        onPhoneTap: isLoading
                            ? null
                            : () => showPhoneSignInDialog(context),
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
