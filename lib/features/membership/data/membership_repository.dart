import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/errors/app_error.dart';
import '../../../data/firebase/firestore_paths.dart';
import '../../../data/firebase/firestore_streams.dart';
import '../../activity_feed/data/feed_repository.dart';
import '../../activity_feed/domain/feed_event.dart';
import '../../notifications/data/inbox_repository.dart';
import '../../notifications/domain/inbox_item.dart';
import '../../tours/data/tour_repository.dart';
import '../../tours/domain/tour.dart';
import '../domain/invite_code.dart';
import '../domain/member.dart';
import '../domain/permissions.dart';

/// Join requests, approvals and member management.
///
/// Membership changes always require the server: they use transactions or
/// awaited batches (which fail offline) so the UI never reports an approval
/// that has not actually happened.
class MembershipRepository {
  MembershipRepository(this._db, this._feed, this._inbox);

  final FirebaseFirestore _db;
  final FeedRepository _feed;
  final InboxRepository _inbox;

  static const _timeout = Duration(seconds: 20);

  DocumentReference<Map<String, dynamic>> _member(String t, String u) =>
      _db.doc(FirestorePaths.member(t, u));
  DocumentReference<Map<String, dynamic>> _request(String t, String u) =>
      _db.doc(FirestorePaths.joinRequest(t, u));
  DocumentReference<Map<String, dynamic>> _index(String u, String t) =>
      _db.doc(FirestorePaths.membershipIndexEntry(u, t));

  Stream<List<Member>> watchMembers(String tourId) => watchQuery(
    _db.collection(FirestorePaths.members(tourId)),
    (doc) => Member.fromDoc(doc.id, doc.data()),
    limit: Tour.maxMembers * 2,
  ).map((s) => s.items);

  /// Own member record; readable even after removal so the UI can explain.
  Stream<Member?> watchOwnMember(String tourId, String uid) => watchDoc(
    _member(tourId, uid),
    (doc) => Member.fromDoc(doc.id, doc.data()!),
  );

  // --- Invites and requests --------------------------------------------

  /// Looks up an invite by code. Returns null when the code does not exist.
  /// Always reads from the server so a revoked invite is never trusted from
  /// cache.
  Future<InvitePreview?> fetchInvite(String code) async {
    final snap = await _db
        .doc('${FirestorePaths.invites}/$code')
        .get(const GetOptions(source: Source.server))
        .timeout(_timeout);
    if (!snap.exists) return null;
    return InvitePreview.fromDoc(snap.id, snap.data()!);
  }

  Stream<JoinRequest?> watchOwnRequest(String tourId, String uid) => watchDoc(
    _request(tourId, uid),
    (doc) => JoinRequest.fromDoc(doc.id, doc.data()!),
  );

