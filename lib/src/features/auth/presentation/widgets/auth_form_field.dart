import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// A styled, reusable form field for authentication screens.
///
/// Wraps [TextFormField] with consistent styling, optional
/// password visibility toggle, and prefix icon support.
class AuthFormField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final bool enabled;

  const AuthFormField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onFieldSubmitted,
    this.enabled = true,
  });

  @override
  State<AuthFormField> createState() => _AuthFormFieldState();
}

class _AuthFormFieldState extends State<AuthFormField> {
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      style: const TextStyle(color: AppColors.onSurface),
      obscureText: _isObscured,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      onFieldSubmitted: widget.onFieldSubmitted,
      enabled: widget.enabled,
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: const TextStyle(color: AppColors.onSurfaceVariant),
        hintText: widget.hint,
        hintStyle: TextStyle(
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
        ),
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, color: AppColors.outline)
            : null,
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(
                  _isObscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _isObscured = !_isObscured;
                  });
                },
              )
            : null,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
