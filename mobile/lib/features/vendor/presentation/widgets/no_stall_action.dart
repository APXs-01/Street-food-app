import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/api_failure.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// For `AsyncView.errorAction` on the vendor screens: when the failure is "no
/// stall yet", a button that opens stall setup. Any other failure gets nothing
/// extra (it has Try again).
Widget? noStallAction(Object error) {
  if (error is! ApiFailure || error.code != ApiFailure.codeNoStall) return null;

  return Builder(
    builder: (context) => FilledButton(
      onPressed: () => context.go(Routes.vendorOnboarding),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.surface,
        shape: const StadiumBorder(),
        minimumSize: const Size(0, 46),
        padding: const EdgeInsets.symmetric(horizontal: 22),
      ),
      child: Text(context.l10n.vendorSetUpMyStall, style: AppTextStyles.button),
    ),
  );
}
