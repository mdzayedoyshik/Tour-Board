import 'package:flutter/material.dart';
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
import '../../../data/firebase/firestore_streams.dart';
import '../../expenses/domain/expense.dart';
import '../../expenses/presentation/expense_detail_screen.dart';
import '../../expenses/presentation/expense_ui.dart';
import '../../membership/data/membership_repository.dart';
import '../data/notes_repository.dart';
import '../domain/note.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({required this.tourId, super.key});

  final String tourId;

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  /// Older pages fetched on demand; the first page stays live.
  final List<Note> _older = [];
  bool _loadingMore = false;
  bool _exhausted = false;

  Future<void> _loadMore(List<Note> live) async {
    if (_loadingMore) return;
    final all = [...live, ..._older];
    if (all.isEmpty) return;
    setState(() => _loadingMore = true);
    try {
      final page = await ref
          .read(notesRepositoryProvider)
          .fetchOlder(widget.tourId, all.last.updatedAt);
      setState(() {
        _older.addAll(page);
        _exhausted = page.length < Note.pageSize;
      });
    } catch (e) {
      if (mounted) showAppSnack(context, errorMessage(context, e), error: true);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final notes = ref.watch(recentNotesProvider(widget.tourId));
    final members = ref.watch(memberMapProvider(widget.tourId));
    final permissions = ref.watch(permissionsProvider(widget.tourId));
    final uid = ref.watch(currentUidProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notesTitle)),
      floatingActionButton: permissions?.canAddContent ?? false
          ? FloatingActionButton(
              tooltip: l10n.noteAdd,
              onPressed: () => context.push(Routes.newNote(widget.tourId)),
              child: const Icon(Icons.add),
            )
          : null,
      body: AsyncValueView(
        value: notes,
        onRetry: () => ref.invalidate(recentNotesProvider(widget.tourId)),
        data: (snap) {
          final liveIds = snap.items.map((n) => n.id).toSet();
          final all = [
            ...snap.items,
            ..._older.where((n) => !liveIds.contains(n.id)),
          ];
          if (all.isEmpty) {
            return EmptyState(
              icon: Icons.sticky_note_2_outlined,
              title: l10n.notesEmptyTitle,
              message: l10n.notesEmptyBody,
            );
          }
          return ContentWidth(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: all.length + 1,
              itemBuilder: (context, i) {
                if (i == all.length) {
                  if (!snap.hasMore || _exhausted) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.page),
                    child: SecondaryButton(
                      label: l10n.commonLoadMore,
                      loading: _loadingMore,
                      onPressed: () => _loadMore(snap.items),
                    ),
                  );
                }
                final note = all[i];
                return ListTile(
                  onTap: () =>
                      context.push(Routes.note(widget.tourId, note.id)),
                  leading: MemberUidAvatar(
                    members: members,
                    uid: note.createdBy,
                  ),
                  title: Text(
                    note.title ?? note.body,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    [
                      if (note.title != null) note.body,
                      memberName(
                        context,
                        members,
                        note.createdBy,
                        viewerUid: uid,
                      ),
                      formatShortDate(context, note.updatedAt),
                      if (note.isEdited) l10n.stateEdited,
                      if (note.hasPendingWrites) l10n.statePendingSync,
                    ].join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// Read a note; edit/delete per permissions; "View edits" when revised.
class NoteDetailScreen extends ConsumerWidget {
  const NoteDetailScreen({
    required this.tourId,
    required this.noteId,
    super.key,
  });

  final String tourId;
  final String noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final noteAsync = ref.watch(noteProvider((tourId: tourId, noteId: noteId)));
    final members = ref.watch(memberMapProvider(tourId));
    final permissions = ref.watch(permissionsProvider(tourId));
    final uid = ref.watch(currentUidProvider);

    return Builder(
      builder: (context) {
        final note = noteAsync.value;
        final canEdit =
            note != null &&
            (permissions?.canEditContent(note.createdBy) ?? false);
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.noteTitle),
            actions: [
              if (canEdit)
                IconButton(
                  tooltip: l10n.commonEdit,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          NoteEditorScreen(tourId: tourId, note: note),
                    ),
                  ),
                ),
              if (canEdit)
                IconButton(
                  tooltip: l10n.commonDelete,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final ok = await confirmAction(
                      context,
                      title: l10n.noteDeleteTitle,
                      confirmLabel: l10n.commonDelete,
                      destructive: true,
                    );
                    if (!ok) return;
                    try {
                      await ref
                          .read(notesRepositoryProvider)
                          .delete(tourId, note);
                      if (context.mounted) context.pop();
                    } catch (e) {
                      if (context.mounted) {
                        showAppSnack(
                          context,
                          errorMessage(context, e),
                          error: true,
                        );
                      }
                    }
                  },
                ),
            ],
          ),
          body: switch (noteAsync) {
            AsyncError(:final error) => ErrorState(error: error),
            AsyncData() when note == null => const ErrorState(
              error: AppException(AppErrorKind.notFound),
            ),
            _ when note == null => const LoadingView(),
            _ => ContentWidth(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.page),
                children: [
                  if (note.title != null)
                    Text(
                      note.title!,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  SelectableText(note.body),
                  const SizedBox(height: AppSpacing.lg),
                  MemberCaption(
                    members: members,
                    uid: note.createdBy,
                    text: l10n.expenseCreatedBy(
                      memberName(
                        context,
                        members,
                        note.createdBy,
                        viewerUid: uid,
                      ),
                      formatDateTime(context, note.createdAt),
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (note.isEdited)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton(
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        onPressed: () => _showEdits(context, ref, note),
                        child: Text(l10n.viewEdits),
                      ),
                    ),
                ],
              ),
            ),
          },
        );
      },
    );
  }

  void _showEdits(BuildContext context, WidgetRef ref, Note note) {
    final members = ref.read(memberMapProvider(tourId));
    final uid = ref.read(currentUidProvider);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: FutureBuilder<List<Revision>>(
          future: ref
              .read(notesRepositoryProvider)
              .fetchRevisions(tourId, note.id),
          builder: (context, snap) {
            if (snap.hasError) return ErrorState(error: snap.error!);
            if (!snap.hasData) return const LoadingView();
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.page),
              itemCount: snap.data!.length,
              separatorBuilder: (_, _) => const Divider(height: AppSpacing.xl),
              itemBuilder: (context, i) => RevisionTile(
                revision: snap.data![i],
                editorAvatar: MemberUidAvatar(
                  members: members,
                  uid: snap.data![i].editorUid,
                  size: AppSizes.avatarXs,
                ),
                editorName: memberName(
                  context,
                  members,
                  snap.data![i].editorUid,
                  viewerUid: uid,
                ),
                describe: (_, value) => value == null ? '—' : '$value',
              ),
            );
          },
        ),
      ),
    );
  }
}

