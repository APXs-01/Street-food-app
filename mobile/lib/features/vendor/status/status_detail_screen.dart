import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/json.dart';
import '../../../core/format.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/async_view.dart';
import '../../auth/presentation/widgets/pill_badge.dart';
import '../../auth/providers/auth_providers.dart';
import '../../consumer/presentation/widgets/stall_thumbnail.dart';
import '../../consumer/vendor_profile/widgets/avatar_circle.dart';
import '../../consumer/vendor_profile/widgets/frosted.dart';
import '../../statuses/data/status_models.dart';
import '../../statuses/providers/status_providers.dart';

/// A status (story) with its caption and the comments under it: a full-bleed
/// photo on top, the caption and likes below, then the comment thread. Read from
/// `GET /statuses/{id}`; likes and comments are real calls.
///
/// One screen for both sides. Customers open it from the story circles on their
/// home screen (`/consumer/status/:id`); a vendor opens their own from the
/// Homepage (`/vendor/status/:id`, [ownerView]). Whoever wrote the status gets
/// "Delete Status"; anyone else gets "View Stall" when the status is about one.
class StatusDetailScreen extends ConsumerStatefulWidget {
  const StatusDetailScreen({super.key, required this.statusId, this.ownerView = false});

  final int statusId;
  final bool ownerView;

  @override
  ConsumerState<StatusDetailScreen> createState() => _StatusDetailScreenState();
}

class _StatusDetailScreenState extends ConsumerState<StatusDetailScreen> {
  List<String> get _quickReactions => [l10n.sdReact1, l10n.sdReact2, l10n.sdReact3];

  final _input = TextEditingController();
  final _inputFocus = FocusNode();

  late int _currentId = widget.statusId;

  /// What a like or unlike just did, until the status is read again.
  final Map<int, ({bool liked, int likes})> _likes = {};
  bool _sending = false;

  @override
  void dispose() {
    _input.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(widget.ownerView ? Routes.vendorHome : Routes.consumerHome);
    }
  }

  Future<void> _toggleLike(StatusPost post) async {
    try {
      final result = await ref.read(statusRepositoryProvider).toggleLike(post.id);

      if (mounted) setState(() => _likes[post.id] = result);
    } catch (error) {
      if (mounted) _toast(errorMessage(error));
    }
  }

  Future<void> _send(StatusPost post, String text) async {
    final body = text.trim();
    if (body.isEmpty || _sending) return;

    setState(() => _sending = true);

    try {
      await ref.read(statusRepositoryProvider).comment(post.id, body);
      if (!mounted) return;

      _input.clear();
      ref.invalidate(statusDetailProvider(post.id));
    } catch (error) {
      if (mounted) _toast(errorMessage(error));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _confirmDelete(StatusPost post) async {
    final delete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.sdDeleteTitle, style: AppTextStyles.title),
        content: Text(context.l10n.sdDeleteBody, style: AppTextStyles.body),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(context.l10n.sdKeep)),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.sdDelete, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (delete != true || !mounted) return;

    try {
      await ref.read(statusRepositoryProvider).delete(post.id);
      if (!mounted) return;

      refreshStatuses(ref);
      _leave();
    } catch (error) {
      if (mounted) _toast(errorMessage(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(statusDetailProvider(_currentId));
    final post = detail.asData?.value;
    final now = DateTime.now();

    if (post == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          leading: IconButton(tooltip: context.l10n.commonClose, icon: const Icon(Icons.close), onPressed: _leave),
        ),
        body: Center(
          child: SingleChildScrollView(
            child: AsyncView<StatusPost>(
              value: detail,
              onRetry: () => ref.invalidate(statusDetailProvider(_currentId)),
              builder: (_) => const SizedBox.shrink(),
            ),
          ),
        ),
      );
    }

    final user = ref.watch(authControllerProvider.select((state) => state.session?.user));
    final isMine = user != null && post.author.id == user.id;

    // The same author's other live statuses, oldest first, like the segments of a story.
    final feed = ref.watch(feedProvider).asData?.value ?? const <StatusPost>[];
    final story = feed
        .where((candidate) => candidate.author.id == post.author.id && (candidate.isActive || candidate.id == post.id))
        .toList()
      ..sort((a, b) => (a.createdAt ?? now).compareTo(b.createdAt ?? now));
    final index = story.indexWhere((candidate) => candidate.id == post.id);
    final viewportHeight = MediaQuery.sizeOf(context).height * 0.56;

    final likeState = _likes[post.id];
    final liked = likeState?.liked ?? post.likedByMe;
    final likes = likeState?.likes ?? post.likesCount;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            height: viewportHeight,
            child: _Viewport(
              post: post,
              now: now,
              segments: story.isEmpty ? 1 : story.length,
              current: index < 0 ? 0 : index,
              onClose: _leave,
              onPrevious: index > 0 ? () => setState(() => _currentId = story[index - 1].id) : null,
              onNext: index >= 0 && index < story.length - 1 ? () => setState(() => _currentId = story[index + 1].id) : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.lg, AppSpacing.screenPadding, 0),
            child: _CaptionStrip(
              post: post,
              now: now,
              isMine: isMine,
              liked: liked,
              likes: likes,
              onLike: () => _toggleLike(post),
              onViewStall: post.vendorId == null ? null : () => context.push(Routes.consumerVendor(post.vendorId!)),
              onDelete: () => _confirmDelete(post),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.xl, AppSpacing.screenPadding, AppSpacing.xl),
            child: _Comments(post: post, now: now),
          ),
        ],
      ),
      bottomNavigationBar: _CommentBar(
        controller: _input,
        focusNode: _inputFocus,
        authorName: user?.name ?? '',
        authorPhoto: user?.avatarUrl,
        hint: isMine ? context.l10n.sdReplyHint : context.l10n.sdCommentHint(post.displayName),
        reactions: isMine ? const [] : _quickReactions,
        sending: _sending,
        onSend: (text) => _send(post, text),
      ),
    );
  }
}

