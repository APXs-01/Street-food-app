import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// "Don't have an account? Sign Up": plain text followed by a bold link.
class InlineLinkRow extends StatelessWidget {
  const InlineLinkRow({
    super.key,
    required this.prefix,
    required this.linkLabel,
    required this.onTap,
    this.linkColor = AppColors.primary,
    this.textStyle,
  });

  final String prefix;
  final String linkLabel;
  final VoidCallback onTap;
  final Color linkColor;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final style = textStyle ?? AppTextStyles.body;

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('$prefix ', style: style),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
            child: Text(linkLabel, style: style.copyWith(color: linkColor, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}
