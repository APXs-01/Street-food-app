import 'dart:io';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_failure.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/widgets/app_text_field.dart';
import '../../../auth/presentation/widgets/coming_soon.dart';
import '../../../auth/presentation/widgets/error_banner.dart';
import '../../../auth/presentation/widgets/pill_badge.dart';
import '../../../auth/presentation/widgets/primary_button.dart';
import '../../../auth/presentation/widgets/surface_card.dart';
import '../../../auth/providers/auth_providers.dart';
import '../data/location_service.dart';
import '../data/onboarding_draft.dart';
import '../data/photo_picker_service.dart';
import '../data/stall_category.dart';
import '../providers/onboarding_providers.dart';
import 'widgets/category_chip.dart';
import 'widgets/dashed_border.dart';
import 'widgets/section_card.dart';
import 'widgets/segmented_progress.dart';
import 'widgets/time_field.dart';

/// "Add Food Stall": the single form a new vendor fills in to create their stall.
///
/// On success the stall id is recorded on the signed-in user, which is what
/// makes the router replace this screen with the vendor home.
class VendorOnboardingScreen extends ConsumerStatefulWidget {
  const VendorOnboardingScreen({super.key});

  @override
  ConsumerState<VendorOnboardingScreen> createState() => _VendorOnboardingScreenState();
}

class _VendorOnboardingScreenState extends ConsumerState<VendorOnboardingScreen> {
  /// Sections in the order they appear, so the first problem can be scrolled to.
  static const _sectionOrder = ['name', 'categories', 'location', 'hours', 'photo', 'description'];

  static const _sectionOfError = {
    'name': 'name',
    'categories': 'categories',
    'location': 'location',
    'opens_at': 'hours',
    'closes_at': 'hours',
    'open_days': 'hours',
    'cover_photo': 'photo',
    'description': 'description',
  };

  final _name = TextEditingController();
  final _description = TextEditingController();
  final Map<String, GlobalKey> _sectionKeys = {for (final section in _sectionOrder) section: GlobalKey()};

  OnboardingDraft _draft = const OnboardingDraft();

  /// Problems by field, from the client-side check or from the server.
  Map<String, String> _errors = {};

  /// A failure that does not belong to one field: offline, a server error.
  String? _banner;

  bool _submitting = false;
  bool _locating = false;
  LocationException? _locationProblem;
  String? _photoProblem;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  /// Replaces the draft and withdraws the problems [clears] for the field just edited.
  void _update(OnboardingDraft next, {List<String> clears = const []}) {
    setState(() {
      _draft = next;
      _errors = Map.of(_errors)..removeWhere((key, _) => clears.contains(key));
    });
  }

  /// The one-letter chip and the full name for a weekday (1 Monday to 7 Sunday).
  (String, String) _dayLabel(int day) {
    final l10n = context.l10n;

    return switch (day) {
      1 => (l10n.obDayMon, l10n.dayMonday),
      2 => (l10n.obDayTue, l10n.dayTuesday),
      3 => (l10n.obDayWed, l10n.dayWednesday),
      4 => (l10n.obDayThu, l10n.dayThursday),
      5 => (l10n.obDayFri, l10n.dayFriday),
      6 => (l10n.obDaySat, l10n.daySaturday),
      _ => (l10n.obDaySun, l10n.daySunday),
    };
  }

  // ---- actions ---------------------------------------------------------