/// The photo with the story chrome: progress segments, who posted it, the
/// countdown and tap zones to step through the author's statuses.
class _Viewport extends StatelessWidget {
  const _Viewport({
    required this.post,
    required this.now,
    required this.segments,
    required this.current,
    required this.onClose,
    required this.onPrevious,
    required this.onNext,
  });

  final StatusPost post;
  final DateTime now;
  final int segments;
  final int current;
  final VoidCallback onClose;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final place = post.locationLabel?.trim() ?? '';

    return Container(
      color: AppColors.textPrimary,
      child: Stack(
        fit: StackFit.expand,
        children: [
          StallThumbnail(url: post.photoUrl, width: double.infinity, height: double.infinity, radius: 0, iconSize: 64),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x99000000), Color(0x00000000), Color(0x00000000), Color(0x99000000)],
                stops: [0, 0.3, 0.6, 1],
              ),
            ),
          ),
          // Tap the left or right third to step through the author's statuses.
          Positioned.fill(
            child: Row(
              children: [
                Expanded(flex: 3, child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: onPrevious)),
                const Spacer(flex: 4),
                Expanded(flex: 3, child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: onNext)),
              ],
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < segments; i++) ...[
                        if (i > 0) const SizedBox(width: 4),
                        Expanded(
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: i <= current ? AppColors.surface : AppColors.surface.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: onClose,
                        child: const Frosted(
                          color: AppColors.textPrimary,
                          opacity: 0.45,
                          child: SizedBox(width: 38, height: 38, child: Icon(Icons.close, size: 20, color: AppColors.surface)),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: _AuthorChip(post: post)),
                      const SizedBox(width: AppSpacing.sm),
                      PillBadge(
                        label: post.timeLeftLabelAt(now),
                        background: AppColors.amber,
                        foreground: AppColors.surface,
                        leading: const Icon(Icons.schedule, size: 12, color: AppColors.surface),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (place.isNotEmpty)
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.md,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Frosted(
                  color: AppColors.textPrimary,
                  opacity: 0.5,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text('📍 $place', style: AppTextStyles.caption.copyWith(color: AppColors.surface, letterSpacing: 0.2)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Who posted it, in a frosted chip: their picture or initial and their name.
class _AuthorChip extends StatelessWidget {
  const _AuthorChip({required this.post});

  final StatusPost post;

  @override
  Widget build(BuildContext context) {
    return Frosted(
      color: AppColors.textPrimary,
      opacity: 0.45,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        children: [
          AvatarCircle(name: post.displayName, photoUrl: post.author.avatarUrl, size: 26),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyStrong.copyWith(fontSize: 12, color: AppColors.surface),
                ),
                Text(
                  post.audience == 'friends' ? context.l10n.csFriendsOnly : context.l10n.sdPublic,
                  style: AppTextStyles.body.copyWith(fontSize: 10, color: AppColors.surface.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CaptionStrip extends StatelessWidget {
  const _CaptionStrip({
    required this.post,
    required this.now,
    required this.isMine,
    required this.liked,
    required this.likes,
    required this.onLike,
    required this.onViewStall,
    required this.onDelete,
  });

  final StatusPost post;
  final DateTime now;
  final bool isMine;
  final bool liked;
  final int likes;
  final VoidCallback onLike;

  /// Null when the status is not about a stall.
  final VoidCallback? onViewStall;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final caption = post.caption?.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(post.displayName, style: AppTextStyles.display.copyWith(fontSize: 22, height: 1.2, letterSpacing: -0.4)),
            ),
            const SizedBox(width: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(post.postedAgoLabelAt(now), style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted)),
            ),
          ],
        ),
        if (caption.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(caption, style: AppTextStyles.body.copyWith(fontSize: 14, height: 1.5, color: AppColors.textPrimary)),
        ],
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _LikePill(liked: liked, count: likes, onTap: onLike),
            _CountPill(count: post.comments.isEmpty ? post.commentsCount : post.comments.length),
            if (isMine)
              OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: Text(context.l10n.sdDeleteStatus),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(color: AppColors.error.withValues(alpha: 0.6)),
                  shape: const StadiumBorder(),
                ),
              )
            else if (onViewStall != null)
              FilledButton(
                onPressed: onViewStall,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.surface,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                ),
                child: Text(context.l10n.sdViewStall, style: AppTextStyles.button.copyWith(fontSize: 12)),
              ),
          ],
        ),
      ],
    );
  }
}

