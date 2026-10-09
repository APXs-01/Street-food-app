import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/json.dart';
import '../../core/format.dart';
import '../../core/localization/l10n.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../auth/presentation/widgets/pill_badge.dart';
import '../auth/presentation/widgets/primary_button.dart';
import '../auth/presentation/widgets/surface_card.dart';
import '../consumer/data/discovery_stall.dart';
import '../consumer/presentation/widgets/photo_source_sheet.dart';
import '../consumer/presentation/widgets/stall_thumbnail.dart';
import '../consumer/providers/discovery_providers.dart';
import '../vendor/onboarding/data/onboarding_draft.dart';
import '../vendor/onboarding/data/photo_picker_service.dart';
import '../vendor/onboarding/presentation/widgets/dashed_border.dart';
import '../vendor/onboarding/providers/onboarding_providers.dart';
import 'data/inspection_scoring.dart';
import 'providers/inspector_providers.dart';

/// "Inspection Submission": a health inspector picks a stall, scores the five
/// mandatory criteria (pass, partial or fail), attaches a photo and adds notes,
/// then sends it with `POST /api/inspections`.
///
/// The app has no inspector sign-in (inspectors use the backend directly), so
/// this screen is reachable only by its route and is not linked from anywhere.
/// The request is real, but only an inspector account may make it: anyone else
/// gets the server's refusal, shown on screen. The `inspector.checklist` flag can
/// switch it off. Stalls are found with the same search as the customer app.
class InspectorChecklistScreen extends ConsumerStatefulWidget {
  const InspectorChecklistScreen({super.key});

  @override
  ConsumerState<InspectorChecklistScreen> createState() => _InspectorChecklistScreenState();
}

class _InspectorChecklistScreenState extends ConsumerState<InspectorChecklistScreen> {
  /// The API's limit on notes.
  static const _maxNotes = 1000;

  final _search = TextEditingController();
  final _notes = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _debounce;

  DiscoveryStall? _stall;
  bool _showResults = false;
  bool _searching = false;
  String? _searchProblem;
  List<DiscoveryStall> _matches = const [];

  /// One answer per criterion; a criterion nobody has answered yet is absent.
  final Map<InspectionCriterion, CheckResult> _answers = {};

  String? _photoPath;
  DateTime? _capturedAt;
  String? _photoProblem;
  String? _submitProblem;
  bool _submitting = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _notes.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  bool get _complete => _stall != null && _photoPath != null && _answers.length == InspectionCriterion.values.length;

  void _typed(String text) {
    _debounce?.cancel();

    final query = text.trim();

    if (query.isEmpty) {
      setState(() {
        _showResults = false;
        _matches = const [];
        _searchProblem = null;
      });
      return;
    }

    setState(() => _showResults = true);
    _debounce = Timer(const Duration(milliseconds: 350), () => _runSearch(query));
  }

  Future<void> _runSearch(String query) async {
    setState(() {
      _searching = true;
      _searchProblem = null;
    });

    try {
      final found = await ref.read(stallRepositoryProvider).search(query);

      if (!mounted || _search.text.trim() != query) return;

      setState(() {
        _matches = found.take(6).toList();
        _searching = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _searching = false;
        _searchProblem = errorMessage(error);
      });
    }
  }

  Future<void> _pickPhoto() async {
    final source = await showPhotoSourceSheet(context);
    if (source == null || !mounted) return;

    setState(() => _photoProblem = null);

    try {
      final path = await ref.read(photoPickerProvider).pick(source);
      if (path == null || !mounted) return;

      setState(() {
        _photoPath = path;
        _capturedAt = DateTime.now();
      });
    } on PhotoPickException catch (problem) {
      if (mounted) setState(() => _photoProblem = problem.message);
    }
  }

