import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// The scrolling column every auth screen uses: safe area, 16px side padding,
/// and a maximum width so it does not stretch across a tablet.
class AuthScrollBody extends StatelessWidget {
  const AuthScrollBody({super.key, required this.children, this.topPadding = AppSpacing.sm});

  final List<Widget> children;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(AppSpacing.screenPadding, topPadding, AppSpacing.screenPadding, AppSpacing.xxl),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
          ),
        ),
      ),
    );
  }
}
