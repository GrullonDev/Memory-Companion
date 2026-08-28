import 'package:flutter/material.dart';

import 'package:memory_companion/core/theme/app_colors.dart';

/// Rounded, outlined text field shared by the login and register screens.
class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.icon,
    required this.hint,
    this.controller,
    this.isPassword = false,
    this.keyboardType,
    this.enabled = true,
  });

  final IconData icon;
  final String hint;
  final TextEditingController? controller;
  final bool isPassword;
  final TextInputType? keyboardType;
  final bool enabled;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      enabled: widget.enabled,
      obscureText: widget.isPassword && _obscured,
      keyboardType: widget.keyboardType,
      style: Theme.of(
        context,
      ).textTheme.bodyLarge?.copyWith(color: AppColors.onSurface),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: AppColors.outline),
        prefixIcon: Icon(widget.icon, color: AppColors.outline),
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.outline,
                ),
                onPressed: () => setState(() => _obscured = !_obscured),
              )
            : null,
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.secondaryContainer,
            width: 2,
          ),
        ),
      ),
    );
  }
}
