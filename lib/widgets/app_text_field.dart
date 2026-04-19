import 'package:fluffychat/config/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// App-wide custom text field. Use consistently across login, forms, etc.
class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final String? errorText;
  final bool obscureText;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final void Function(String)? onChanged;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextDirection? textDirection;
  final bool autocorrect;
  final bool autofocus;
  final FocusNode? focusNode;
  final List<String>? autofillHints;
  final TextAlign textAlign;
  final int? maxLines;
  final int? minLines;
  final List<TextInputFormatter>? inputFormatters;
  final TextStyle? style;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.errorText,
    this.obscureText = false,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
    this.onChanged,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.readOnly = false,
    this.onTap,
    this.textDirection,
    this.autocorrect = false,
    this.autofocus = false,
    this.focusNode,
    this.autofillHints,
    this.textAlign = TextAlign.right,
    this.maxLines = 1,
    this.minLines,
    this.inputFormatters,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fillColor = theme.brightness == Brightness.dark
        ? colorScheme.surfaceContainerHigh
        : colorScheme.surfaceContainerLow;

    return TextFormField(
      onTapOutside: (event) {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      controller: controller,
      focusNode: focusNode,
      readOnly: readOnly,
      onTap: onTap,
      obscureText: obscureText,
      validator: validator,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      onChanged: onChanged,
      keyboardType: keyboardType,
      textDirection: textDirection,
      textAlign: textAlign,
      autocorrect: autocorrect,
      autofocus: autofocus,
      autofillHints: autofillHints,
      maxLines: maxLines,
      minLines: minLines,
      inputFormatters: inputFormatters,
      style:
          style ??
          TextStyle(
            color: colorScheme.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        errorText: errorText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColor.sGoldenWheat3),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColor.sGoldenWheat3, width: 2),
        ),
      ),
    );
  }
}
