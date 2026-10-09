import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/l10n.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/models/user_role.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/presentation/widgets/coming_soon.dart';
import '../../auth/presentation/widgets/pill_badge.dart';
import '../../auth/presentation/widgets/surface_card.dart';
import '../../auth/providers/auth_providers.dart';

/// Each language is named in its own script, whichever language the app is
/// showing now, so a person who cannot read the current one can still find theirs.
const Map<String, String> kLanguageNativeNames = {
  'en': 'English',
  'si': 'සිංහල',
};

/// App settings for both customers and vendors: the language choice, which
/// takes effect immediately and is remembered, and the notification and privacy
/// settings, which are not built yet and say so.
class AppSettingsScreen extends ConsumerWidget {
  const AppSettingsScreen({super.key});

  void _back(BuildContext context, WidgetRef ref) {
    if (context.canPop()) {
      context.pop();
      return;
    }

    final role = ref.read(authControllerProvider).session?.role;
    context.go(role == UserRole.vendor ? Routes.vendorProfile : Routes.consumerProfile);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(localeControllerProvider);
    final controller = ref.read(localeControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.l10n.settingsTitle, style: AppTextStyles.title),
        leading: IconButton(
          tooltip: context.l10n.commonBack,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _back(context, ref),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          Text(context.l10n.settingsLanguage, style: AppTextStyles.title.copyWith(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(context.l10n.settingsLanguageHelp, style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: AppSpacing.md),
          SurfaceCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (index, locale) in kSupportedLocales.indexed) ...[
                  if (index > 0) const Divider(height: 1),
                  _LanguageOption(
                    name: kLanguageNativeNames[locale.languageCode] ?? locale.languageCode,
                    selected: locale.languageCode == selected.languageCode,
                    onTap: () => controller.setLocale(locale),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(context.l10n.settingsPreferences, style: AppTextStyles.title.copyWith(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.md),
          SurfaceCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                // Not built: there is no notification-preferences screen or API yet.
                _SoonRow(
                  icon: Icons.notifications_none_rounded,
                  title: context.l10n.settingsNotifications,
                  subtitle: context.l10n.settingsNotificationsSub,
                  onTap: () => showComingSoon(context, context.l10n.settingsFeatureNotifications),
                ),
                const Divider(height: 1),
                // Not built: there are no privacy controls on the server yet.
                _SoonRow(
                  icon: Icons.lock_outline,
                  title: context.l10n.settingsPrivacy,
                  subtitle: context.l10n.settingsPrivacySub,
                  onTap: () => showComingSoon(context, context.l10n.settingsFeaturePrivacy),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({required this.name, required this.selected, required this.onTap});

  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: selected ? context.l10n.settingsLanguageSelected(name) : name,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: AppTextStyles.bodyStrong.copyWith(color: selected ? AppColors.textPrimary : AppColors.textSecondary),
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: selected ? AppColors.secondary : AppColors.border,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoonRow extends StatelessWidget {
  const _SoonRow({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: AppColors.borderLight, borderRadius: BorderRadius.circular(AppRadii.softButton)),
              child: Icon(icon, size: 21, color: AppColors.textSecondary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(title, style: AppTextStyles.bodyStrong),
                      PillBadge(label: context.l10n.commonComingSoonTag, background: AppColors.borderLight, foreground: AppColors.textSecondary),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