  Future<void> _useCurrentLocation() async {
    setState(() {
      _locating = true;
      _locationProblem = null;
    });

    try {
      final point = await ref.read(locationServiceProvider).currentPosition();
      if (!mounted) return;

      _update(_draft.copyWith(latitude: point.latitude, longitude: point.longitude), clears: const ['location']);
    } on LocationException catch (problem) {
      if (!mounted) return;

      setState(() => _locationProblem = problem);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _editLandmark() async {
    final landmark = await showDialog<String>(
      context: context,
      builder: (context) => _LandmarkDialog(initial: _draft.landmark),
    );

    if (landmark != null && mounted) _update(_draft.copyWith(landmark: landmark));
  }

  Future<void> _pickTime({required bool opening}) async {
    final current = opening ? _draft.opensAt : _draft.closesAt;

    final picked = await showTimePicker(
      context: context,
      initialTime: current ?? TimeOfDay(hour: opening ? 17 : 23, minute: 0),
      helpText: opening ? context.l10n.obOpeningTime : context.l10n.obClosingTime,
    );

    if (picked == null || !mounted) return;

    _update(
      opening ? _draft.copyWith(opensAt: picked) : _draft.copyWith(closesAt: picked),
      // Changing either time can resolve "closing time must differ".
      clears: const ['opens_at', 'closes_at'],
    );
  }

  Future<void> _choosePhoto() async {
    final source = await showModalBottomSheet<PhotoSource>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(context.l10n.commonCamera, style: AppTextStyles.bodyStrong),
              onTap: () => Navigator.of(context).pop(PhotoSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(context.l10n.commonGallery, style: AppTextStyles.bodyStrong),
              onTap: () => Navigator.of(context).pop(PhotoSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    setState(() => _photoProblem = null);

    try {
      final path = await ref.read(photoPickerProvider).pick(source);
      if (path == null || !mounted) return;

      _update(_draft.copyWith(photoPath: path), clears: const ['cover_photo']);
    } on PhotoPickException catch (problem) {
      if (mounted) setState(() => _photoProblem = problem.message);
    }
  }

  Future<void> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.obLeaveTitle, style: AppTextStyles.title),
        content: Text(context.l10n.obLeaveBody, style: AppTextStyles.body),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(context.l10n.obStay)),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(context.l10n.obSignOut)),
        ],
      ),
    );

    if (leave == true && mounted) await ref.read(authControllerProvider.notifier).logout();
  }

  Future<void> _submit() async {
    if (_submitting) return;

    FocusScope.of(context).unfocus();

    final problems = _draft.validate();

    if (problems.isNotEmpty) {
      setState(() {
        _errors = problems;
        _banner = null;
      });
      _scrollToFirstProblem();
      return;
    }

    setState(() {
      _submitting = true;
      _errors = {};
      _banner = null;
    });

    final auth = ref.read(authControllerProvider.notifier);

    try {
      final vendorId = await ref.read(onboardingRepositoryProvider).createStall(_draft);

      // The router reacts to the user's new vendor_id and replaces this screen
      // with the vendor home, so nothing navigates here.
      await auth.stallRegistered(vendorId);
    } on ApiFailure catch (failure) {
      if (!mounted) return;

      // Already has a stall (another device, or a repeated tap): carry on to it.
      if (failure.statusCode == 409 && failure.vendorId != null) {
        await auth.stallRegistered(failure.vendorId!);
        return;
      }

      final mapped = OnboardingDraft.screenErrorsFromServer(failure.fieldErrors);
      final hasUnplaced = mapped.keys.any((key) => !OnboardingDraft.errorKeys.contains(key));

      setState(() {
        _errors = mapped;
        _banner = mapped.isEmpty || hasUnplaced ? failure.message : null;
      });
      _scrollToFirstProblem();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _scrollToFirstProblem() {
    final sections = _errors.keys.map((key) => _sectionOfError[key]).whereType<String>().toSet();

    for (final section in _sectionOrder) {
      if (!sections.contains(section)) continue;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = _sectionKeys[section]?.currentContext;
        if (target == null) return;

        Scrollable.ensureVisible(target, duration: const Duration(milliseconds: 300), alignment: 0.05);
      });
      return;
    }
  }

  // ---- build -----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Column(
            children: [
              _Header(onBack: _confirmLeave),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  // Room for the sticky button bar.
                  padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.lg, AppSpacing.screenPadding, 190),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(context.l10n.obTitle, style: AppTextStyles.title.copyWith(fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(
                            context.l10n.obSubtitle,
                            style: AppTextStyles.body,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          const _ActivationCard(),
                          const SizedBox(height: AppSpacing.lg),
                          _nameCard(),
                          const SizedBox(height: AppSpacing.lg),
                          _categoriesCard(categories),
                          const SizedBox(height: AppSpacing.lg),
                          _locationCard(),
                          const SizedBox(height: AppSpacing.lg),
                          _hoursCard(),
                          const SizedBox(height: AppSpacing.lg),
                          _photoCard(),
                          const SizedBox(height: AppSpacing.lg),
                          _descriptionCard(),
                          const SizedBox(height: AppSpacing.lg),
                          const _AgreementNotice(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(left: 0, right: 0, bottom: 0, child: _BottomBar(banner: _banner, submitting: _submitting, onSubmit: _submit)),
        ],
      ),
    );
  }

  Widget _nameCard() {
    return KeyedSubtree(
      key: _sectionKeys['name'],
      child: SurfaceCard(
        borderColor: _errors['name'] == null ? null : AppColors.error.withValues(alpha: 0.6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              label: context.l10n.obStallName,
              isRequired: true,
              controller: _name,
              hint: context.l10n.obStallNameHint,
              icon: Icons.storefront_outlined,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.text,
              errorText: _errors['name'],
              onChanged: (value) => _update(_draft.copyWith(name: value), clears: const ['name']),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.obStallNameTip,
              style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoriesCard(AsyncValue<List<StallCategory>> categories) {
    return KeyedSubtree(
      key: _sectionKeys['categories'],
      child: SectionCard(
        title: context.l10n.obFoodCategory,
        isRequired: true,
        trailing: PillBadge(
          label: context.l10n.obMultiSelect,
          background: AppColors.surfaceMuted,
          foreground: AppColors.textSecondary,
        ),
        errorText: _errors['categories'],
        child: categories.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary)),
          ),
          error: (error, stack) => _CategoriesError(
            message: error is ApiFailure ? error.message : context.l10n.obCategoriesLoadFailed,
            onRetry: () => ref.invalidate(categoriesProvider),
          ),
          data: (items) => LayoutBuilder(
            builder: (context, constraints) {
              const gap = AppSpacing.sm;
              final width = (constraints.maxWidth - gap) / 2;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final category in items)
                    SizedBox(
                      width: width,
                      child: CategoryChip(
                        category: category,
                        selected: _draft.categories.contains(category.slug),
                        onTap: () => _update(_draft.toggleCategory(category.slug), clears: const ['categories']),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _locationCard() {
    final pinned = _draft.hasLocation;
    final problem = _locationProblem;

    return KeyedSubtree(
      key: _sectionKeys['location'],
      child: SectionCard(
        title: context.l10n.obStallLocation,
        isRequired: true,
        // Only claimed once there is a fix to be accurate about.
        trailing: pinned ? const _GpsIndicator() : null,
        errorText: _errors['location'],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DashedBorder(
              color: AppColors.border,
              radius: AppRadii.input,
              child: Material(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadii.input),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadii.input),
                  onTap: _locating ? null : _useCurrentLocation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: AppSpacing.lg),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_locating)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.primary),
                          )
                        else
                          const Icon(Icons.my_location, size: 20, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            _locating
                                ? context.l10n.obFindingYou
                                : (pinned ? context.l10n.obUpdateGps : context.l10n.obUseGps),
                            style: AppTextStyles.bodyStrong.copyWith(color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (problem != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                problem.message,
                style: AppTextStyles.caption.copyWith(color: AppColors.error, letterSpacing: 0, fontWeight: FontWeight.w600),
              ),
              if (problem.canOpenSettings)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => ref.read(locationServiceProvider).openSettings(problem.problem),
                    child: Text(context.l10n.obOpenSettings, style: AppTextStyles.link),
                  ),
                ),
            ],
            if (pinned) ...[
              const SizedBox(height: AppSpacing.md),
              _PinnedCard(
                landmark: _draft.landmark,
                latitude: _draft.latitude!,
                longitude: _draft.longitude!,
                onEdit: _editLandmark,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _hoursCard() {
    final hasTimeError = _errors['opens_at'] != null || _errors['closes_at'] != null;

    return KeyedSubtree(
      key: _sectionKeys['hours'],
      child: SectionCard(
        title: context.l10n.vpOperatingHours,
        isRequired: true,
        errorText: _errors['opens_at'] ?? _errors['closes_at'] ?? _errors['open_days'],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TimeField(
                    label: context.l10n.obOpens,
                    value: _draft.opensAt,
                    hasError: hasTimeError && _errors['opens_at'] != null,
                    onTap: () => _pickTime(opening: true),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TimeField(
                    label: context.l10n.obCloses,
                    value: _draft.closesAt,
                    hasError: hasTimeError && _errors['closes_at'] != null,
                    onTap: () => _pickTime(opening: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(child: Text(context.l10n.obOpenEveryDay, style: AppTextStyles.bodyStrong)),
                Switch(
                  value: _draft.openEveryDay,
                  activeTrackColor: AppColors.primary,
                  activeThumbColor: AppColors.surface,
                  onChanged: (value) => _update(_draft.copyWith(openEveryDay: value), clears: const ['open_days']),
                ),
              ],
            ),
            if (!_draft.openEveryDay) ...[
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (var day = 1; day <= 7; day++)
                    _DayChip(
                      label: _dayLabel(day).$1,
                      semanticLabel: _dayLabel(day).$2,
                      selected: _draft.openDays.contains(day),
                      onTap: () => _update(_draft.toggleDay(day), clears: const ['open_days']),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _photoCard() {
    final path = _draft.photoPath;

    return KeyedSubtree(
      key: _sectionKeys['photo'],
      child: SectionCard(
        title: context.l10n.obPhotoTitle,
        isRequired: true,
        errorText: _errors['cover_photo'] ?? _photoProblem,
        child: path == null
            ? DashedBorder(
                color: AppColors.primary,
                radius: AppRadii.card,
                child: Material(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadii.card),
                    onTap: _choosePhoto,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        children: [
                          const Icon(Icons.photo_camera_outlined, size: 40, color: AppColors.primary),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            context.l10n.obPhotoTap,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyStrong,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.l10n.obPhotoHelp,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _PillAction(label: context.l10n.obPhotoAction, icon: Icons.add_a_photo_outlined),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            : _PhotoPreview(path: path, onChange: _choosePhoto),
      ),
    );
  }

  Widget _descriptionCard() {
    return KeyedSubtree(
      key: _sectionKeys['description'],
      child: SurfaceCard(
        borderColor: _errors['description'] == null ? null : AppColors.error.withValues(alpha: 0.6),
        child: AppTextField(
          label: context.l10n.obDescription,
          controller: _description,
          hint: context.l10n.obDescriptionHint,
          minLines: 3,
          maxLines: 5,
          maxLength: OnboardingDraft.maxDescription,
          keyboardType: TextInputType.multiline,
          errorText: _errors['description'],
          onChanged: (value) => _update(_draft.copyWith(description: value), clears: const ['description']),
        ),
      ),
    );
  }
}

// ---- pieces local to this screen ------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.xs, AppSpacing.screenPadding, 0),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: context.l10n.commonBack,
                    icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                    onPressed: onBack,
                  ),
                  Expanded(
                    child: Center(
                      child: PillBadge(
                        label: context.l10n.commonStepOf(2, 2),
                        background: AppColors.successBg,
                        foreground: AppColors.successText,
                        borderColor: AppColors.successBorder,
                        uppercase: true,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => showComingSoon(context, context.l10n.commonHelp),
                    child: Text(context.l10n.commonHelp, style: AppTextStyles.link),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.md, top: AppSpacing.xs, bottom: AppSpacing.md),
                child: const SegmentedProgress(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivationCard extends StatelessWidget {
  const _ActivationCard();

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      color: AppColors.successBg,
      borderColor: AppColors.secondary,
      borderWidth: 2,
      shadow: false,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⚡', style: TextStyle(fontSize: 22)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.obInstantTitle, style: AppTextStyles.bodyStrong.copyWith(color: AppColors.successText)),
                const SizedBox(height: 2),
                Text(
                  context.l10n.obInstantBody,
                  style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.successText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GpsIndicator extends StatelessWidget {
  const _GpsIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(color: AppColors.vendorAccent, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(context.l10n.obGpsAccurate, style: AppTextStyles.caption.copyWith(color: AppColors.successText, letterSpacing: 0)),
      ],
    );
  }
}

class _PinnedCard extends StatelessWidget {
  const _PinnedCard({required this.landmark, required this.latitude, required this.longitude, required this.onEdit});

  final String landmark;
  final double latitude;
  final double longitude;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    // No reverse geocoding (it would need another package and service), so an
    // unnamed spot is shown as its coordinates until the vendor names it.
    final named = landmark.trim().isNotEmpty;

    return SurfaceCard(
      color: AppColors.successBg,
      borderColor: AppColors.successBorder,
      shadow: false,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.obPinnedLandmark, style: AppTextStyles.caption.copyWith(color: AppColors.successText)),
                const SizedBox(height: 2),
                Text(named ? landmark.trim() : context.l10n.obCurrentLocation, style: AppTextStyles.bodyStrong),
                Text(
                  '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}',
                  style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onEdit, child: Text(context.l10n.commonEdit, style: AppTextStyles.link)),
        ],
      ),
    );
  }
}

/// Edits the landmark text: a name for the pinned spot ("Opposite the bus stand").
class _LandmarkDialog extends StatefulWidget {
  const _LandmarkDialog({required this.initial});

  final String initial;

  @override
  State<_LandmarkDialog> createState() => _LandmarkDialogState();
}

class _LandmarkDialogState extends State<_LandmarkDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.obNameSpotTitle, style: AppTextStyles.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: OnboardingDraft.maxLandmark,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: context.l10n.obNameSpotHint),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(context.l10n.commonCancel)),
        TextButton(onPressed: () => Navigator.of(context).pop(_controller.text), child: Text(context.l10n.commonSave)),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.label, required this.semanticLabel, required this.selected, required this.onTap});

  final String label;
  final String semanticLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      child: Material(
        color: selected ? AppColors.primary : AppColors.surfaceMuted,
        shape: CircleBorder(side: BorderSide(color: selected ? AppColors.primary : AppColors.border.withValues(alpha: 0.6))),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: Text(
                label,
                style: AppTextStyles.bodyStrong.copyWith(color: selected ? AppColors.surface : AppColors.textPrimary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PillAction extends StatelessWidget {
  const _PillAction({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 10),
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadii.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.surface),
          const SizedBox(width: AppSpacing.sm),
          Flexible(child: Text(label, style: AppTextStyles.button.copyWith(fontSize: 13))),
        ],
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.path, required this.onChange});

  final String path;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Image.file(
              File(path),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Container(
                color: AppColors.surfaceMuted,
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image_outlined, color: AppColors.textMuted, size: 40),
              ),
            ),
          ),
          Positioned(
            right: AppSpacing.md,
            bottom: AppSpacing.md,
            child: FilledButton.icon(
              onPressed: onChange,
              icon: const Icon(Icons.autorenew, size: 18),
              label: Text(context.l10n.obChangePhoto),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.textPrimary,
                shape: const StadiumBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoriesError extends StatelessWidget {
  const _CategoriesError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ErrorBanner(message),
        const SizedBox(height: AppSpacing.sm),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh, size: 18),
          label: Text(context.l10n.commonTryAgain, style: AppTextStyles.link),
        ),
      ],
    );
  }
}

class _AgreementNotice extends StatelessWidget {
  const _AgreementNotice();

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      color: AppColors.surfaceMuted,
      borderColor: Colors.transparent,
      shadow: false,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_user_outlined, size: 18, color: AppColors.textMuted),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              context.l10n.obAgreement,
              style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

/// The sticky call to action: a white bar with the page showing blurred through
/// it, a shadow on its top edge, the button and its caption.
class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.banner, required this.submitting, required this.onSubmit});

  final String? banner;
  final bool submitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.88),
            boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, -4))],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.md, AppSpacing.screenPadding, AppSpacing.md),
              child: Center(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (banner != null) ...[
                        ErrorBanner(banner!),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      PrimaryButton(
                        label: context.l10n.obSubmit,
                        trailingIcon: null,
                        isLoading: submitting,
                        labelStyle: AppTextStyles.button.copyWith(fontSize: 18),
                        onPressed: onSubmit,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        context.l10n.obZeroCommission,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
