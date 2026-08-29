import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/features/auth/controller/phone_auth_controller.dart';
import 'package:memory_companion/features/auth/util/auth_error_mapper.dart';
import 'package:memory_companion/features/auth/widget/auth_text_field.dart';

/// Shows the phone sign-in dialog: enter a phone number, then the SMS code
/// Firebase sends to it. Pops itself once sign-in succeeds.
Future<void> showPhoneSignInDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _PhoneSignInDialog(),
  );
}

class _PhoneSignInDialog extends ConsumerStatefulWidget {
  const _PhoneSignInDialog();

  @override
  ConsumerState<_PhoneSignInDialog> createState() =>
      _PhoneSignInDialogState();
}

class _PhoneSignInDialogState extends ConsumerState<_PhoneSignInDialog> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    // Safely reset the provider before widget is unmounted
    if (mounted) {
      try {
        ref.read(phoneAuthControllerProvider.notifier).reset();
      } catch (e) {
        // Ignore errors during dispose
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(phoneAuthControllerProvider);
    final isCodeStep = state.step == PhoneAuthStep.codeSent;

    ref.listen(phoneAuthControllerProvider, (previous, next) {
      if (next.step == PhoneAuthStep.verified) {
        Navigator.of(context).pop();
      } else if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authErrorMessage(context, next.errorMessage!)),
          ),
        );
      }
    });

    return AlertDialog(
      backgroundColor: AppColors.surfaceContainerLowest,
      title: Text(AppLocale.phoneSignInTitle.getString(context)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isCodeStep) ...[
            Text(
              AppLocale.codeSentMessage.getString(context),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            AuthTextField(
              icon: Icons.sms_outlined,
              hint: AppLocale.verificationCodeHint.getString(context),
              controller: _codeController,
              keyboardType: TextInputType.number,
              enabled: !state.isLoading,
            ),
          ] else
            AuthTextField(
              icon: Icons.phone_outlined,
              hint: AppLocale.phoneNumberHint.getString(context),
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              enabled: !state.isLoading,
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: state.isLoading
              ? null
              : () {
                  final notifier = ref.read(
                    phoneAuthControllerProvider.notifier,
                  );
                  if (isCodeStep) {
                    notifier.confirmCode(_codeController.text);
                  } else {
                    notifier.sendCode(_phoneController.text);
                  }
                },
          child: state.isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  isCodeStep
                      ? AppLocale.verifyCodeLabel.getString(context)
                      : AppLocale.sendCodeLabel.getString(context),
                ),
        ),
      ],
    );
  }
}
