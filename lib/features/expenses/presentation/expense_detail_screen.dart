import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/routes.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/money/money.dart';
import '../../../core/money/split.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/states.dart';
import '../../membership/data/membership_repository.dart';
import '../../membership/domain/member.dart';
import '../data/expense_repository.dart';
import '../domain/expense.dart';
import 'expense_ui.dart';

final _revisionsProvider = FutureProvider.autoDispose
    .family<List<Revision>, ({String tourId, String expenseId, int count})>(
      (ref, key) => ref
          .watch(expenseRepositoryProvider)
          .fetchRevisions(key.tourId, key.expenseId),
    );

class ExpenseDetailScreen extends ConsumerWidget {
  const ExpenseDetailScreen({
    required this.tourId,
    required this.expenseId,
    super.key,
  });

  final String tourId;
  final String expenseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final expenses = ref.watch(expensesProvider(tourId));
    final members = ref.watch(memberMapProvider(tourId));
    final permissions = ref.watch(permissionsProvider(tourId));
    final uid = ref.watch(currentUidProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.expenseDetailTitle)),
      body: AsyncValueView(
        value: expenses,
        data: (snapshot) {
          final e = snapshot.items.where((x) => x.id == expenseId).firstOrNull;
          if (e == null) {
            return const ErrorState(error: AppException(AppErrorKind.notFound));
          }
          final canEdit =
              !e.isDeleted &&
              (permissions?.canEditExpense(e.createdBy) ?? false);
          return _Body(
            tourId: tourId,
            expense: e,
            members: members,
            uid: uid,
            canEdit: canEdit,
          );
        },
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({
    required this.tourId,
    required this.expense,
    required this.members,
    required this.uid,
    required this.canEdit,
  });

  final String tourId;
  final Expense expense;
  final Map<String, Member> members;
  final String? uid;
  final bool canEdit;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  bool _deleting = false;

  Future<void> _delete() async {
    final l10n = context.l10n;
    final ok = await confirmAction(
      context,
      title: l10n.expenseDeleteTitle,
      message: l10n.expenseDeleteBody,
      confirmLabel: l10n.commonDelete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _deleting = true);
    try {
      await ref
          .read(expenseRepositoryProvider)
          .softDelete(
            tourId: widget.tourId,
            expense: widget.expense,
            uid: widget.uid!,
          );
      if (mounted) showAppSnack(context, l10n.expenseDeleted);
    } catch (e) {
      if (mounted) showAppSnack(context, errorMessage(context, e), error: true);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  void _showEdits() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _RevisionsSheet(
        tourId: widget.tourId,
        expense: widget.expense,
        members: widget.members,
        viewerUid: widget.uid,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.expense;
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = context.localeTag;
    final muted = theme.colorScheme.onSurfaceVariant;
    String name(String uid) =>
        memberName(context, widget.members, uid, viewerUid: widget.uid);
    final participants = e.shares.keys.toList()
      ..sort((a, b) => name(a).compareTo(name(b)));

    return ContentWidth(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.page),
        children: [
          if (e.isDeleted)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: InlineBanner(
                icon: Icons.delete_outline,
                message: l10n.expenseDeletedBanner(
                  name(e.deletedBy ?? ''),
                  formatDateTime(context, e.deletedAt!),
                ),
              ),
            ),
          if (e.hasPendingWrites)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: InlineBanner(
                icon: Icons.cloud_upload_outlined,
                message: l10n.statePendingSync,
              ),
            ),
          Row(
            children: [
              CategoryIcon(e.category),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  e.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    decoration: e.isDeleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            formatMoney(e.amountMinor, e.currencyCode, locale: locale),
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${l10n.expensePaidBy(name(e.payerUid))} · '
            '${formatDateTime(context, e.occurredAt)}',
            style: theme.textTheme.bodyMedium?.copyWith(color: muted),
          ),
          Text(
            categoryLabel(l10n, e.category),
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
          if (e.isEdited) ...[
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                onPressed: _showEdits,
                child: Text(l10n.viewEdits),
              ),
            ),
          ],
          FormSectionLabel(
            '${l10n.expenseSplit} · ${_methodLabel(l10n, e.splitMethod)}',
          ),
          for (final uid in participants)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  MemberAvatar(
                    name: widget.members[uid]?.displayName ?? '?',
                    photoUrl: widget.members[uid]?.photoUrl,
                    size: AppSizes.avatarSm,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      e.splitMethod == SplitMethod.shares &&
                              e.splitWeights[uid] != null
                          ? '${name(uid)} · ${e.splitWeights[uid]}×'
                          : name(uid),
                    ),
                  ),
                  Text(
                    formatMoney(e.shares[uid]!, e.currencyCode, locale: locale),
                  ),
                ],
              ),
            ),
          if (!e.payerIsParticipant)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                l10n.expensePayerNotParticipant(name(e.payerUid)),
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
            ),
          if (e.note != null) ...[
            FormSectionLabel(l10n.expenseNote),
            Text(e.note!),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.expenseCreatedBy(
              name(e.createdBy),
              formatDateTime(context, e.createdAt),
            ),
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
          if (widget.canEdit) ...[
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: l10n.commonEdit,
              icon: Icons.edit_outlined,
              onPressed: () =>
                  context.push(Routes.editExpense(widget.tourId, e.id)),
            ),
            const SizedBox(height: AppSpacing.sm),
            DestructiveButton(
              label: l10n.commonDelete,
              icon: Icons.delete_outline,
              loading: _deleting,
              onPressed: _delete,
            ),
          ],
        ],
      ),
    );
  }
}