class _LikePill extends StatelessWidget {
  const _LikePill({required this.liked, required this.count, required this.onTap});

  final bool liked;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: liked,
      label: context.l10n.sdLikeLabel,
      child: Material(
        color: liked ? AppColors.error.withValues(alpha: 0.1) : AppColors.surfaceMuted,
        shape: StadiumBorder(side: BorderSide(color: liked ? AppColors.error.withValues(alpha: 0.4) : Colors.transparent)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(liked ? '❤️' : '🤍', style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(context.l10n.sdLikes(count), style: AppTextStyles.bodyStrong.copyWith(fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('💬', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text('$count', style: AppTextStyles.bodyStrong.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}

class _Comments extends StatelessWidget {
  const _Comments({required this.post, required this.now});

  final StatusPost post;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.sdComments(post.comments.length),
          style: AppTextStyles.title.copyWith(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.md),
        if (post.comments.isEmpty)
          EmptyNote(context.l10n.sdNoComments)
        else
          for (final comment in post.comments) ...[
            _CommentCard(comment: comment, now: now),
            const SizedBox(height: AppSpacing.md),
          ],
      ],
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({required this.comment, required this.now});

  final StatusComment comment;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadii.softButton),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AvatarCircle(name: comment.authorName, photoUrl: comment.author?.avatarUrl, size: 34),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(comment.authorName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyStrong.copyWith(fontSize: 13)),
                    ),
                    const SizedBox(width: 6),
                    Text(agoFrom(comment.createdAt, now: now), style: AppTextStyles.body.copyWith(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(comment.body, style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.45, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The sticky bar: quick reactions (for someone else's status) above the comment field.
class _CommentBar extends StatefulWidget {
  const _CommentBar({
    required this.controller,
    required this.focusNode,
    required this.authorName,
    required this.authorPhoto,
    required this.hint,
    required this.reactions,
    required this.sending,
    required this.onSend,
  });

  /// The API's limit on a comment.
  static const maxLength = 300;

  final TextEditingController controller;
  final FocusNode focusNode;
  final String authorName;
  final String? authorPhoto;
  final String hint;
  final List<String> reactions;
  final bool sending;
  final ValueChanged<String> onSend;

  @override
  State<_CommentBar> createState() => _CommentBarState();
}

class _CommentBarState extends State<_CommentBar> {
  bool get _canSend => widget.controller.text.trim().isNotEmpty && !widget.sending;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.4))),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.sm, AppSpacing.screenPadding, AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.reactions.isNotEmpty) ...[
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.reactions.length,
                    separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, index) => ActionChip(
                      label: Text(widget.reactions[index], style: AppTextStyles.bodyStrong.copyWith(fontSize: 12)),
                      backgroundColor: AppColors.surfaceMuted,
                      side: BorderSide.none,
                      shape: const StadiumBorder(),
                      onPressed: widget.sending ? null : () => widget.onSend(widget.reactions[index]),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              Row(
                children: [
                  AvatarCircle(name: widget.authorName, photoUrl: widget.authorPhoto, size: 36),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: widget.focusNode,
                      maxLength: _CommentBar.maxLength,
                      textInputAction: TextInputAction.send,
                      textCapitalization: TextCapitalization.sentences,
                      cursorColor: AppColors.primary,
                      style: AppTextStyles.input,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (text) => widget.onSend(text),
                      buildCounter: (context, {required currentLength, required isFocused, required maxLength}) => null,
                      decoration: InputDecoration(
                        hintText: widget.hint,
                        hintStyle: AppTextStyles.hint,
                        filled: true,
                        fillColor: AppColors.surfaceMuted,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Material(
                    color: _canSend ? AppColors.secondary : AppColors.borderLight,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _canSend ? () => widget.onSend(widget.controller.text) : null,
                      child: SizedBox(
                        width: 42,
                        height: 42,
                        child: widget.sending
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textMuted),
                              )
                            : Icon(Icons.send_rounded, size: 20, color: _canSend ? AppColors.surface : AppColors.textMuted),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
