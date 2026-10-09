import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/l10n.dart';
import '../../../core/models/user_role.dart';import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/auth_providers.dart';
import 'auth_form_mixin.dart';
import 'validators.dart';
import 'widgets/agreement_checkbox.dart';
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
import 'widgets/surface_card.dart';

class ConsumerSignupScreen extends ConsumerStatefulWidget {
  const ConsumerSignupScreen({super.key});

  @override
  ConsumerState<ConsumerSignupScreen> createState() => _ConsumerSignupScreenState();
}

class _ConsumerSignupScreenState extends ConsumerState<ConsumerSignupScreen> with AuthFormMixin<ConsumerSignupScreen> {
  static const _nameFields = ['name'];
  static const _identifierFields = ['email', 'phone'];
  static const _passwordFields = ['password'];
  static const _termsFields = ['terms'];

  final _name = TextEditingController();
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _acceptedTerms = false;
  String? _termsError;

  @override
  void dispose() {
    _name.dispose();
    _identifier.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  bool _validateTerms() {
    setState(() => _termsError = _acceptedTerms ? null : context.l10n.authTermsRequired);

    return _acceptedTerms;
  }

  Future<void> _submit() {
    return submitForm(
      () => ref.read(authControllerProvider.notifier).register(
            role: UserRole.consumer,
            name: _name.text,
            identifier: _identifier.text,
            password: _password.text,
            passwordConfirmation: _confirmPassword.text,
            acceptedTerms: _acceptedTerms,
          ),
      extraValidation: _validateTerms,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(authControllerProvider.select((state) => state.isSubmitting));
    final banner = bannerMessage;

    return Scaffold(
      appBar: AuthAppBar(
        showShield: true,
        trailing: IconButton(
          tooltip: context.l10n.commonHelp,
          icon: const Icon(Icons.help_outline, color: AppColors.textSecondary),
          onPressed: () => showComingSoon(context, context.l10n.commonHelp),
        ),
      ),
      body: AuthScrollBody(
        children: [
          Align(
            child: PillBadge(
              label: context.l10n.authSignupFreeBadge,
              background: AppColors.successBg,
              foreground: AppColors.successText,
              borderColor: AppColors.successBorder,
              uppercase: true,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(context.l10n.authCreateAccount, textAlign: TextAlign.center, style: AppTextStyles.headline),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.authSignupSubtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSpacing.xl),
          SurfaceCard(
            child: Form(
              key: formKey,
              autovalidateMode: autovalidateMode,
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      label: context.l10n.authFieldFullName,
                      controller: _name,
                      hint: context.l10n.authHintFullName,
                      icon: Icons.person_outline,
                      keyboardType: TextInputType.name,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                      validator: Validators.fullName,
                      errorText: serverError(_nameFields),
                      onChanged: (_) => clearServerError(_nameFields),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      label: context.l10n.authFieldEmailOrMobile,
                      controller: _identifier,
                      hint: context.l10n.authHintEmailOrMobileShort,
                      icon: Icons.alternate_email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email, AutofillHints.telephoneNumber],
                      validator: Validators.emailOrMobile,
                      errorText: serverError(_identifierFields),
                      onChanged: (_) => clearServerError(_identifierFields),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      label: context.l10n.authFieldPassword,
                      controller: _password,
                      hint: context.l10n.authHintPasswordMin,
                      icon: Icons.lock_outline,
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      validator: Validators.newPassword,
                      errorText: serverError(_passwordFields),
                      onChanged: (_) => clearServerError(_passwordFields),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      label: context.l10n.authFieldConfirmPassword,
                      controller: _confirmPassword,
                      hint: context.l10n.authHintConfirmPassword,
                      icon: Icons.shield_outlined,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.newPassword],
                      validator: (value) => Validators.confirmPassword(value, _password.text),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AgreementCheckbox(
                      value: _acceptedTerms,
                      onChanged: (checked) {
                        setState(() {
                          _acceptedTerms = checked;
                          _termsError = null;
                        });
                        clearServerError(_termsFields);
                      },
                      errorText: _termsError ?? serverError(_termsFields),
                      segments: [
                        (text: context.l10n.authAgreePre, isLink: false),
                        (text: context.l10n.authAgreeTerms, isLink: true),
                        (text: context.l10n.authAgreeAnd, isLink: false),
                        (text: context.l10n.authAgreeGuidelines, isLink: true),
                        if (context.l10n.authAgreePost.isNotEmpty) (text: context.l10n.authAgreePost, isLink: false),
                      ],
                      onLinkTap: (link) => showComingSoon(context, link),
                    ),
                    if (banner != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      ErrorBanner(banner),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    PrimaryButton(
                      label: context.l10n.authCreateAccount,
                      trailingIcon: Icons.how_to_reg,
                      isLoading: isSubmitting,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    OrDivider(context.l10n.authOrSignUpWith),
                    const SizedBox(height: AppSpacing.lg),
                    const GoogleButton(),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _CertifiedCard(),
          const SizedBox(height: AppSpacing.lg),
          InlineLinkRow(
            prefix: context.l10n.authAlreadyAccount,
            linkLabel: context.l10n.authLogInArrow,
            onTap: () => context.go(Routes.consumerLogin),
          ),
        ],
      ),
    );
  }
}

class _CertifiedCard extends StatelessWidget {
  const _CertifiedCard();

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      color: AppColors.borderLight.withValues(alpha: 0.6),
      borderColor: Colors.transparent,
      shadow: false,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AppColors.primaryLight.withValues(alpha: 0.6), shape: BoxShape.circle),
            child: const Icon(Icons.verified_outlined, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.authCertifiedTitle, style: AppTextStyles.bodyStrong),
                const SizedBox(height: 2),
                Text(
                  context.l10n.authCertifiedBody,
                  style: AppTextStyles.body.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