String _methodLabel(AppLocalizations l10n, SplitMethod m) => switch (m) {
  SplitMethod.equal => l10n.splitEqual,
  SplitMethod.custom => l10n.splitCustom,
  SplitMethod.shares => l10n.splitShares,
};

class _RevisionsSheet extends ConsumerWidget {
  const _RevisionsSheet({
    required this.tourId,
    required this.expense,
    required this.members,
    required this.viewerUid,
  });

  final String tourId;
  final Expense expense;
  final Map<String, Member> members;
  final String? viewerUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final revisions = ref.watch(
      _revisionsProvider((
        tourId: tourId,
        expenseId: expense.id,
        count: expense.revisionCount,
      )),
    );
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
            child: Text(
              l10n.viewEditsTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: AsyncValueView(
              value: revisions,
              data: (list) => ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.page),
                itemCount: list.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: AppSpacing.xl),
                itemBuilder: (context, i) => RevisionTile(
                  revision: list[i],
                  editorName: memberName(
                    context,
                    members,
                    list[i].editorUid,
                    viewerUid: viewerUid,
                  ),
                  describe: (field, value) => _describe(context, field, value),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _describe(BuildContext context, String field, Object? value) {
    final l10n = context.l10n;
    if (value == null) return '—';
    return switch (field) {
      'amountMinor' when value is num => formatMoney(
        value.toInt(),
        expense.currencyCode,
        locale: context.localeTag,
      ),
      'payerUid' when value is String => memberName(
        context,
        members,
        value,
        viewerUid: viewerUid,
      ),
      'category' when value is String => categoryLabel(
        l10n,
        expenseCategoryFromName(value),
      ),
      'occurredAt' when value is Timestamp => formatDateTime(
        context,
        value.toDate(),
      ),
      'splitMethod' when value is String => _methodLabel(
        l10n,
        splitMethodFromName(value),
      ),
      'shares' || 'splitWeights' => l10n.revisionSplitChanged,
      'deleted' => value == true ? l10n.stateDeleted : '—',
      _ => '$value',
    };
  }
}

/// One revision: who, when, and compact before → after values.
class RevisionTile extends StatelessWidget {
  const RevisionTile({
    required this.revision,
    required this.editorName,
    required this.describe,
    super.key,
  });

  final Revision revision;
  final String editorName;
  final String Function(String field, Object? value) describe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.revisionBy(
            editorName,
            formatDateTime(context, revision.editedAt),
          ),
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final f in revision.changedFields)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xxs),
            child: Text(
              f == 'shares' || f == 'splitWeights' || f == 'deleted'
                  ? '${_fieldLabel(l10n, f)}: ${describe(f, revision.after[f])}'
                  : '${_fieldLabel(l10n, f)}: ${describe(f, revision.before[f])}'
                        ' → ${describe(f, revision.after[f])}',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        if (revision.reason != null)
          Text(
            revision.reason!,
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  static String _fieldLabel(AppLocalizations l10n, String field) =>
      switch (field) {
        'title' => l10n.fieldTitle,
        'amountMinor' => l10n.amountLabel,
        'currencyCode' => l10n.currencyLabel,
        'payerUid' => l10n.expensePayer,
        'shares' || 'splitWeights' => l10n.expenseSplit,
        'splitMethod' => l10n.fieldSplitMethod,
        'category' => l10n.expenseCategory,
        'occurredAt' => l10n.expenseDate,
        'note' => l10n.expenseNote,
        'body' => l10n.fieldBody,
        'deleted' => l10n.fieldStatus,
        _ => field,
      };
}
