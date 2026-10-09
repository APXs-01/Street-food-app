import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// A labelled text field: label above, icon inside on the left, and an eye
/// toggle when [obscureText] is set.
///
/// [validator] is the client-side check. [errorText] carries a message from the
/// server; the caller clears it when the person edits the field, and the
/// validator's message wins while both are present.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
    this.icon,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.obscureText = false,
    this.isRequired = false,
    this.labelTrailing,
    this.errorText,
    this.onChanged,
    this.onFieldSubmitted,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
  });

  final String label;
  final TextEditingController controller;
  final String hint;

  /// Omit for a field with no icon, such as a multi-line text area.
  final IconData? icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool obscureText;

  /// Adds the red asterisk after the label.
  final bool isRequired;

  /// A small widget beside the label, such as the "SMS Ready" badge.
  final Widget? labelTrailing;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final bool enabled;

  /// More than 1 makes a text area. Ignored for password fields.
  final int maxLines;
  final int? minLines;

  /// Limits the text and shows a live "142/200" counter under the field.
  final int? maxLength;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured = widget.obscureText;

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.input),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = AppTextStyles.label;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            children: [
              Flexible(
                child: Text.rich(
                  TextSpan(
                    text: widget.label,
                    style: labelStyle,
                    children: [
                      if (widget.isRequired)
                        TextSpan(text: ' *', style: labelStyle.copyWith(color: AppColors.error)),
                    ],
                  ),
                ),
              ),
              if (widget.labelTrailing != null) ...[
                const SizedBox(width: AppSpacing.sm),
                widget.labelTrailing!,
              ],
            ],
          ),
        ),
        TextFormField(
          controller: widget.controller,
          enabled: widget.enabled,
          obscureText: _obscured,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          minLines: widget.obscureText ? null : widget.minLines,
          maxLength: widget.maxLength,
          enableSuggestions: !widget.obscureText,
          autocorrect: !widget.obscureText,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          autofillHints: widget.autofillHints,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onFieldSubmitted,
          style: AppTextStyles.input,
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: AppTextStyles.hint,
            errorText: widget.errorText,
            errorMaxLines: 3,
            errorStyle: AppTextStyles.caption.copyWith(
              color: AppColors.error,
              letterSpacing: 0,
              fontWeight: FontWeight.w600,
            ),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 16),
            counterStyle: AppTextStyles.caption.copyWith(
              color: AppColors.textMuted,
              letterSpacing: 0,
              fontWeight: FontWeight.w600,
            ),
            prefixIcon: widget.icon == null ? null : Icon(widget.icon, size: 20, color: AppColors.textMuted),
            prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            suffixIcon: widget.obscureText
                ? IconButton(
                    tooltip: _obscured ? context.l10n.commonShowPassword : context.l10n.commonHidePassword,
                    icon: Icon(
                      _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () => setState(() => _obscured = !_obscured),
                  )
                : null,
            border: _border(AppColors.border.withValues(alpha: 0.65)),
            enabledBorder: _border(AppColors.border.withValues(alpha: 0.65)),
            disabledBorder: _border(AppColors.borderLight),
            focusedBorder: _border(AppColors.primary, width: 1.5),
            errorBorder: _border(AppColors.error),
            focusedErrorBorder: _border(AppColors.error, width: 1.5),
          ),
        ),
      ],
    );
  }
}
