import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/brand.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/models/user_role.dart';
import '../../../core/router/routes.dart';
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
import 'widgets/inline_link_row.dart';
import 'widgets/pill_badge.dart';
import 'widgets/primary_button.dart';
import 'widgets/surface_card.dart';

class VendorSignupScreen extends ConsumerStatefulWidget {
  const VendorSignupScreen({super.key});

  @override
  ConsumerState<VendorSignupScreen> createState() => _VendorSignupScreenState();
}

class _VendorSignupScreenState extends ConsumerState<VendorSignupScreen> with AuthFormMixin<VendorSignupScreen> {
  static const _nameFields = ['name'];
  static const _identifierFields = ['email', 'phone'];
  static const _passwordFields = ['password'];
  static const _termsFields = ['terms'];

  /// Cosmetic badge from the design; not tied to the app version.
  static const _versionBadge = 'V 2.4';

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
            role: UserRole.vendor,
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
      appBar: const AuthAppBar(
        badge: PillBadge(
          label: _versionBadge,
          background: AppColors.borderLight,
          foreground: AppColors.textSecondary,
        ),
      ),
      body: AuthScrollBody(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PillBadge.eyebrow(context.l10n.authVendorRegistration),
                const SizedBox(width: AppSpacing.sm),
                Text('•', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                const SizedBox(width: AppSpacing.sm),
                PillBadge.orange(context.l10n.authPartner),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(context.l10n.authCreateVendorAccount, style: AppTextStyles.display),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.authVendorSignupSubtitle,
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSpacing.lg),
          const _NextStepCard(),
          const SizedBox(height: AppSpacing.xl),
          Form(
            key: formKey,
            autovalidateMode: autovalidateMode,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    label: context.l10n.authOwnerFullName,
                    isRequired: true,
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
                    isRequired: true,
                    // Only once what is typed is a valid mobile number.
                    labelTrailing: Validators.looksLikeMobile(_identifier.text)
                        ? PillBadge(
                            label: context.l10n.authSmsReady,
                            background: AppColors.successBg,
                            foreground: AppColors.successText,
                            borderColor: AppColors.successBorder,
                            uppercase: true,
                          )
                        : null,
                    controller: _identifier,
                    hint: context.l10n.authHintEmailOrMobileLong,
                    icon: Icons.alternate_email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email, AutofillHints.telephoneNumber],
                    validator: Validators.emailOrMobile,
                    errorText: serverError(_identifierFields),
                    onChanged: (_) {
                      clearServerError(_identifierFields);
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: context.l10n.authFieldPassword,
                    isRequired: true,
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
                    isRequired: true,
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
                    activeColor: AppColors.vendorAccent,
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
                      (text: context.l10n.authAgreeVendorLink, isLink: true),
                      (text: context.l10n.authAgreeVendorPost(kBrandName), isLink: false),
                    ],
                    onLinkTap: (link) => showComingSoon(context, link),
                  ),
                  if (banner != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    ErrorBanner(banner),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  PrimaryButton(
                    label: context.l10n.authCreateVendorAccount,
                    color: AppColors.vendorAccent,
                    isLoading: isSubmitting,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          InlineLinkRow(
            prefix: context.l10n.authAlreadyAccount,
            linkLabel: context.l10n.authLogInArrow,
            onTap: () => context.go(Routes.vendorLogin),
          ),
          InlineLinkRow(
            prefix: context.l10n.authLookingToOrder,
            linkLabel: context.l10n.authSwitchToConsumerSignup,
            linkColor: AppColors.orangeAccentText,
            textStyle: AppTextStyles.body.copyWith(fontSize: 12),
            onTap: () => context.go(Routes.consumerSignup),
          ),
        ],
      ),
    );
  }
}

/// Previews the next screen, stall onboarding, which opens as soon as the
/// account is created. Not a form field.
class _NextStepCard extends StatelessWidget {
  const _NextStepCard();

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      accentColor: AppColors.primary,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AppColors.primaryLight.withValues(alpha: 0.6), shape: BoxShape.circle),
            child: const Icon(Icons.verified, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(context.l10n.authNextStep, style: AppTextStyles.bodyStrong)),
                    const SizedBox(width: AppSpacing.sm),
                    PillBadge.orange(context.l10n.authNextStepTime),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.authNextStepBody,
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
