import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// One piece of the sentence beside a checkbox; links are set bold green.
typedef AgreementSegment = ({String text, bool isLink});

/// A checkbox with a sentence that contains tappable links, and an error line
/// underneath. The destinations of the links are not built yet, so [onLinkTap]
/// only says so.
class AgreementCheckbox extends StatefulWidget {
  const AgreementCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.segments,
    required this.onLinkTap,
    this.errorText,
    this.activeColor = AppColors.primary,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final List<AgreementSegment> segments;
  final ValueChanged<String> onLinkTap;
  final String? errorText;
  final Color activeColor;

  @override
  State<AgreementCheckbox> createState() => _AgreementCheckboxState();
}

class _AgreementCheckboxState extends State<AgreementCheckbox> {
  // One recogniser per link, created once and disposed with the widget.
  late final List<TapGestureRecognizer> _recognizers = [
    for (final segment in widget.segments)
      if (segment.isLink) TapGestureRecognizer()..onTap = () => widget.onLinkTap(segment.text),
  ];

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var linkIndex = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: widget.value,
                onChanged: (checked) => widget.onChanged(checked ?? false),
                activeColor: widget.activeColor,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                side: BorderSide(
                  color: widget.errorText == null ? AppColors.border : AppColors.error,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: AppTextStyles.body.copyWith(fontSize: 13),
                  children: [
                    for (final segment in widget.segments)
                      TextSpan(
                        text: segment.text,
                        style: segment.isLink ? AppTextStyles.link : null,
                        recognizer: segment.isLink ? _recognizers[linkIndex++] : null,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs, left: 34),
            child: Text(
              widget.errorText!,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.error,
                letterSpacing: 0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
