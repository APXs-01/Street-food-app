import 'package:flutter/material.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/format.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/widgets/pill_badge.dart';
import '../../../auth/presentation/widgets/surface_card.dart';
import '../../data/discovery_stall.dart';
import '../../data/stall_detail_models.dart';
import '../../presentation/widgets/hygiene_pills.dart';
import '../data/vendor_profile_data.dart';

/// Hygiene Breakdown: audit status, who inspected, the 5-point checklist with
/// the inspector's result for each point, and the evidence photo. All of it is
/// the stall's latest inspection from `GET /vendors/{id}/hygiene`.
class HygieneTab extends StatelessWidget {
  const HygieneTab({super.key, required this.stall, required this.hygiene, required this.onReadCommunityLogs});

  final DiscoveryStall stall;
  final HygieneBreakdown hygiene;
  final VoidCallback onReadCommunityLogs;

  @override
  Widget build(BuildContext context) {
    final inspection = hygiene.inspection;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AuditStatusCard(stall: stall, hygiene: hygiene),
        const SizedBox(height: AppSpacing.xl),
        if (inspection == null)
          SurfaceCard(
            child: Column(
              children: [
                const Icon(Icons.fact_check_outlined, size: 32, color: AppColors.textMuted),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  context.l10n.vpNoInspection,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          )
        else ...[
          Row(
            children: [
              Expanded(
                child: Text(context.l10n.vpChecklistTitle, style: AppTextStyles.title.copyWith(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
              Text(
                context.l10n.vpMunicipalStandard,
                style: AppTextStyles.caption.copyWith(color: AppColors.textMuted, letterSpacing: 0.3),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final criterion in orderedCriteria(inspection.criteria)) ...[
            _ChecklistCard(criterion: criterion),
            const SizedBox(height: AppSpacing.md),
          ],
          if (inspection.notes != null && inspection.notes!.trim().isNotEmpty) ...[
            _NotesCard(notes: inspection.notes!.trim()),
            const SizedBox(height: AppSpacing.md),
          ],
          if (inspection.evidenceUrl != null) ...[
            _EvidenceCard(url: inspection.evidenceUrl!),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
        const SizedBox(height: AppSpacing.sm),
        SurfaceCard(
          padding: EdgeInsets.zero,
          child: InkWell(
            onTap: onReadCommunityLogs,
            borderRadius: BorderRadius.circular(AppRadii.card),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  const Icon(Icons.groups_2_outlined, size: 20, color: AppColors.secondary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      context.l10n.vpReadReviews(stall.ratingCount),
                      style: AppTextStyles.bodyStrong,
                    ),
                  ),
                  Text(context.l10n.vpReviewsArrow, style: AppTextStyles.link.copyWith(fontSize: 12, color: AppColors.secondary)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            context.l10n.vpHygieneFooter,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(fontSize: 11, color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }
}

class _AuditStatusCard extends StatelessWidget {
  const _AuditStatusCard({required this.stall, required this.hygiene});

  final DiscoveryStall stall;
  final HygieneBreakdown hygiene;

  @override
  Widget build(BuildContext context) {
    final days = hygiene.daysUntilDue();
    final inspected = hygiene.lastInspectedAt;
    final organization = hygiene.inspection?.organization;

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.vpAuditStatus, style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RatingHygienePill(
                      rating: stall.ratingLabel,
                      caption: hygieneCaption(stall),
                      caution: stall.isCaution,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      inspected == null ? context.l10n.hygieneNotInspected : context.l10n.vpLastInspected(agoFrom(inspected)),
                      style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              if (days != null) ...[
                const SizedBox(width: AppSpacing.sm),
                PillBadge(
                  label: days <= 0 ? context.l10n.vpRecheckDue : context.l10n.vpRecheckIn(days),
                  background: AppColors.amberBg,
                  foreground: AppColors.orangeAccentText,
                  borderColor: AppColors.amber.withValues(alpha: 0.45),
                  leading: const Icon(Icons.schedule, size: 13, color: AppColors.orangeAccentText),
                ),
              ],
            ],
          ),
          if (organization != null && organization.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(AppRadii.softButton)),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.description_outlined, color: AppColors.surface, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(organization, style: AppTextStyles.bodyStrong.copyWith(fontSize: 13)),
                        Text(context.l10n.vpInspectingOrg, style: AppTextStyles.body.copyWith(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChecklistCard extends StatelessWidget {
  const _ChecklistCard({required this.criterion});

  final CriterionResult criterion;

  @override
  Widget build(BuildContext context) {
    final label = checklistLabel(criterion.key);
    final result = criterion.result;
    final clean = result == 'pass';
    final accent = clean ? AppColors.secondary : AppColors.orangeAccentText;

    return SurfaceCard(
      borderColor: clean ? null : AppColors.amber.withValues(alpha: 0.7),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: clean ? AppColors.primaryLight.withValues(alpha: 0.5) : AppColors.amberBg,
              borderRadius: BorderRadius.circular(AppRadii.softButton),
            ),
            child: Icon(label.icon, size: 20, color: accent),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.title, style: AppTextStyles.bodyStrong),
                if (label.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(label.description, style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted)),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          switch (result) {
            'pass' => PillBadge(
                label: context.l10n.hygieneVerifiedClean,
                background: AppColors.successBg,
                foreground: AppColors.successText,
                borderColor: AppColors.successBorder,
                leading: const Icon(Icons.check_circle, size: 13, color: AppColors.secondary),
              ),
            'partial' => PillBadge(
                label: context.l10n.vpResultPartial,
                background: AppColors.amberBg,
                foreground: AppColors.orangeAccentText,
                borderColor: AppColors.orangeAccentBg,
                leading: const Icon(Icons.timelapse, size: 13, color: AppColors.orangeAccentText),
              ),
            _ => PillBadge(
                label: context.l10n.vpResultFail,
                background: AppColors.amberBg,
                foreground: AppColors.orangeAccentText,
                borderColor: AppColors.orangeAccentBg,
                leading: const Icon(Icons.warning_amber_rounded, size: 13, color: AppColors.orangeAccentText),
              ),
          },
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.notes});

  final String notes;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.vpInspectorNotes, style: AppTextStyles.bodyStrong),
          const SizedBox(height: 4),
          Text(notes, style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }
}

/// The inspection's evidence photo (one per inspection, not one per point).
class _EvidenceCard extends StatelessWidget {
  const _EvidenceCard({required this.url});

  final String url;

  void _open(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(AppSpacing.md),
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(
                ApiConfig.resolveMedia(url),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stack) => const SizedBox(
                  height: 200,
                  child: Center(child: Icon(Icons.broken_image_outlined, color: Colors.white70, size: 40)),
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                tooltip: context.l10n.commonClose,
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  ApiConfig.resolveMedia(url),
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => Container(
                    width: 56,
                    height: 56,
                    color: AppColors.borderLight,
                    child: const Icon(Icons.image_not_supported_outlined, color: AppColors.textMuted),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(context.l10n.vpEvidencePhoto, style: AppTextStyles.bodyStrong)),
              Text(context.l10n.vpViewArrow, style: AppTextStyles.link.copyWith(fontSize: 12, color: AppColors.secondary)),
            ],
          ),
        ),
      ),
    );
  }
}