  Future<void> _submit() async {
    final stall = _stall;
    final photo = _photoPath;
    if (!_complete || stall == null || photo == null || _submitting) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _submitProblem = null;
    });

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    try {
      await ref.read(inspectionRepositoryProvider).submit(
            vendorId: stall.id,
            results: Map.of(_answers),
            photoPath: photo,
            notes: _notes.text,
          );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _submitting = false;
        _submitProblem = errorMessage(error);
      });
      return;
    }

    // The stall's hygiene has changed on the server.
    ref.invalidate(stallHygieneProvider(stall.id));
    ref.invalidate(stallDetailProvider(stall.id));
    ref.invalidate(allStallsProvider);

    if (!mounted) return;

    final score = inspectionScoreOf(_answers.values);

    if (router.canPop()) {
      router.pop();
    } else {
      router.go(Routes.roleSelect);
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(context.l10n.inspSubmitted(stall.name, score.toStringAsFixed(1), inspectionGrade(score)))));
  }

  @override
  Widget build(BuildContext context) {
    final stall = _stall;
    final answered = _answers.length;
    final score = inspectionScoreOf(_answers.values);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.xs, AppSpacing.screenPadding, AppSpacing.xs),
              child: Row(
                children: [
                  IconButton(
                    tooltip: context.l10n.commonBack,
                    icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                    onPressed: () => context.canPop() ? context.pop() : context.go(Routes.roleSelect),
                  ),
                  Expanded(child: Text(context.l10n.inspTitle, style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w800))),
                ],
              ),
            ),
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
                        Text(context.l10n.inspSelectStall, style: AppTextStyles.title.copyWith(fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(height: AppSpacing.md),
                        _stallSearch(),
                        if (stall != null) ...[const SizedBox(height: AppSpacing.md), _StallPreview(stall: stall)],
                        const SizedBox(height: AppSpacing.xl),
                        Row(
                          children: [
                            Expanded(
                              child: Text(context.l10n.inspChecklistTitle, style: AppTextStyles.title.copyWith(fontSize: 16, fontWeight: FontWeight.w800)),
                            ),
                            PillBadge(
                              label: context.l10n.inspScored(answered),
                              background: answered == 5 ? AppColors.successBg : AppColors.surfaceMuted,
                              foreground: answered == 5 ? AppColors.successText : AppColors.textSecondary,
                              borderColor: answered == 5 ? AppColors.successBorder : AppColors.border,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        for (final criterion in InspectionCriterion.values) ...[
                          _CriterionRow(
                            criterion: criterion,
                            result: _answers[criterion],
                            onChanged: (result) => setState(() => _answers[criterion] = result),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(AppRadii.softButton)),
                          child: Row(
                            children: [
                              const Icon(Icons.calculate_outlined, size: 18, color: AppColors.textMuted),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  answered < InspectionCriterion.values.length
                                      ? context.l10n.inspScoreAll
                                      : context.l10n.inspWillScore(score.toStringAsFixed(1), inspectionGrade(score)),
                                  style: AppTextStyles.bodyStrong.copyWith(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(context.l10n.inspAttachPhoto, style: AppTextStyles.title.copyWith(fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(height: AppSpacing.md),
                        _photoBox(),
                        const SizedBox(height: AppSpacing.xl),
                        Row(
                          children: [
                            Expanded(child: Text(context.l10n.inspNotes, style: AppTextStyles.title.copyWith(fontSize: 16, fontWeight: FontWeight.w800))),
                            ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _notes,
                              builder: (context, value, _) => Text(
                                '${value.text.length}/$_maxNotes',
                                style: AppTextStyles.caption.copyWith(color: AppColors.textMuted, letterSpacing: 0),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          controller: _notes,
                          minLines: 3,
                          maxLines: 5,
                          maxLength: _maxNotes,
                          textCapitalization: TextCapitalization.sentences,
                          cursorColor: AppColors.primary,
                          style: AppTextStyles.input,
                          buildCounter: (context, {required currentLength, required isFocused, required maxLength}) => null,
                          decoration: InputDecoration(
                            hintText: context.l10n.inspNotesHint,
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
                            const Icon(Icons.public, size: 14, color: AppColors.textMuted),
                            const SizedBox(width: 6),
                            Text(
                              context.l10n.inspNotesPublic,
                              style: AppTextStyles.body.copyWith(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
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
                boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, -4))],
              ),
              padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.md, AppSpacing.screenPadding, AppSpacing.md),
              child: Center(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_submitProblem != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Text(
                            _submitProblem!,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyStrong.copyWith(fontSize: 12, color: AppColors.error),
                          ),
                        ),
                      PrimaryButton(
                        label: context.l10n.inspSubmit,
                        enabled: _complete,
                        isLoading: _submitting,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _complete
                            ? context.l10n.inspSubmitEffect
                            : context.l10n.inspSubmitHint,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.copyWith(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.card),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  Widget _stallSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _search,
          focusNode: _searchFocus,
          cursorColor: AppColors.primary,
          style: AppTextStyles.input,
          onChanged: _typed,
          decoration: InputDecoration(
            hintText: context.l10n.inspSearchHint,
            hintStyle: AppTextStyles.hint,
            filled: true,
            fillColor: AppColors.surface,
            prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: _border(AppColors.border.withValues(alpha: 0.7)),
            enabledBorder: _border(AppColors.border.withValues(alpha: 0.7)),
            focusedBorder: _border(AppColors.primary, width: 1.5),
          ),
        ),
        if (_showResults)
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.softButton),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
            ),
            child: _searching
                ? const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                  )
                : _searchProblem != null
                    ? Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Text(_searchProblem!, style: AppTextStyles.body.copyWith(color: AppColors.error)),
                      )
                    : _matches.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Text(context.l10n.inspNoMatch, style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
                          )
                        : Column(
                            children: [
                              for (final stall in _matches)
                                ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.storefront_outlined, color: AppColors.secondary),
                                  title: Text(stall.name, style: AppTextStyles.bodyStrong.copyWith(fontSize: 13)),
                                  subtitle: Text(
                                    [stall.stallNumberLabel, stall.locationLabel].where((part) => part.isNotEmpty).join(' • '),
                                    style: AppTextStyles.body.copyWith(fontSize: 11),
                                  ),
                                  onTap: () {
                                    _searchFocus.unfocus();
                                    setState(() {
                                      _stall = stall;
                                      _search.text = stall.name;
                                      _showResults = false;
                                    });
                                  },
                                ),
                            ],
                          ),
          ),
      ],
    );
  }

  Widget _photoBox() {
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
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadii.card),
              onTap: _pickPhoto,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: path == null
                    ? Column(
                        children: [
                          const Icon(Icons.add_a_photo_outlined, size: 38, color: AppColors.primary),
                          const SizedBox(height: AppSpacing.sm),
                          Text(context.l10n.inspTapCapture, style: AppTextStyles.bodyStrong),
                          const SizedBox(height: 2),
                          Text(
                            context.l10n.inspPhotoRequired,
                            style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 72,
                              height: 72,
                              child: Image.file(
                                File(path),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stack) => const StallThumbnail(url: '', width: 72, height: 72),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle, size: 16, color: AppColors.secondary),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Text(context.l10n.inspEvidence, style: AppTextStyles.bodyStrong.copyWith(fontSize: 12, color: AppColors.successText)),
                                    ),
                                  ],
                                ),
                                if (capturedAt != null)
                                  Text(
                                    context.l10n.inspToday(formatTime12(TimeOfDay.fromDateTime(capturedAt))),
                                    style: AppTextStyles.body.copyWith(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                const SizedBox(height: 4),
                                Text(context.l10n.inspRetake, style: AppTextStyles.link.copyWith(fontSize: 12, color: AppColors.secondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.schedule, size: 13, color: AppColors.textMuted),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                context.l10n.inspServerRecords,
                style: AppTextStyles.body.copyWith(fontSize: 11, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
        if (_photoProblem != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(_photoProblem!, style: AppTextStyles.caption.copyWith(color: AppColors.error, letterSpacing: 0, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}

/// The selected stall: thumbnail, name, place, last inspection and hygiene score.
class _StallPreview extends StatelessWidget {
  const _StallPreview({required this.stall});

  final DiscoveryStall stall;

  @override
  Widget build(BuildContext context) {
    final inspected = stall.lastInspectedAt;

    return SurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StallThumbnail(url: stall.photoUrl, width: 76, height: 76, radius: 12),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.inspStallWithNumber(stall.name, stall.stallNumber), style: AppTextStyles.bodyStrong),
                if (stall.locationLabel.isNotEmpty)
                  Text(stall.locationLabel, style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        inspected == null ? context.l10n.hygieneNotInspected : context.l10n.inspLastInspected(agoFrom(inspected)),
                        style: AppTextStyles.body.copyWith(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ),
                    if (stall.hygieneScore != null) ...[
                      const SizedBox(width: 6),
                      Text('${stall.hygieneScore!.toStringAsFixed(1)} / 5', style: AppTextStyles.bodyStrong.copyWith(fontSize: 12)),
                    ],
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

class _CriterionRow extends StatelessWidget {
  const _CriterionRow({required this.criterion, required this.result, required this.onChanged});

  final InspectionCriterion criterion;

  /// Null until the inspector answers.
  final CheckResult? result;
  final ValueChanged<CheckResult> onChanged;

  static IconData _icon(InspectionCriterion criterion) => switch (criterion) {
        InspectionCriterion.waterSource => Icons.water_drop_outlined,
        InspectionCriterion.utensilHygiene => Icons.clean_hands_outlined,
        InspectionCriterion.wasteDisposal => Icons.delete_outline,
        InspectionCriterion.foodCovering => Icons.takeout_dining_outlined,
        InspectionCriterion.overallCleanliness => Icons.cleaning_services_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final failed = result == CheckResult.fail;
    final passed = result == CheckResult.pass;

    return SurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: failed ? AppColors.error.withValues(alpha: 0.5) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: failed ? AppColors.error.withValues(alpha: 0.08) : (passed ? AppColors.successBg : AppColors.surfaceMuted),
                  borderRadius: BorderRadius.circular(AppRadii.softButton),
                ),
                child: Icon(_icon(criterion), size: 19, color: failed ? AppColors.error : (passed ? AppColors.secondary : AppColors.textMuted)),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(criterion.title, style: AppTextStyles.bodyStrong),
                    Text(criterion.description, style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(color: AppColors.borderLight, borderRadius: BorderRadius.circular(999)),
            child: Row(
              children: [
                _Choice(label: CheckResult.pass.label, selected: result == CheckResult.pass, selectedColor: AppColors.textPrimary, onTap: () => onChanged(CheckResult.pass)),
                _Choice(label: CheckResult.partial.label, selected: result == CheckResult.partial, selectedColor: AppColors.amber, onTap: () => onChanged(CheckResult.partial)),
                _Choice(label: CheckResult.fail.label, selected: result == CheckResult.fail, selectedColor: AppColors.error, onTap: () => onChanged(CheckResult.fail)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({required this.label, required this.selected, required this.selectedColor, required this.onTap});

  final String label;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(color: selected ? selectedColor : Colors.transparent, borderRadius: BorderRadius.circular(999)),
            child: Center(
              child: Text(
                label,
                style: AppTextStyles.bodyStrong.copyWith(fontSize: 12, color: selected ? AppColors.surface : AppColors.textSecondary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
