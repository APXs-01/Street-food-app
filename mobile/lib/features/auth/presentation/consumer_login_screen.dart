import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/l10n.dart';
import '../../../core/models/user_role.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/auth_providers.dart';
import 'auth_form_mixin.dart';
import 'validators.dart';
import 'widgets/app_text_field.dart';
import 'widgets/auth_app_bar.dart';
import 'widgets/auth_scroll_body.dart';
import 'widgets/coming_soon.dart';
import 'widgets/error_banner.dart';
import 'widgets/google_button.dart';
import 'widgets/inline_link_row.dart';
import 'widgets/or_divider.dart';
import 'widgets/pill_badge.dart';
import 'widgets/primary_button.dart';
import 'widgets/switch_banner.dart';

class ConsumerLoginScreen extends ConsumerStatefulWidget {
  const ConsumerLoginScreen({super.key});

  @override
  ConsumerState<ConsumerLoginScreen> createState() => _ConsumerLoginScreenState();
}

class _ConsumerLoginScreenState extends ConsumerState<ConsumerLoginScreen> with AuthFormMixin<ConsumerLoginScreen> {
  static const _identifierFields = ['login'];

  final _identifier = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() {
    return submitForm(
      () => ref.read(authControllerProvider.notifier).login(
            role: UserRole.consumer,
            identifier: _identifier.text,
            password: _password.text,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(authControllerProvider.select((state) => state.isSubmitting));
    final banner = bannerMessage;

    return Scaffold(
      appBar: const AuthAppBar(),
      body: AuthScrollBody(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: PillBadge(
              label: context.l10n.authConsumerLoginBadge,
              background: AppColors.successBg,
              foreground: AppColors.successText,
              borderColor: AppColors.successBorder,
              leading: const Icon(Icons.verified_user, size: 13, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(context.l10n.authConsumerLoginTitle, style: AppTextStyles.display),
          const SizedBox(height: AppSpacing.sm),
          Text(context.l10n.authConsumerLoginSubtitle, style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.xl),
          Form(
            key: formKey,
            autovalidateMode: autovalidateMode,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    label: context.l10n.authFieldEmailOrMobile,
                    controller: _identifier,
                    hint: context.l10n.authHintEmailOrMobile,
                    icon: Icons.person_outline,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.username],
                    validator: Validators.emailOrMobile,
                    errorText: serverError(_identifierFields),
                    onChanged: (_) => clearServerError(_identifierFields),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: context.l10n.authFieldPassword,
                    controller: _password,
                    hint: context.l10n.authHintPassword,
                    icon: Icons.lock_outline,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    validator: Validators.password,
                    onFieldSubmitted: (_) => isSubmitting ? null : _submit(),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => showComingSoon(context, context.l10n.authFeaturePasswordReset),
              child: Text(context.l10n.authForgotPassword, style: AppTextStyles.link),
            ),
          ),
          if (banner != null) ...[
            ErrorBanner(banner),
            const SizedBox(height: AppSpacing.lg),
          ],
          PrimaryButton(label: context.l10n.authLogIn, isLoading: isSubmitting, onPressed: _submit),
          const SizedBox(height: AppSpacing.xl),
          OrDivider(context.l10n.authOrContinueWith),
          const SizedBox(height: AppSpacing.lg),
          const GoogleButton(),
          const SizedBox(height: AppSpacing.lg),
          InlineLinkRow(
            prefix: context.l10n.authNoAccount,
            linkLabel: context.l10n.authSignUp,
            onTap: () => context.go(Routes.consumerSignup),
          ),
          const SizedBox(height: AppSpacing.md),
          SwitchBanner(
            icon: Icons.storefront,
            eyebrow: context.l10n.authVendorPortal,
            text: context.l10n.authAreYouVendor,
            onTap: () => context.go(Routes.vendorLogin),
          ),
        ],
      ),
    );
  }
}
