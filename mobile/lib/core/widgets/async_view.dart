import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/json.dart';
import '../localization/l10n.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Shows an [AsyncValue] honestly: a spinner while it loads, the server's message
/// with a Retry button when it fails, and [builder] when there is data.
///
/// While a refresh is running over data we already have, the data stays on
/// screen instead of flashing back to a spinner.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.value,
    required this.builder,
    this.onRetry,
    this.loading,
    this.compact = false,
    this.errorAction,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;

  /// An extra button for a particular failure (for example "Set up your stall"),
  /// given the error; null for none.
  final Widget? Function(Object error)? errorAction;

  /// Replaces the default spinner.
  final Widget? loading;

  /// Smaller padding, for use inside a card or a section.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final data = value.asData;
    if (data != null) return builder(data.value);

    if (value.hasError) {
      return _Problem(
        message: errorMessage(value.error!),
        onRetry: onRetry,
        compact: compact,
        action: errorAction?.call(value.error!),
      );
    }

    return loading ??
        Padding(
          padding: EdgeInsets.all(compact ? AppSpacing.lg : AppSpacing.xxl),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary)),
        );
  }
}

class _Problem extends StatelessWidget {
  const _Problem({required this.message, required this.onRetry, required this.compact, this.action});

  final String message;
  final VoidCallback? onRetry;
  final bool compact;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(compact ? AppSpacing.lg : AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 32, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.sm),
          Text(message, textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(context.l10n.commonTryAgain, style: AppTextStyles.link),
            ),
          ],
          if (action != null) ...[const SizedBox(height: AppSpacing.sm), action!],
        ],
      ),
    );
  }
}

/// A short line for an empty list: "No reviews yet."
class EmptyNote extends StatelessWidget {
  const EmptyNote(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Text(message, textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
    );
  }
}
