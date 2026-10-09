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
import 'widgets/inline_link_row.dart';
import 'widgets/pill_badge.dart';
import 'widgets/primary_button.dart';
import 'widgets/surface_card.dart';
import 'widgets/switch_banner.dart';

class VendorLoginScreen extends ConsumerStatefulWidget {
  const VendorLoginScreen({super.key});

  @override
  ConsumerState<VendorLoginScreen> createState() => _VendorLoginScreenState();
}

class _VendorLoginScreenState extends ConsumerState<VendorLoginScreen> with AuthFormMixin<VendorLoginScreen> {
  static const _identifierFields = ['login'];

  final _identifier = TextEditingController();
  final _password = TextEditingController();

  bool _staySignedIn = true;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() {
    return submitForm(
      () => ref.read(authControllerProvider.notifier).login(
            role: UserRole.vendor,
            identifier: _identifier.text,
            password: _password.text,
            staySignedIn: _staySignedIn,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(authControllerProvider.select((state) => state.isSubmitting));
    final banner = bannerMessage;

    return Scaffold(
      appBar: AuthAppBar(
        badge: PillBadge.orange(context.l10n.authVendorPortal),
        trailing: IconButton(
          tooltip: context.l10n.commonHelp,
          icon: const Icon(Icons.help_outline, color: AppColors.textSecondary),
          onPressed: () => showComingSoon(context, context.l10n.commonHelp),
        ),
      ),
      body: AuthScrollBody(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: PillBadge.eyebrow(context.l10n.authVendorEyebrow),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(context.l10n.authVendorLoginTitle, style: AppTextStyles.display.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.authVendorLoginSubtitle,
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSpacing.lg),
          const _TrustCard(),
          const SizedBox(height: AppSpacing.lg),
          SurfaceCard(
            child: Form(
              key: formKey,
              autovalidateMode: autovalidateMode,
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      label: context.l10n.authFieldOwnerContact,
                      controller: _identifier,
                      hint: context.l10n.authHintOwnerContact,
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.username],
                      validator: Validators.emailOrMobile,
                      errorText: serverError(_identifierFields),
                      onChanged: (_) => clearServerError(_identifierFields),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      label: context.l10n.authFieldVendorPassword,
                      controller: _password,
                      hint: context.l10n.authHintVendorPassword,
                      icon: Icons.lock_outline,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      validator: Validators.password,
                      onFieldSubmitted: (_) => isSubmitting ? null : _submit(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _staySignedIn,
                            onChanged: (checked) => setState(() => _staySignedIn = checked ?? false),
                            activeColor: AppColors.primary,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            side: const BorderSide(color: AppColors.border, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(context.l10n.authStaySignedIn, style: AppTextStyles.body.copyWith(fontSize: 13)),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => showComingSoon(context, context.l10n.authFeaturePasswordReset),
                              child: Text(
                                context.l10n.authForgotVendorPin,
                                textAlign: TextAlign.right,
                                style: AppTextStyles.link.copyWith(fontSize: 12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (banner != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      ErrorBanner(banner),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    PrimaryButton(
                      label: context.l10n.authVendorLogIn,
                      isLoading: isSubmitting,
                      onPressed: _submit,
                    ),
                    const Padding(padding: EdgeInsets.symmetric(vertical: AppSpacing.lg), child: Divider()),
                    const _OtpButton(),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          InlineLinkRow(
            prefix: context.l10n.authNewStallOwner,
            linkLabel: context.l10n.authCreateVendorAccount,
            onTap: () => context.go(Routes.vendorSignup),
          ),
          const SizedBox(height: AppSpacing.md),
          SwitchBanner(
            white: true,
            icon: Icons.person_outline,
            iconBackground: AppColors.orangeAccentBg,
            iconColor: AppColors.orangeAccentText,
            eyebrow: context.l10n.authAreYouCustomer,
            text: context.l10n.authSwitchToCustomerLogin,
            onTap: () => context.go(Routes.consumerLogin),
          ),
          const SizedBox(height: AppSpacing.xl),
          const _FooterLinks(),
        ],
      ),
    );
  }
}

class _TrustCard extends StatelessWidget {
  const _TrustCard();

  @override
  Widget build(BuildContext context) {
    // A white pill with a peach icon circle.
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, AppSpacing.lg, 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppShadows.cardBorder),
        boxShadow: const [AppShadows.card],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(color: AppColors.orangeAccentBg, shape: BoxShape.circle),
            child: const Icon(Icons.storefront_outlined, size: 18, color: AppColors.orangeAccentText),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              context.l10n.authTrustCard,
              style: AppTextStyles.bodyStrong.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Send One-Time Passcode via SMS". The backend has no OTP endpoint, so this is
/// a visible stub that says so instead of doing anything.
class _OtpButton extends StatelessWidget {
  const _OtpButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: FilledButton.icon(
        onPressed: () => showComingSoon(context, context.l10n.authFeatureSmsOtp),
        icon: const Icon(Icons.sms_outlined, size: 18),
        label: Text(context.l10n.authSendOtp, style: AppTextStyles.bodyStrong.copyWith(fontSize: 13)),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.borderLight,
          foregroundColor: AppColors.textSecondary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.softButton)),
          elevation: 0,
        ),
      ),
    );
  }
}

class _FooterLinks extends StatelessWidget {
  const _FooterLinks();

  @override
  Widget build(BuildContext context) {
    final links = [context.l10n.authFooterPrivacy, context.l10n.authFooterGuidelines, context.l10n.authFooterEmergency];
    final style = AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted);

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < links.length; i++) ...[
          if (i > 0) Text('·', style: style),
          InkWell(
            onTap: () => showComingSoon(context, links[i]),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
              child: Text(links[i], style: style),
            ),
          ),
        ],
      ],
    );
  }
}
