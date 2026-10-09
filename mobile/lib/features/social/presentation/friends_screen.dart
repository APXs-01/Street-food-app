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
import '../../auth/presentation/widgets/surface_card.dart';
import '../../consumer/vendor_profile/widgets/avatar_circle.dart';
import '../data/social_models.dart';
import '../providers/social_providers.dart';

enum _Tab { add, requests, friends }

/// Add Friends & Foodie Network, on the real friends API: find a customer by
/// their exact username and send a request, answer the requests sent to you, and
/// manage your friends.
///
/// Not offered, because the API has none of it: suggestions, search by name,
/// phone or contacts, QR codes, a list of requests you sent, and chat.
class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  final _username = TextEditingController();
  _Tab _tab = _Tab.add;

  /// The last lookup: null before one, a [Foodie] if found.
  Foodie? _found;
  String? _lookupMessage;
  bool _looking = false;
  bool _sending = false;

  @override
  void dispose() {
    _username.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _lookup() async {
    final text = _username.text.trim().replaceFirst(RegExp(r'^@'), '');
    if (text.isEmpty || _looking) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _looking = true;
      _found = null;
      _lookupMessage = null;
    });

    try {
      final person = await ref.read(friendRepositoryProvider).lookup(text);

      if (!mounted) return;

      setState(() {
        _found = person;
        _lookupMessage = person == null ? l10n.frNoUser(text) : null;
        _looking = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _lookupMessage = errorMessage(error);
        _looking = false;
      });
    }
  }

  Future<void> _sendRequest(Foodie person) async {
    final username = person.username;
    if (username == null || _sending) return;

    setState(() => _sending = true);

    try {
      await ref.read(friendRepositoryProvider).send(username);
      if (!mounted) return;

      refreshFriends(ref);
      setState(() {
        _sending = false;
        _found = null;
        _username.clear();
      });
      _toast(l10n.frRequestSent(person.name));
    } catch (error) {
      if (!mounted) return;

      setState(() => _sending = false);
      _toast(errorMessage(error));
    }
  }

  Future<void> _respond(Friendship request, {required bool accept}) async {
    try {
      await ref.read(friendRepositoryProvider).respond(request.id, accept: accept);
      if (!mounted) return;

      refreshFriends(ref);
      _toast(accept ? l10n.frNowFriends(request.person.name) : l10n.frDeclined);
    } catch (error) {
      if (mounted) _toast(errorMessage(error));
    }
  }

  Future<void> _remove(Friendship friendship) async {
    try {
      await ref.read(friendRepositoryProvider).remove(friendship.id);
      if (!mounted) return;

      refreshFriends(ref);
      _toast(l10n.frRemoved(friendship.person.name));
    } catch (error) {
      if (mounted) _toast(errorMessage(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final friends = ref.watch(friendsProvider);
    final requests = ref.watch(friendRequestsProvider);

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
                    onPressed: () => context.canPop() ? context.pop() : context.go(Routes.consumerProfile),
                  ),
                  Expanded(child: Text(context.l10n.frTitle, style: AppTextStyles.title.copyWith(fontSize: 20, fontWeight: FontWeight.w800))),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.xs, AppSpacing.screenPadding, AppSpacing.md),
              child: _Tabs(
                current: _tab,
                requests: requests.asData?.value.length,
                friends: friends.asData?.value.length,
                onChanged: (tab) => setState(() => _tab = tab),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  refreshFriends(ref);
                  await ref.read(friendsProvider.future).then((_) {}, onError: (_) {});
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 0, AppSpacing.screenPadding, AppSpacing.xxl),
                  children: [
                    if (_tab == _Tab.add) ..._addTab(),
                    if (_tab == _Tab.requests)
                      AsyncView<List<Friendship>>(
                        value: requests,
                        onRetry: () => ref.invalidate(friendRequestsProvider),
                        builder: (list) => list.isEmpty
                            ? EmptyNote(context.l10n.frNoRequests)
                            : Column(
                                children: [
                                  for (final request in list) ...[
                                    _RequestCard(
                                      request: request,
                                      onAccept: () => _respond(request, accept: true),
                                      onDecline: () => _respond(request, accept: false),
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                  ],
                                ],
                              ),
                      ),
                    if (_tab == _Tab.friends)
                      AsyncView<List<Friendship>>(
                        value: friends,
                        onRetry: () => ref.invalidate(friendsProvider),
                        builder: (list) => Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(context.l10n.frActiveFriends, style: AppTextStyles.title.copyWith(fontSize: 16, fontWeight: FontWeight.w800))),
                                PillBadge(
                                  label: context.l10n.profConnected(list.length),
                                  background: AppColors.successBg,
                                  foreground: AppColors.successText,
                                  borderColor: AppColors.successBorder,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            if (list.isEmpty)
                              EmptyNote(context.l10n.frNoFriends)
                            else
                              for (final friendship in list) ...[
                                _FriendRow(friendship: friendship, onRemove: () => _remove(friendship)),
                                const SizedBox(height: AppSpacing.md),
                              ],
                          ],
                        ),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    const _TipCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _addTab() {
    final found = _found;

    return [
      Text(context.l10n.frFindTitle, style: AppTextStyles.title.copyWith(fontSize: 16, fontWeight: FontWeight.w800)),
      const SizedBox(height: 2),
      Text(
        context.l10n.frFindSub,
        style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted),
      ),
      const SizedBox(height: AppSpacing.md),
      Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.pill),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
              ),
              child: TextField(
                controller: _username,
                onSubmitted: (_) => _lookup(),
                textInputAction: TextInputAction.search,
                autocorrect: false,
                cursorColor: AppColors.secondary,
                style: AppTextStyles.input,
                decoration: InputDecoration(
                  hintText: context.l10n.frUsernameHint,
                  hintStyle: AppTextStyles.hint,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  prefixIcon: const Icon(Icons.alternate_email, color: AppColors.textMuted),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton(
            onPressed: _looking ? null : _lookup,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.surface,
              shape: const StadiumBorder(),
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 18),
            ),
            child: _looking
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.surface))
                : Text(context.l10n.frFind, style: AppTextStyles.button.copyWith(fontSize: 13)),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      if (_lookupMessage != null) EmptyNote(_lookupMessage!),
      if (found != null)
        SurfaceCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              AvatarCircle(name: found.name, photoUrl: found.avatarUrl, size: 46),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(found.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyStrong),
                    Text(found.atHandle, style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton.icon(
                onPressed: _sending ? null : () => _sendRequest(found),
                icon: const Icon(Icons.add, size: 16),
                label: Text(context.l10n.frAdd, style: AppTextStyles.button.copyWith(fontSize: 12)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.surface,
                  shape: const StadiumBorder(),
                  minimumSize: const Size(0, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
              ),
            ],
          ),
        ),
    ];
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.current, required this.requests, required this.friends, required this.onChanged});

  final _Tab current;

  /// Null while loading: no count is shown.
  final int? requests;
  final int? friends;
  final ValueChanged<_Tab> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget tab(_Tab value, String label, {int? count, bool amberBadge = false}) {
      final selected = value == current;

      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          label: label,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? AppColors.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                boxShadow: selected ? const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))] : null,
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        count == null ? label : '$label ($count)',
                        style: AppTextStyles.bodyStrong.copyWith(fontSize: 12, color: selected ? AppColors.secondary : AppColors.textMuted),
                      ),
                      if (amberBadge && (count ?? 0) > 0) ...[
                        const SizedBox(width: 5),
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.amber, shape: BoxShape.circle)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.borderLight, borderRadius: BorderRadius.circular(999)),
      child: Row(
        children: [
          tab(_Tab.add, context.l10n.frTabAdd),
          tab(_Tab.requests, context.l10n.frTabRequests, count: requests, amberBadge: true),
          tab(_Tab.friends, context.l10n.frTabFriends, count: friends),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.onAccept, required this.onDecline});

  final Friendship request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final person = request.person;

    return SurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Row(
            children: [
              AvatarCircle(name: person.name, photoUrl: person.avatarUrl, size: 46),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(person.name, style: AppTextStyles.bodyStrong),
                    Text(person.atHandle, style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              Text(agoFrom(request.createdAt), style: AppTextStyles.body.copyWith(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onAccept,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.surface,
                    shape: const StadiumBorder(),
                    minimumSize: const Size(0, 42),
                  ),
                  child: Text(context.l10n.frAccept, style: AppTextStyles.button.copyWith(fontSize: 13)),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlinedButton(
                  onPressed: onDecline,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: BorderSide(color: AppColors.border.withValues(alpha: 0.9)),
                    shape: const StadiumBorder(),
                    minimumSize: const Size(0, 42),
                  ),
                  child: Text(context.l10n.frDecline, style: AppTextStyles.button.copyWith(fontSize: 13, color: AppColors.textSecondary)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FriendRow extends StatelessWidget {
  const _FriendRow({required this.friendship, required this.onRemove});

  final Friendship friendship;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final person = friendship.person;
    final since = friendship.respondedAt ?? friendship.createdAt;

    return SurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.primaryLight, width: 2)),
            child: AvatarCircle(name: person.name, photoUrl: person.avatarUrl, size: 42),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(person.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyStrong),
                Text(person.atHandle, style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted)),
                if (since != null)
                  Text(
                    context.l10n.frFriendsSince(agoFrom(since)),
                    style: AppTextStyles.body.copyWith(fontSize: 11, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: context.l10n.frMoreOptions,
            icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
            onSelected: (value) {
              if (value == 'remove') onRemove();
            },
            itemBuilder: (context) => [PopupMenuItem(value: 'remove', child: Text(context.l10n.frRemoveFriend))],
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.successBg,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.successBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, color: AppColors.secondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.frTipTitle, style: AppTextStyles.bodyStrong.copyWith(color: AppColors.successText)),
                const SizedBox(height: 2),
                Text(
                  context.l10n.frTipBody,
                  style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.successText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
