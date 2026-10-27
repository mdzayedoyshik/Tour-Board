import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/pickers.dart';
import '../../../core/widgets/states.dart';
import '../../expenses/presentation/expense_ui.dart';
import '../../membership/data/membership_repository.dart';
import '../data/packing_repository.dart';
import '../domain/packing_item.dart';

class PackingScreen extends ConsumerStatefulWidget {
  const PackingScreen({required this.tourId, super.key});

  final String tourId;

  @override
  ConsumerState<PackingScreen> createState() => _PackingScreenState();
}

class _PackingScreenState extends ConsumerState<PackingScreen> {
  final _input = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _guard(Future<Object?> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (mounted) showAppSnack(context, errorMessage(context, e), error: true);
    }
  }

  Future<void> _add() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    _focus.requestFocus();
    final uid = ref.read(currentUidProvider)!;
    await _guard(
      () => ref.read(packingRepositoryProvider).add(widget.tourId, text, uid),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = ref.watch(packingItemsProvider(widget.tourId));
    final permissions = ref.watch(permissionsProvider(widget.tourId));
    final members = ref.watch(memberMapProvider(widget.tourId));
    final active = ref.watch(activeMembersProvider(widget.tourId));
    final uid = ref.watch(currentUidProvider);
    final canEdit = permissions?.canEditPacking ?? false;
    final repo = ref.read(packingRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.packingTitle)),
      body: Column(
        children: [
          if (canEdit)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.sm,
                AppSpacing.page,
                AppSpacing.sm,
              ),
              child: TextField(
                controller: _input,
                focusNode: _focus,
                maxLength: PackingItem.maxLabelLength,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: l10n.packingAddHint,
                  counterText: '',
                  suffixIcon: IconButton(
                    tooltip: l10n.commonAdd,
                    icon: const Icon(Icons.add),
                    onPressed: _add,
                  ),
                ),
                onSubmitted: (_) => _add(),
              ),
            ),
          Expanded(
            child: AsyncValueView(
              value: items,
              onRetry: () =>
                  ref.invalidate(packingItemsProvider(widget.tourId)),
              data: (snap) {
                if (snap.items.isEmpty) {
                  return EmptyState(
                    icon: Icons.checklist_outlined,
                    title: l10n.packingEmpty,
                    message: l10n.packingEmptyBody,
                  );
                }
                final sorted = [...snap.items]
                  ..sort((a, b) {
                    if (a.checked != b.checked) return a.checked ? 1 : -1;
                    return a.createdAt.compareTo(b.createdAt);
                  });
                final done = sorted.where((i) => i.checked).length;
                return ContentWidth(
                  child: ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.page,
                        ),
                        child: Text(
                          l10n.packingProgress(done, sorted.length),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      for (final item in sorted)
                        CheckboxListTile(
                          value: item.checked,
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: canEdit
                              ? (v) => _guard(
                                  () => repo.setChecked(
                                    widget.tourId,
                                    item,
                                    v ?? false,
                                    uid!,
                                  ),
                                )
                              : null,
                          title: Text(
                            item.label,
                            style: TextStyle(
                              decoration: item.checked
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          subtitle:
                              item.assigneeUid == null && !item.hasPendingWrites
                              ? null
                              : Builder(
                                  builder: (context) {
                                    final text = [
                                      if (item.assigneeUid != null)
                                        l10n.packingAssignedTo(
                                          memberName(
                                            context,
                                            members,
                                            item.assigneeUid!,
                                            viewerUid: uid,
                                          ),
                                        ),
                                      if (item.hasPendingWrites)
                                        l10n.statePendingSync,
                                    ].join(' · ');
                                    return item.assigneeUid == null
                                        ? Text(text)
                                        : MemberCaption(
                                            members: members,
                                            uid: item.assigneeUid!,
                                            text: text,
                                          );
                                  },
                                ),
                          secondary: canEdit
                              ? PopupMenuButton<String>(
                                  tooltip: l10n.memberActions,
                                  onSelected: (action) async {
                                    if (action == 'assign') {
                                      // '' = unassign; null = dismissed.
                                      final picked = await pickFromList<String>(
                                        context,
                                        title: l10n.packingAssign,
                                        items: [
                                          '',
                                          ...active.map((m) => m.uid),
                                        ],
                                        label: (u) => u.isEmpty
                                            ? l10n.commonNone
                                            : memberName(context, members, u),
                                        leading: (u) => u.isEmpty
                                            ? const SizedBox.square(
                                                dimension: AppSizes.avatarSm,
                                                child: Icon(
                                                  Icons.person_off_outlined,
                                                ),
                                              )
                                            : MemberUidAvatar(
                                                members: members,
                                                uid: u,
                                              ),
                                      );
                                      if (!mounted || picked == null) return;
                                      await _guard(
                                        () => repo.assign(
                                          widget.tourId,
                                          item,
                                          picked.isEmpty ? null : picked,
                                        ),
                                      );
                                    } else if (action == 'delete') {
                                      await _guard(
                                        () =>
                                            repo.delete(widget.tourId, item.id),
                                      );
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'assign',
                                      child: Text(l10n.packingAssign),
                                    ),
                                    if (permissions!.canDeletePackingItem(
                                      item.createdBy,
                                    ))
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text(l10n.commonDelete),
                                      ),
                                  ],
                                )
                              : null,
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
