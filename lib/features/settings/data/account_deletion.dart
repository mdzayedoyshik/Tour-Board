import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../data/firebase/firestore_paths.dart';
import '../../auth/data/auth_repository.dart';
import '../../membership/data/membership_repository.dart';
import '../../membership/domain/member.dart';
import '../../notifications/data/inbox_repository.dart';
import '../../notifications/data/push_service.dart';
import '../../notifications/data/reminder_service.dart';

/// Tours that block deletion because the user is their only host.
class DeletionBlocker {
  const DeletionBlocker({required this.tourId, required this.tourName});
  final String tourId;
  final String tourName;
}

/// Client-only account deletion (no backend is available):
///
/// 0. Re-authenticate with Google (Firebase requires a recent sign-in).
/// 1. Refuse while the user hosts any tour — they must transfer hosting or
///    delete the (archived) tour first, so no tour is orphaned.
/// 2. Leave every other tour. Past expenses keep the UID and name snapshot
///    so the group's books stay consistent; that data is not erased.
/// 3. Delete the inbox, membership index and private profile.
/// 4. Delete the Firebase Auth user.
///
/// Join requests the user created stay readable only by that tour's
/// hosts/admins (rules do not let a requester delete them).
class AccountDeletionService {
  AccountDeletionService(this._ref);

  final Ref _ref;

  FirebaseFirestore get _db => _ref.read(firestoreProvider);

  Future<List<DeletionBlocker>> findBlockers(String uid) async {
    final index = await _db
        .collection(FirestorePaths.membershipIndex(uid))
        .limit(100)
        .get();
    final blockers = <DeletionBlocker>[];
    for (final entry in index.docs) {
      try {
        final tour = await _db.doc(FirestorePaths.tour(entry.id)).get();
        if (tour.exists && tour.data()!['hostUid'] == uid) {
          blockers.add(
            DeletionBlocker(
              tourId: entry.id,
              tourName: '${tour.data()!['name'] ?? ''}',
            ),
          );
        }
      } on FirebaseException {
        // Not readable any more: not a member, so not a blocker.
      }
    }
    return blockers;
  }

  Future<void> deleteAccount(String uid) async {
    final blockers = await findBlockers(uid);
    if (blockers.isNotEmpty) {
      throw StateError('User still hosts ${blockers.length} tour(s)');
    }
    final auth = _ref.read(authRepositoryProvider);
    await auth.reauthenticate();
    final membership = _ref.read(membershipRepositoryProvider);
    final index = await _db
        .collection(FirestorePaths.membershipIndex(uid))
        .limit(100)
        .get();
    for (final entry in index.docs) {
      final memberSnap = await _db
          .doc(FirestorePaths.member(entry.id, uid))
          .get();
      if (memberSnap.exists) {
        final me = Member.fromDoc(memberSnap.id, memberSnap.data()!);
        if (me.isActive) {
          await membership.leave(entry.id, me);
          continue;
        }
      }
      await entry.reference.delete();
    }
    await _ref.read(pushServiceProvider).stop();
    await _ref.read(inboxRepositoryProvider).deleteAll(uid);
    await _ref.read(reminderServiceProvider).cancelAll();
    await _db.doc(FirestorePaths.user(uid)).delete();
    await auth.deleteAuthUser();
  }
}

final accountDeletionProvider = Provider<AccountDeletionService>(
  AccountDeletionService.new,
);
