import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/json.dart';
import '../../../core/brand.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/presentation/widgets/primary_button.dart';
import '../../auth/presentation/widgets/surface_card.dart';
import '../../consumer/data/discovery_stall.dart';
import '../../consumer/presentation/widgets/photo_source_sheet.dart';
import '../../consumer/providers/discovery_providers.dart';
import '../../consumer/vendor_profile/widgets/frosted.dart';
import '../../statuses/providers/status_providers.dart';
import '../onboarding/data/photo_picker_service.dart';
import '../onboarding/presentation/widgets/dashed_border.dart';
import '../onboarding/providers/onboarding_providers.dart';
import '../providers/vendor_providers.dart';

enum _Audience { public, friends }

/// "New Status": a photo, a caption, where it was taken and who can see it.
/// Opened full-screen; there is no bottom nav while composing.
///
/// Sends `POST /statuses` (multipart `caption`, `media`, `audience`,
/// `location_label`, and `vendor_id` for the stall a customer tags). The server
/// needs a photo or a caption. A vendor posts as their own stall and always
/// publicly; "Friends Only" is a customer feature on the server, so it is
/// switched off here for a vendor. Tagging friends, drafts and photo filters
/// have no backend and are not offered.
class CreateStatusScreen extends ConsumerStatefulWidget {
  const CreateStatusScreen({super.key, this.asConsumer = false});

  /// A customer posting as themselves (the backend lets customers post statuses
  /// too) instead of a vendor posting as their stall. Customers may tag a stall.
  final bool asConsumer;

  @override
  ConsumerState<CreateStatusScreen> createState() => _CreateStatusScreenState();
}

class _CreateStatusScreenState extends ConsumerState<CreateStatusScreen> {
  /// The API's limits.
  static const _maxCaption = 200;
  static const _maxPlace = 120;
  static const _quickEmoji = ['🔥', '🤤', '🥟', '🍜', '✨'];

  final _caption = TextEditingController();
  final _place = TextEditingController();

  String? _photoPath;
  String? _photoProblem;
  String? _postProblem;
  DiscoveryStall? _taggedStall;
  _Audience _audience = _Audience.public;
  bool _placeSeeded = false;
  bool _submitting = false;

  @override
  void dispose() {
    _caption.dispose();
    _place.dispose();
    super.dispose();
  }

  bool get _hasContent => _photoPath != null || _caption.text.trim().isNotEmpty;

  Future<void> _pick({PhotoSource? source}) async {
    final chosen = source ?? await showPhotoSourceSheet(context);
    if (chosen == null || !mounted) return;

    setState(() => _photoProblem = null);

    try {
      final path = await ref.read(photoPickerProvider).pick(chosen);
      if (path == null || !mounted) return;

      setState(() => _photoPath = path);
    } on PhotoPickException catch (problem) {
      if (mounted) setState(() => _photoProblem = problem.message);
    }
  }

  /// Puts [emoji] where the cursor is (or at the end), unless the caption is full.
  void _insertEmoji(String emoji) {
    final text = _caption.text;
    if (text.length + emoji.length > _maxCaption) return;

    final selection = _caption.selection;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;

    _caption.value = TextEditingValue(
      text: text.replaceRange(start, end, emoji),
      selection: TextSelection.collapsed(offset: start + emoji.length),
    );
  }