  /// Creates or retries the caller's join request. Uses a transaction so it
  /// fails cleanly offline instead of queueing.
  Future<void> requestToJoin({
    required InvitePreview invite,
    required String uid,
    required String displayName,
    String? photoUrl,
  }) async {
    final ref = _request(invite.tourId, uid);
    await _db
        .runTransaction((tx) async {
          final existing = await tx.get(ref);
          if (!existing.exists) {
            tx.set(ref, {
              'uid': uid,
              'displayNameSnapshot': displayName,
              'photoUrlSnapshot': ?photoUrl,
              'status': 'pending',
              'attemptCount': 1,
              'inviteCode': invite.code,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
            return;
          }
          final request = JoinRequest.fromDoc(existing.id, existing.data()!);
          if (request.status == JoinRequestStatus.pending) return;
          if (!request.canRetry) {
            throw const AppException(AppErrorKind.quota, 'join attempts');
          }
          tx.update(ref, {
            'status': 'pending',
            'attemptCount': request.attemptCount + 1,
            'inviteCode': invite.code,
            'displayNameSnapshot': displayName,
            'photoUrlSnapshot': photoUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        })
        .timeout(_timeout);

    await _inbox.notify(
      recipientUids: [invite.hostUid],
      type: InboxType.joinRequest,
      tourId: invite.tourId,
      tourName: invite.tourName,
      senderUid: uid,
      senderName: displayName,
    );
  }

  Future<void> cancelRequest(String tourId, String uid) => _request(tourId, uid)
      .update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      })
      .timeout(_timeout);

  Stream<List<JoinRequest>> watchPendingRequests(String tourId) => watchQuery(
    _db
        .collection(FirestorePaths.joinRequests(tourId))
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt'),
    (doc) => JoinRequest.fromDoc(doc.id, doc.data()),
    limit: 50,
  ).map((s) => s.items);

  /// Approves atomically: request status, member record, tour membership
  /// list (first-time members only) and the requester's Home index.
  /// Idempotent — approving an already-approved request is a no-op.
  Future<void> approve({
    required Tour tour,
    required JoinRequest request,
    required String reviewerUid,
    required String reviewerName,
    required int activeMemberCount,
  }) async {
    if (activeMemberCount >= Tour.maxMembers) {
      throw const AppException(AppErrorKind.quota, 'member cap');
    }
    final tourRef = _db.doc(FirestorePaths.tour(tour.id));
    final requestRef = _request(tour.id, request.uid);
    final memberRef = _member(tour.id, request.uid);

    final approved = await _db
        .runTransaction((tx) async {
          final req = await tx.get(requestRef);
          if (!req.exists) throw const AppException(AppErrorKind.notFound);
          if (req.data()!['status'] != 'pending') return false;
          final memberSnap = await tx.get(memberRef);
          final tourSnap = await tx.get(tourRef);
          final everMembers = List<String>.from(
            tourSnap.data()?['allMemberUids'] as List? ?? const [],
          );

          tx.update(requestRef, {
            'status': 'approved',
            'reviewedBy': reviewerUid,
            'reviewedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          final memberFields = {
            'uid': request.uid,
            'displayNameSnapshot': request.displayName,
            'photoUrlSnapshot': request.photoUrl,
            'role': 'member',
            'status': 'active',
            'joinedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          };
          if (memberSnap.exists) {
            // Re-admission of a former member keeps the same record.
            tx.update(memberRef, {...memberFields, 'removedAt': null});
          } else {
            tx.set(memberRef, memberFields);
          }
          if (!everMembers.contains(request.uid)) {
            tx.update(tourRef, {
              'allMemberUids': [...everMembers, request.uid],
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
          tx.set(_index(request.uid, tour.id), {
            'tourId': tour.id,
            'joinedAt': FieldValue.serverTimestamp(),
          });
          return true;
        })
        .timeout(_timeout);

    if (!approved) return;
    await Future.wait([
      _feed.record(
        tour.id,
        type: FeedEventType.memberJoined,
        actorUid: reviewerUid,
        subjectUid: request.uid,
        label: request.displayName,
      ),
      _inbox.notify(
        recipientUids: [request.uid],
        type: InboxType.joinApproved,
        tourId: tour.id,
        tourName: tour.name,
        senderUid: reviewerUid,
        senderName: reviewerName,
      ),
    ]);
  }

  Future<void> reject({
    required Tour tour,
    required JoinRequest request,
    required String reviewerUid,
    required String reviewerName,
  }) async {
    final ref = _request(tour.id, request.uid);
    final rejected = await _db
        .runTransaction((tx) async {
          final snap = await tx.get(ref);
          if (!snap.exists || snap.data()!['status'] != 'pending') return false;
          tx.update(ref, {
            'status': 'rejected',
            'reviewedBy': reviewerUid,
            'reviewedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          return true;
        })
        .timeout(_timeout);
    if (!rejected) return;
    await _inbox.notify(
      recipientUids: [request.uid],
      type: InboxType.joinRejected,
      tourId: tour.id,
      tourName: tour.name,
      senderUid: reviewerUid,
      senderName: reviewerName,
    );
  }

  // --- Member management --------------------------------------------------

  /// Removes access immediately. Past expenses keep the member's UID and
  /// name snapshot; their balance stays visible so the host can settle it.
  Future<void> removeMember(Tour tour, Member member, String actorUid) async {
    final batch = _db.batch()
      ..update(_member(tour.id, member.uid), {
        'status': 'removed',
        'removedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      })
      ..delete(_index(member.uid, tour.id))
      ..set(
        _feed.newRef(tour.id),
        _feed.eventData(
          type: FeedEventType.memberRemoved,
          actorUid: actorUid,
          subjectUid: member.uid,
          label: member.displayName,
        ),
      );
    await batch.commit().timeout(_timeout);
  }

  Future<void> leave(String tourId, Member me) async {
    final batch = _db.batch()
      ..set(
        _feed.newRef(tourId),
        _feed.eventData(
          type: FeedEventType.memberLeft,
          actorUid: me.uid,
          label: me.displayName,
        ),
      )
      ..delete(_db.doc(FirestorePaths.location(tourId, me.uid)))
      ..update(_member(tourId, me.uid), {
        'status': 'left',
        'removedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      })
      ..delete(_index(me.uid, tourId));
    await batch.commit().timeout(_timeout);
  }

  Future<void> changeRole({
    required Tour tour,
    required Member member,
    required MemberRole role,
    required String actorUid,
    required String actorName,
  }) async {
    assert(role != MemberRole.host, 'Use transferHost');
    final batch = _db.batch()
      ..update(_member(tour.id, member.uid), {
        'role': role.name,
        'updatedAt': FieldValue.serverTimestamp(),
      })
      ..set(
        _feed.newRef(tour.id),
        _feed.eventData(
          type: FeedEventType.roleChanged,
          actorUid: actorUid,
          subjectUid: member.uid,
          label: member.displayName,
        ),
      );
    await batch.commit().timeout(_timeout);
    await _inbox.notify(
      recipientUids: [member.uid],
      type: InboxType.roleChanged,
      tourId: tour.id,
      tourName: tour.name,
      senderUid: actorUid,
      senderName: actorName,
    );
  }

  /// Hands hosting to another active member; the old host becomes admin.
  Future<void> transferHost({
    required Tour tour,
    required Member newHost,
    required String currentHostUid,
  }) async {
    final batch = _db.batch()
      ..update(_db.doc(FirestorePaths.tour(tour.id)), {
        'hostUid': newHost.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      })
      ..update(_member(tour.id, newHost.uid), {
        'role': 'host',
        'updatedAt': FieldValue.serverTimestamp(),
      })
      ..update(_member(tour.id, currentHostUid), {
        'role': 'admin',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    await batch.commit().timeout(_timeout);
    await _feed.record(
      tour.id,
      type: FeedEventType.hostTransferred,
      actorUid: currentHostUid,
      subjectUid: newHost.uid,
      label: newHost.displayName,
    );
  }

  /// Refreshes the caller's name/photo snapshot in a tour.
  Future<void> updateOwnSnapshot(
    String tourId,
    String uid, {
    required String displayName,
    String? photoUrl,
  }) => _member(tourId, uid).update({
    'displayNameSnapshot': displayName,
    'photoUrlSnapshot': photoUrl,
    'updatedAt': FieldValue.serverTimestamp(),
  });
}

final membershipRepositoryProvider = Provider<MembershipRepository>(
  (ref) => MembershipRepository(
    ref.watch(firestoreProvider),
    ref.watch(feedRepositoryProvider),
    ref.watch(inboxRepositoryProvider),
  ),
);

final membersProvider = StreamProvider.autoDispose.family<List<Member>, String>(
  (ref, tourId) => ref.watch(membershipRepositoryProvider).watchMembers(tourId),
);

/// uid -> member, including former members (for historical names).
final memberMapProvider = Provider.autoDispose
    .family<Map<String, Member>, String>(
      (ref, tourId) => {
        for (final m
            in ref.watch(membersProvider(tourId)).value ?? const <Member>[])
          m.uid: m,
      },
    );

final activeMembersProvider = Provider.autoDispose.family<List<Member>, String>(
  (ref, tourId) {
    final list = (ref.watch(membersProvider(tourId)).value ?? const <Member>[])
        .where((m) => m.isActive)
        .toList();
    int rank(Member m) => switch (m.role) {
      MemberRole.host => 0,
      MemberRole.admin => 1,
      MemberRole.member => 2,
    };
    list.sort((a, b) {
      final r = rank(a).compareTo(rank(b));
      return r != 0
          ? r
          : a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    });
    return list;
  },
);

/// The signed-in user's own member record in [tourId].
final myMemberProvider = StreamProvider.autoDispose.family<Member?, String>((
  ref,
  tourId,
) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(membershipRepositoryProvider).watchOwnMember(tourId, uid);
});

/// Permission evaluation for the open tour; null until the tour loads.
final permissionsProvider = Provider.autoDispose
    .family<TourPermissions?, String>((ref, tourId) {
      final tour = ref.watch(tourProvider(tourId)).value;
      final me = ref.watch(myMemberProvider(tourId)).value;
      if (tour == null) return null;
      return TourPermissions(tour: tour, viewer: me);
    });

final pendingRequestsProvider = StreamProvider.autoDispose
    .family<List<JoinRequest>, String>((ref, tourId) {
      final permissions = ref.watch(permissionsProvider(tourId));
      if (permissions == null || !permissions.canReviewJoinRequests) {
        return Stream.value(const []);
      }
      return ref
          .watch(membershipRepositoryProvider)
          .watchPendingRequests(tourId);
    });
