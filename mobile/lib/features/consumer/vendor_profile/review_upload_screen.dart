import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/json.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/async_view.dart';
import '../../auth/presentation/widgets/pill_badge.dart';
import '../../auth/presentation/widgets/primary_button.dart';
import '../../auth/presentation/widgets/surface_card.dart';
import '../../vendor/onboarding/data/onboarding_draft.dart';
import '../../vendor/onboarding/data/photo_picker_service.dart';
import '../../vendor/onboarding/presentation/widgets/dashed_border.dart';
import '../../vendor/onboarding/providers/onboarding_providers.dart';
import '../data/discovery_stall.dart';
import '../presentation/widgets/photo_source_sheet.dart';
import '../providers/discovery_providers.dart';
import 'data/vendor_profile_data.dart';
import 'widgets/frosted.dart';

/// A hygiene observation the reviewer can tick.
class _Observation {
  const _Observation(this.key, this.icon);

  /// The API's key; the label comes from [reviewObservationLabel].
  final String key;
  final IconData icon;

  String get label => reviewObservationLabel(key);
}

/// "Leave a Review": a photo with its time, a star rating, hygiene observations
/// and written feedback, sent to `POST /vendors/{id}/reviews`. Opened from the
/// vendor profile as a full-screen modal.
///
/// The photo is optional, as it is on the backend; the rating is required. If
/// the customer already reviewed this stall the server updates that review.
class ReviewUploadScreen extends ConsumerStatefulWidget {
  const ReviewUploadScreen({super.key, required this.stallId});

  final int stallId;

  @override
  ConsumerState<ReviewUploadScreen> createState() => _ReviewUploadScreenState();
}

class _ReviewUploadScreenState extends ConsumerState<ReviewUploadScreen> {
  /// The API's limit on a comment.
  static const _maxFeedback = 500;

  static const _observations = [
    _Observation('clean_area', Icons.cleaning_services_outlined),
    _Observation('gloves_worn', Icons.clean_hands_outlined),
    _Observation('covered_waste_bin', Icons.delete_outline),
    _Observation('clean_water', Icons.water_drop_outlined),
    _Observation('covered_food', Icons.takeout_dining_outlined),
  ];

  String _ratingLabel(int rating) => switch (rating) {
        1 => l10n.ruRating1,
        2 => l10n.ruRating2,
        3 => l10n.ruRating3,
        4 => l10n.ruRating4,
        5 => l10n.ruRating5,
        _ => l10n.ruRatingNone,
      };

  final _feedback = TextEditingController();

  int _rating = 0;
  // Nothing is ticked to begin with: a tick is a claim about what the reviewer saw.
  final Set<String> _observed = {};
  bool _anonymous = false;
  String? _photoPath;
  DateTime? _capturedAt;
  String? _photoProblem;
  String? _submitProblem;
  bool _submitting = false;

  @override
  void dispose() {
    _feedback.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final source = await showPhotoSourceSheet(context);
    if (source == null || !mounted) return;

    setState(() => _photoProblem = null);

    try {
      final path = await ref.read(photoPickerProvider).pick(source);
      if (path == null || !mounted) return;

      // The time is noted when the photo is taken or chosen. The upload sends no
      // capture time or place of its own, so the server stamps it on arrival.
      setState(() {
        _photoPath = path;
        _capturedAt = DateTime.now();
      });
    } on PhotoPickException catch (problem) {
      if (mounted) setState(() => _photoProblem = problem.message);
    }
  }