  Future<void> _pickStall() async {
    final stalls = ref.read(allStallsProvider).asData?.value ?? const <DiscoveryStall>[];

    final picked = await showModalBottomSheet<DiscoveryStall>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.6),
          child: stalls.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text(context.l10n.csNoNearbyStalls, textAlign: TextAlign.center, style: AppTextStyles.body),
                )
              : ListView(
                  shrinkWrap: true,
                  children: [
                    for (final stall in stalls)
                      ListTile(
                        leading: const Icon(Icons.storefront_outlined, color: AppColors.secondary),
                        title: Text(stall.name, style: AppTextStyles.bodyStrong),
                        subtitle: stall.hasDistance ? Text(stall.distanceLabel, style: AppTextStyles.body.copyWith(fontSize: 12)) : null,
                        onTap: () => Navigator.of(context).pop(stall),
                      ),
                  ],
                ),
        ),
      ),
    );

    if (picked != null && mounted) setState(() => _taggedStall = picked);
  }

  Future<void> _close() async {
    if (!_hasContent) {
      context.pop();
      return;
    }

    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.csDiscardTitle, style: AppTextStyles.title),
        content: Text(context.l10n.csDiscardBody, style: AppTextStyles.body),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(context.l10n.csKeepEditing)),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(context.l10n.csDiscard)),
        ],
      ),
    );

    if (discard == true && mounted) context.pop();
  }

  Future<void> _post() async {
    if (!_hasContent || _submitting) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _postProblem = null;
    });

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    try {
      await ref.read(statusRepositoryProvider).create(
            caption: _caption.text,
            photoPath: _photoPath,
            // A vendor's status is always public, whatever this says.
            audience: widget.asConsumer && _audience == _Audience.friends ? 'friends' : 'public',
            locationLabel: _place.text.trim(),
            vendorId: widget.asConsumer ? _taggedStall?.id : null,
          );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _submitting = false;
        _postProblem = errorMessage(error);
      });
      return;
    }

    refreshStatuses(ref);

    if (!mounted) return;

    if (router.canPop()) {
      router.pop();
    } else {
      router.go(widget.asConsumer ? Routes.consumerProfile : Routes.vendorHome);
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.csPosted)));
  }

  @override
  Widget build(BuildContext context) {
    // Null for a customer, who is not posting as a stall.
    final stall = widget.asConsumer ? null : ref.watch(vendorStallProvider).asData?.value;

    // A vendor's place starts as their stall's landmark or address.
    if (!_placeSeeded && stall != null) {
      _placeSeeded = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _place.text.isEmpty) _place.text = stall.locationLabel;
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(onClose: _close),
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
                        _photoArea(),
                        const SizedBox(height: AppSpacing.md),
                        _captionCard(),
                        const SizedBox(height: AppSpacing.lg),
                        _contextCard(stallName: stall?.name),
                        const SizedBox(height: AppSpacing.lg),
                        _audienceCard(),
                        const SizedBox(height: AppSpacing.xl),
                        if (_postProblem != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: Text(
                              _postProblem!,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyStrong.copyWith(fontSize: 13, color: AppColors.error),
                            ),
                          ),
                        PrimaryButton(
                          label: context.l10n.csPost,
                          trailingIcon: null,
                          enabled: _hasContent,
                          isLoading: _submitting,
                          onPressed: _post,
                        ),
                        if (!_hasContent)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.sm),
                            child: Text(
                              context.l10n.csNeedContent,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ),
                        const SizedBox(height: AppSpacing.lg),
                        const _ExpiryNotice(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoArea() {
    final path = _photoPath;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.card),
          child: SizedBox(
            height: 300,
            child: path == null
                ? DashedBorder(
                    color: AppColors.primary,
                    radius: AppRadii.card,
                    child: Material(
                      color: AppColors.surfaceMuted,
                      child: InkWell(
                        onTap: _pick,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add_a_photo_outlined, size: 44, color: AppColors.primary),
                              const SizedBox(height: AppSpacing.sm),
                              Text(context.l10n.csTapPhoto, style: AppTextStyles.bodyStrong),
                              const SizedBox(height: 2),
                              Text(context.l10n.csCameraOrGallery, style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                      ),
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
                        right: AppSpacing.md,
                        bottom: AppSpacing.md,
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => _pick(source: PhotoSource.camera),
                              child: Frosted(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.photo_camera_outlined, size: 15, color: AppColors.textPrimary),
                                    const SizedBox(width: 6),
                                    Text(context.l10n.ruRetake, style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary, letterSpacing: 0.2)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Tooltip(
                              message: context.l10n.csChooseDifferent,
                              child: GestureDetector(
                                onTap: () => _pick(source: PhotoSource.gallery),
                                child: const Frosted(
                                  child: SizedBox(
                                    width: 38,
                                    height: 38,
                                    child: Icon(Icons.photo_library_outlined, size: 18, color: AppColors.textPrimary),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

  Widget _captionCard() {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(context.l10n.csCaptionTitle, style: AppTextStyles.label.copyWith(fontSize: 14))),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _caption,
                builder: (context, value, _) => Text(
                  '${value.text.length}/$_maxCaption',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textMuted, letterSpacing: 0),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _caption,
            minLines: 4,
            maxLines: 6,
            maxLength: _maxCaption,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            cursorColor: AppColors.primary,
            style: AppTextStyles.input,
            onChanged: (_) => setState(() {}),
            // The live counter above replaces the field's own.
            buildCounter: (context, {required currentLength, required isFocused, required maxLength}) => null,
            decoration: InputDecoration(
              hintText: context.l10n.csCaptionHint,
              hintStyle: AppTextStyles.hint,
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.all(AppSpacing.lg),
              border: _border(AppColors.border.withValues(alpha: 0.7)),
              enabledBorder: _border(AppColors.border.withValues(alpha: 0.7)),
              focusedBorder: _border(AppColors.primary, width: 1.5),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final emoji in _quickEmoji)
                Semantics(
                  button: true,
                  label: context.l10n.csInsertEmoji(emoji),
                  child: Material(
                    color: AppColors.surfaceMuted,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _insertEmoji(emoji),
                      child: SizedBox(width: 40, height: 40, child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18)))),
                    ),
                  ),
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

  Widget _contextCard({required String? stallName}) {
    // A vendor posts as their own stall, so there is no "change stall" button. A
    // customer may tag the stall in the photo, or none.
    final stallRow = stallName != null
        ? _ContextRow(
            iconBackground: AppColors.primaryLight,
            icon: Icons.storefront,
            iconColor: AppColors.primary,
            label: context.l10n.csFoodStall,
            labelTrailing: const SizedBox.shrink(),
            content: Text(stallName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyStrong),
            helper: context.l10n.csPostingAs(stallName),
          )
        : _ContextRow(
            iconBackground: AppColors.primaryLight,
            icon: Icons.storefront,
            iconColor: AppColors.primary,
            label: context.l10n.csFoodStall,
            labelTrailing: InkWell(
              onTap: _pickStall,
              child: Text(
                _taggedStall == null ? context.l10n.csTagStall : context.l10n.csChange,
                style: AppTextStyles.link.copyWith(fontSize: 11, color: AppColors.secondary),
              ),
            ),
            content: Text(_taggedStall?.name ?? context.l10n.csNoStallTagged, style: AppTextStyles.bodyStrong),
            helper: context.l10n.csTagOptional,
          );

    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          stallRow,
          const Divider(height: 1),
          _ContextRow(
            iconBackground: AppColors.orangeAccentBg,
            icon: Icons.location_on,
            iconColor: AppColors.orangeAccentText,
            label: context.l10n.csWhere,
            labelTrailing: const SizedBox.shrink(),
            content: TextField(
              controller: _place,
              maxLength: _maxPlace,
              cursorColor: AppColors.primary,
              style: AppTextStyles.bodyStrong,
              buildCounter: (context, {required currentLength, required isFocused, required maxLength}) => null,
              decoration: InputDecoration(
                hintText: context.l10n.csWhereHint,
                hintStyle: AppTextStyles.hint,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                border: InputBorder.none,
              ),
            ),
            helper: context.l10n.csWhereHelper,
          ),
        ],
      ),
    );
  }

  Widget _audienceCard() {
    // A vendor's statuses are always public on the server.
    final canChoose = widget.asConsumer;

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(context.l10n.csAudience, style: AppTextStyles.label.copyWith(fontSize: 14)),
              const Spacer(),
              Text(context.l10n.csWhoSees, style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: AppColors.borderLight, borderRadius: BorderRadius.circular(999)),
            child: Row(
              children: [
                _Segment(
                  label: context.l10n.csPublic(kBrandName),
                  selected: _audience == _Audience.public,
                  onTap: () => setState(() => _audience = _Audience.public),
                ),
                _Segment(
                  label: context.l10n.csFriendsOnly,
                  selected: _audience == _Audience.friends,
                  enabled: canChoose,
                  onTap: () => setState(() => _audience = _Audience.friends),
                ),
              ],
            ),
          ),
          if (!canChoose) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.csAlwaysPublic,
              style: AppTextStyles.body.copyWith(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.xs, AppSpacing.sm, AppSpacing.xs),
      child: Row(
        children: [
          IconButton(tooltip: context.l10n.commonClose, icon: const Icon(Icons.close, color: AppColors.textPrimary), onPressed: onClose),
          Expanded(
            child: Center(child: Text(context.l10n.csTitle, style: AppTextStyles.title.copyWith(fontSize: 17, fontWeight: FontWeight.w800))),
          ),
          // Keeps the title centred against the close button.
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _ContextRow extends StatelessWidget {
  const _ContextRow({
    required this.iconBackground,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.labelTrailing,
    required this.content,
    required this.helper,
  });

  final Color iconBackground;
  final IconData icon;
  final Color iconColor;
  final String label;
  final Widget labelTrailing;

  /// The row's main line: the stall name or the place.
  final Widget content;
  final String helper;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: iconBackground, borderRadius: BorderRadius.circular(AppRadii.softButton)),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                    const Spacer(),
                    labelTrailing,
                  ],
                ),
                const SizedBox(height: 4),
                content,
                const SizedBox(height: 2),
                Text(helper, style: AppTextStyles.body.copyWith(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.label, required this.selected, required this.onTap, this.enabled = true});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// False greys the segment out and ignores taps.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        enabled: enabled,
        selected: selected,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: selected ? AppColors.textPrimary : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: AppTextStyles.bodyStrong.copyWith(
                    fontSize: 12,
                    color: !enabled ? AppColors.textMuted.withValues(alpha: 0.6) : (selected ? AppColors.surface : AppColors.textSecondary),
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

class _ExpiryNotice extends StatelessWidget {
  const _ExpiryNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(AppRadii.softButton)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.schedule, size: 20, color: AppColors.textMuted),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              context.l10n.csExpiryNotice,
              style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
