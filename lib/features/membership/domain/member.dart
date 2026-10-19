import '../../../data/firebase/firestore_helpers.dart';

enum MemberRole { host, admin, member }

enum MemberStatus { active, removed, left }

MemberRole memberRoleFromName(String? name) => MemberRole.values.firstWhere(
  (r) => r.name == name,
  orElse: () => MemberRole.member,
);

MemberStatus memberStatusFromName(String? name) => MemberStatus.values
    .firstWhere((s) => s.name == name, orElse: () => MemberStatus.removed);

class Member {
  const Member({
    required this.uid,
    required this.displayName,
    required this.role,
    required this.status,
    required this.joinedAt,
    this.photoUrl,
    this.removedAt,
  });

  factory Member.fromDoc(String id, Map<String, dynamic> data) => Member(
    uid: id,
    displayName: readString(data['displayNameSnapshot'], fallback: '—'),
    photoUrl: readStringOrNull(data['photoUrlSnapshot']),
    role: memberRoleFromName(data['role'] as String?),
    status: memberStatusFromName(data['status'] as String?),
    joinedAt: readDate(data['joinedAt']),
    removedAt: readDateOrNull(data['removedAt']),
  );

  final String uid;

  /// Snapshot of the profile name at join time; kept for historical records
  /// even after the member leaves.
  final String displayName;
  final String? photoUrl;
  final MemberRole role;
  final MemberStatus status;
  final DateTime joinedAt;
  final DateTime? removedAt;

  bool get isActive => status == MemberStatus.active;
  bool get isHost => role == MemberRole.host;
  bool get isAdminOrHost => role == MemberRole.host || role == MemberRole.admin;
}

enum JoinRequestStatus { pending, approved, rejected, cancelled }

JoinRequestStatus joinRequestStatusFromName(String? name) => JoinRequestStatus
    .values
    .firstWhere((s) => s.name == name, orElse: () => JoinRequestStatus.pending);

class JoinRequest {
  const JoinRequest({
    required this.uid,
    required this.displayName,
    required this.status,
    required this.attemptCount,
    required this.inviteCode,
    required this.createdAt,
    required this.updatedAt,
    this.photoUrl,
    this.reviewedBy,
    this.reviewedAt,
  });

  factory JoinRequest.fromDoc(String id, Map<String, dynamic> data) =>
      JoinRequest(
        uid: id,
        displayName: readString(data['displayNameSnapshot'], fallback: '—'),
        photoUrl: readStringOrNull(data['photoUrlSnapshot']),
        status: joinRequestStatusFromName(data['status'] as String?),
        attemptCount: readInt(data['attemptCount'], fallback: 1),
        inviteCode: readString(data['inviteCode']),
        createdAt: readDate(data['createdAt']),
        updatedAt: readDate(data['updatedAt']),
        reviewedBy: readStringOrNull(data['reviewedBy']),
        reviewedAt: readDateOrNull(data['reviewedAt']),
      );

  /// Requests (including retries) allowed per user per tour. Mirrored in
  /// firestore.rules (`maxJoinAttempts()`).
  static const maxAttempts = 3;

  final String uid;
  final String displayName;
  final String? photoUrl;
  final JoinRequestStatus status;
  final int attemptCount;
  final String inviteCode;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;

  bool get canRetry => attemptCount < maxAttempts;
}
