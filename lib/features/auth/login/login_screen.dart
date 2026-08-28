import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/routes/route_paths.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/widgets/floating_bob.dart';
import 'package:memory_companion/features/auth/login/widget/social_login_row.dart';
import 'package:memory_companion/features/auth/widget/auth_primary_button.dart';
import 'package:memory_companion/features/auth/widget/auth_text_field.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _showForgotPasswordDialog(BuildContext context) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        title: Text(AppLocale.forgotPasswordLabel.getString(dialogContext)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: AppLocale.emailHint.getString(dialogContext),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              MaterialLocalizations.of(dialogContext).cancelButtonLabel,
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocale.forgotPasswordSentMessage.getString(context),
                  ),
                ),
              );
            },
            child: Text(AppLocale.loginButtonLabel.getString(dialogContext)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 8),
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: AppColors.secondary, width: 6),
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            children: [
              Center(
                child: FloatingBob(
                  amplitude: 6,
                  duration: const Duration(seconds: 2),
                  child: Container(
                    width: 140,
                    height: 140,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryFixed,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1F000000),
                          offset: Offset(0, 8),
                          blurRadius: 24,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/logo_mascota.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppLocale.loginWelcomeTitle.getString(context),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocale.loginSubtitle.getString(context),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                AppLocale.usernameOrEmailLabel.getString(context),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              AuthTextField(
                icon: Icons.person_outline_rounded,
                hint: AppLocale.usernameOrEmailHint.getString(context),
              ),
              const SizedBox(height: 20),
              Text(
                AppLocale.passwordLabel.getString(context),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              AuthTextField(
                icon: Icons.lock_outline_rounded,
                hint: AppLocale.passwordHint.getString(context),
                isPassword: true,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _showForgotPasswordDialog(context),
                  child: Text(
                    AppLocale.forgotPasswordLabel.getString(context),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AuthPrimaryButton(
                label: AppLocale.loginButtonLabel.getString(context),
                onTap: () =>
                    Navigator.of(context).pushReplacementNamed(RoutePaths.home),
              ),
              const SizedBox(height: 24),
              SocialLoginRow(
                onGoogleTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocale.comingSoon.getString(context))),
                ),
                onFacebookTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocale.comingSoon.getString(context))),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    Text(
                      '${AppLocale.noAccountLabel.getString(context)} ',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(
                        context,
                      ).pushReplacementNamed(RoutePaths.register),
                      child: Text(
                        AppLocale.signUpLabel.getString(context),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
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
    );
  }
}