  Future<void> _submit(String stallName) async {
    if (_rating == 0 || _submitting) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _submitProblem = null;
    });

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    try {
      await ref.read(stallRepositoryProvider).submitReview(
            vendorId: widget.stallId,
            rating: _rating,
            comment: _feedback.text,
            observations: [
              for (final observation in _observations)
                if (_observed.contains(observation.key)) observation.key,
            ],
            photoPaths: [?_photoPath],
            anonymous: _anonymous,
          );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _submitting = false;
        _submitProblem = errorMessage(error);
      });
      return;
    }

    // The stall's rating, review list and the lists that show stars have changed.
    ref.invalidate(stallReviewsProvider);
    ref.invalidate(stallDetailProvider(widget.stallId));
    ref.invalidate(allStallsProvider);

    if (!mounted) return;

    if (router.canPop()) {
      router.pop();
    } else {
      router.go(Routes.consumerHome);
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.ruThanks(stallName))));
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(stallDetailProvider(widget.stallId));
    final stall = detail.asData?.value;

    if (stall == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          leading: IconButton(tooltip: context.l10n.commonClose, icon: const Icon(Icons.close), onPressed: () => context.pop()),
        ),
        body: Center(
          child: SingleChildScrollView(
            child: AsyncView<DiscoveryStall>(
              value: detail,
              onRetry: () => ref.invalidate(stallDetailProvider(widget.stallId)),
              builder: (_) => const SizedBox.shrink(),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(stallName: stall.name, stallNumber: stall.stallNumberLabel, onClose: () => context.pop()),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.sm, AppSpacing.screenPadding, AppSpacing.xl),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _photoCard(),
                        const SizedBox(height: AppSpacing.lg),
                        _ratingCard(),
                        const SizedBox(height: AppSpacing.lg),
                        _observationsCard(),
                        const SizedBox(height: AppSpacing.lg),
                        _feedbackCard(),
                        if (_submitProblem != null) ...[
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            _submitProblem!,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyStrong.copyWith(fontSize: 13, color: AppColors.error),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        const _CommunityNote(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.4))),
              ),
              padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.md, AppSpacing.screenPadding, AppSpacing.md),
              child: Center(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
                  child: PrimaryButton(
                    label: context.l10n.ruSubmit,
                    trailingIcon: Icons.send_rounded,
                    enabled: _rating > 0,
                    isLoading: _submitting,
                    onPressed: () => _submit(stall.name),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- cards -----------------------------------------------------------

  Widget _photoCard() {
    final path = _photoPath;
    final capturedAt = _capturedAt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DashedBorder(
          color: AppColors.primary,
          radius: AppRadii.card,
          child: Material(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadii.card),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.softButton),
                    child: SizedBox(
                      height: 224,
                      width: double.infinity,
                      child: InkWell(
                        onTap: _pickPhoto,
                        child: path == null
                            ? Container(
                                color: AppColors.borderLight,
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.photo_camera_outlined, size: 44, color: AppColors.primary),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(context.l10n.ruTapPhoto, style: AppTextStyles.bodyStrong),
                                    const SizedBox(height: 2),
                                    Text(
                                      context.l10n.ruPhotoOptional,
                                      style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              )
                            : Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(
                                    File(path),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stack) => Container(
                                      color: AppColors.borderLight,
                                      alignment: Alignment.center,
                                      child: const Icon(Icons.broken_image_outlined, size: 40, color: AppColors.textMuted),
                                    ),
                                  ),
                                  Positioned(
                                    top: AppSpacing.md,
                                    right: AppSpacing.md,
                                    child: GestureDetector(
                                      onTap: _pickPhoto,
                                      child: Frosted(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.photo_camera_outlined, size: 14, color: AppColors.textPrimary),
                                            const SizedBox(width: 6),
                                            Text(context.l10n.ruRetake, style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary, letterSpacing: 0.2)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (capturedAt != null)
                                    Positioned(
                                      left: AppSpacing.md,
                                      right: AppSpacing.md,
                                      bottom: AppSpacing.md,
                                      child: _StampOverlay(capturedAt: capturedAt),
                                    ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.verified_user, size: 14, color: AppColors.secondary),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          context.l10n.ruPhotoHelp,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body.copyWith(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_photoProblem != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              _photoProblem!,
              style: AppTextStyles.caption.copyWith(color: AppColors.error, letterSpacing: 0, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }

  Widget _ratingCard() {
    return SurfaceCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(context.l10n.ruOverall, style: AppTextStyles.label.copyWith(fontSize: 14))),
              PillBadge(
                label: '${_rating.toStringAsFixed(1)} / 5.0',
                background: AppColors.successBg,
                foreground: AppColors.successText,
                borderColor: AppColors.successBorder,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var star = 1; star <= 5; star++)
                Semantics(
                  button: true,
                  selected: star <= _rating,
                  label: context.l10n.ruStars(star),
                  child: IconButton(
                    iconSize: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    onPressed: () => setState(() => _rating = star),
                    icon: Icon(
                      star <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: star <= _rating ? AppColors.amber : AppColors.border,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _ratingLabel(_rating),
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyStrong.copyWith(color: _rating == 0 ? AppColors.textMuted : AppColors.secondary),
          ),
        ],
      ),
    );
  }

  Widget _observationsCard() {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.checklist, size: 20, color: AppColors.secondary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(context.l10n.ruObservationsTitle, style: AppTextStyles.label.copyWith(fontSize: 14))),
              Text(context.l10n.ruTapToToggle, style: AppTextStyles.caption.copyWith(color: AppColors.textMuted, letterSpacing: 0.2)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.ruObservationsHelp,
            style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final observation in _observations)
                _ObservationChip(
                  observation: observation,
                  selected: _observed.contains(observation.key),
                  onTap: () => setState(() {
                    if (!_observed.remove(observation.key)) _observed.add(observation.key);
                  }),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _feedbackCard() {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(context.l10n.ruFeedbackTitle, style: AppTextStyles.label.copyWith(fontSize: 14))),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _feedback,
                builder: (context, value, _) => Text(
                  '${value.text.length}/$_maxFeedback',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textMuted, letterSpacing: 0),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _feedback,
            minLines: 4,
            maxLines: 6,
            maxLength: _maxFeedback,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            cursorColor: AppColors.primary,
            style: AppTextStyles.input,
            // The counter above is the live one; hide the field's own.
            buildCounter: (context, {required currentLength, required isFocused, required maxLength}) => null,
            decoration: InputDecoration(
              hintText: context.l10n.ruFeedbackHint,
              hintStyle: AppTextStyles.hint,
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.all(AppSpacing.lg),
              border: _border(AppColors.border.withValues(alpha: 0.7)),
              enabledBorder: _border(AppColors.border.withValues(alpha: 0.7)),
              focusedBorder: _border(AppColors.primary, width: 1.5),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.ruAnonymous,
                  style: AppTextStyles.bodyStrong.copyWith(fontSize: 13),
                ),
              ),
              Switch(
                value: _anonymous,
                activeTrackColor: AppColors.secondary,
                activeThumbColor: AppColors.surface,
                onChanged: (value) => setState(() => _anonymous = value),
              ),
            ],
          ),
        ],
      ),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.card),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.stallName, required this.stallNumber, required this.onClose});

  final String stallName;

  /// "Stall #12", already in the language in use.
  final String stallNumber;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.sm, AppSpacing.screenPadding, AppSpacing.sm),
      child: Row(
        children: [
          Tooltip(
            message: context.l10n.commonClose,
            child: Material(
              color: AppColors.borderLight,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onClose,
                child: const SizedBox(width: 40, height: 40, child: Icon(Icons.close, size: 20, color: AppColors.textPrimary)),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.ruTitle, style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w800)),
                Row(
                  children: [
                    const Icon(Icons.photo_camera_outlined, size: 12, color: AppColors.secondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        context.l10n.ruStallSubtitle(stallName, stallNumber),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyStrong.copyWith(fontSize: 12, color: AppColors.secondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The dark frosted strip over the photo: when it was taken or chosen. There is
/// no place on it: the app does not read the device's location for reviews.
class _StampOverlay extends StatelessWidget {
  const _StampOverlay({required this.capturedAt});

  final DateTime capturedAt;

  @override
  Widget build(BuildContext context) {
    final small = AppTextStyles.caption.copyWith(color: AppColors.surface, letterSpacing: 0, fontWeight: FontWeight.w600);

    return Frosted(
      color: AppColors.textPrimary,
      opacity: 0.62,
      radius: 14,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user, size: 14, color: AppColors.primaryLight),
              const SizedBox(width: 6),
              Text(
                context.l10n.ruPhotoAdded,
                style: AppTextStyles.bodyStrong.copyWith(fontSize: 12, color: AppColors.primaryLight),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.schedule, size: 12, color: AppColors.surface),
              const SizedBox(width: 4),
              Text(context.l10n.ruToday(formatTime12(TimeOfDay.fromDateTime(capturedAt))), style: small),
            ],
          ),
        ],
      ),
    );
  }
}

class _ObservationChip extends StatelessWidget {
  const _ObservationChip({required this.observation, required this.selected, required this.onTap});

  final _Observation observation;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppColors.surface : AppColors.textPrimary;

    return Semantics(
      button: true,
      selected: selected,
      label: observation.label,
      child: Material(
        color: selected ? AppColors.secondary : AppColors.surface,
        shape: StadiumBorder(side: BorderSide(color: selected ? AppColors.secondary : AppColors.border.withValues(alpha: 0.8))),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(selected ? Icons.check_circle : observation.icon, size: 16, color: selected ? AppColors.surface : AppColors.textMuted),
                const SizedBox(width: 6),
                Text(observation.label, style: AppTextStyles.bodyStrong.copyWith(fontSize: 12, color: foreground)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CommunityNote extends StatelessWidget {
  const _CommunityNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(AppRadii.softButton)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, size: 22, color: AppColors.secondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.ruCommunityTitle, style: AppTextStyles.bodyStrong),
                const SizedBox(height: 2),
                Text(
                  context.l10n.ruCommunityBody,
                  style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
