import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/routes.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/states.dart';
import '../../auth/data/auth_repository.dart';
import '../data/membership_repository.dart';
import '../domain/invite_code.dart';
import '../domain/member.dart';

final _ownRequestProvider = StreamProvider.autoDispose
    .family<JoinRequest?, String>((ref, tourId) {
      final uid = ref.watch(currentUidProvider);
      if (uid == null) return Stream.value(null);
      return ref
          .watch(membershipRepositoryProvider)
          .watchOwnRequest(tourId, uid);
    });

/// Join with an invite link or code: preview → request → status.
class JoinScreen extends ConsumerStatefulWidget {
  const JoinScreen({this.initialCode, super.key});

  final String? initialCode;

  @override
  ConsumerState<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends ConsumerState<JoinScreen> {
  late final TextEditingController _input;
  InvitePreview? _invite;
  String? _error;
  bool _looking = false;
  bool _requesting = false;

  @override
  void initState() {
    super.initState();
    _input = TextEditingController(text: widget.initialCode);
    if (widget.initialCode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _lookup());
    }
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null) return;
    _input.text = text.trim();
    await _lookup();
  }

  Future<void> _lookup() async {
    final l10n = context.l10n;
    final code = InviteCodes.parse(_input.text);
    if (code == null) {
      setState(() {
        _invite = null;
        _error = l10n.joinInvalidCode;
      });
      return;
    }
    setState(() {
      _looking = true;
      _error = null;
    });
    try {
      final invite = await ref
          .read(membershipRepositoryProvider)
          .fetchInvite(code);
      if (!mounted) return;
      final now = ref.read(clockProvider)().toUtc();
      setState(() {
        if (invite == null) {
          _invite = null;
          _error = l10n.joinCodeNotFound;
        } else if (!invite.isUsable(now)) {
          _invite = null;
          _error = l10n.joinCodeExpired;
        } else {
          _invite = invite;
        }
      });
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(context, e));
    } finally {
      if (mounted) setState(() => _looking = false);
    }
  }

  Future<void> _request() async {
    final invite = _invite;
    if (invite == null || _requesting) return;
    setState(() => _requesting = true);
    try {
      final user = ref.read(authRepositoryProvider).currentUser!;
      final profile = ref.read(profileProvider).value;
      await ref
          .read(membershipRepositoryProvider)
          .requestToJoin(
            invite: invite,
            uid: user.uid,
            displayName: profile?.displayName ?? user.displayName ?? '—',
            photoUrl: profile?.photoUrl ?? user.photoURL,
          );
    } catch (e) {
      if (!mounted) return;
      final message = classifyError(e) == AppErrorKind.quota
          ? context.l10n.joinTooManyAttempts
          : errorMessage(context, e);
      showAppSnack(context, message, error: true);
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final invite = _invite;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.joinTitle)),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: [
            Text(
              l10n.joinIntro,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _input,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: l10n.joinCodeLabel,
                hintText: 'XXXX-XXXX-XXXX',
                errorText: _error,
                suffixIcon: IconButton(
                  tooltip: l10n.joinPaste,
                  icon: const Icon(Icons.content_paste),
                  onPressed: _paste,
                ),
              ),
              onSubmitted: (_) => _lookup(),
            ),
            const SizedBox(height: AppSpacing.md),
            SecondaryButton(
              label: l10n.joinFind,
              loading: _looking,
              onPressed: _lookup,
            ),
            if (invite != null) ...[
              const SizedBox(height: AppSpacing.xl),
              _InvitePreviewCard(
                invite: invite,
                requesting: _requesting,
                onRequest: _request,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InvitePreviewCard extends ConsumerWidget {
  const _InvitePreviewCard({
    required this.invite,
    required this.requesting,
    required this.onRequest,
  });

  final InvitePreview invite;
  final bool requesting;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final member = ref.watch(myMemberProvider(invite.tourId));
    final request = ref.watch(_ownRequestProvider(invite.tourId));

    Widget action;
    if (member.value?.isActive ?? false) {
      action = PrimaryButton(
        label: l10n.joinOpenTour,
        onPressed: () => context.go(Routes.tour(invite.tourId)),
      );
    } else {
      final r = request.value;
      action = switch (r?.status) {
        JoinRequestStatus.pending => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InlineBanner(icon: Icons.hourglass_top, message: l10n.joinPending),
            const SizedBox(height: AppSpacing.md),
            SecondaryButton(
              label: l10n.joinCancelRequest,
              onPressed: () => ref
                  .read(membershipRepositoryProvider)
                  .cancelRequest(invite.tourId, r!.uid)
                  .catchError((Object e) {
                    if (context.mounted) {
                      showAppSnack(
                        context,
                        errorMessage(context, e),
                        error: true,
                      );
                    }
                  }),
            ),
          ],
        ),
        JoinRequestStatus.approved when member.value?.isActive ?? false =>
          PrimaryButton(
            label: l10n.joinOpenTour,
            onPressed: () => context.go(Routes.tour(invite.tourId)),
          ),
        JoinRequestStatus.rejected => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InlineBanner(
              icon: Icons.block,
              message: l10n.joinRejected,
              color: StatusColors.of(context).error,
            ),
            if (r!.canRetry) ...[
              const SizedBox(height: AppSpacing.md),
              SecondaryButton(
                label: l10n.joinRequestAgain,
                loading: requesting,
                onPressed: onRequest,
              ),
            ],
          ],
        ),
        _ when r != null && !r.canRetry => InlineBanner(
          icon: Icons.block,
          message: l10n.joinTooManyAttempts,
        ),
        _ => PrimaryButton(
          label: l10n.joinRequest,
          loading: requesting,
          onPressed: onRequest,
        ),
      };
    }

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(invite.tourName, style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            formatTripRange(context, invite.startAt, invite.endAt),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.joinHostedBy(invite.hostName),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          action,
        ],
      ),
    );
  }
}