class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({required this.tourId, this.note, super.key});

  final String tourId;
  final Note? note;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late final TextEditingController _title = TextEditingController(
    text: widget.note?.title,
  );
  late final TextEditingController _body = TextEditingController(
    text: widget.note?.body,
  );
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || _body.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final l10n = context.l10n;
    final repo = ref.read(notesRepositoryProvider);
    final uid = ref.read(currentUidProvider)!;
    try {
      final note = widget.note;
      if (note == null) {
        final outcome = await repo.add(
          widget.tourId,
          title: _title.text,
          body: _body.text,
          uid: uid,
        );
        if (mounted && outcome == WriteOutcome.pendingSync) {
          showAppSnack(context, l10n.stateSavedOffline);
        }
      } else {
        await repo.edit(
          widget.tourId,
          note,
          title: _title.text,
          body: _body.text,
          uid: uid,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      final message = classifyError(e) == AppErrorKind.conflict
          ? l10n.noteConflict
          : errorMessage(context, e);
      showAppSnack(context, message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? l10n.noteAdd : l10n.noteEdit),
      ),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: [
            TextField(
              controller: _title,
              maxLength: Note.maxTitleLength,
              decoration: InputDecoration(labelText: l10n.noteTitleLabel),
            ),
            TextField(
              controller: _body,
              autofocus: widget.note == null,
              maxLength: Note.maxBodyLength,
              minLines: 5,
              maxLines: 14,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.noteBodyLabel),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: l10n.commonSave,
              loading: _saving,
              onPressed: _body.text.trim().isEmpty ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
