/// Single source of truth for Firestore paths. Keep in sync with
/// firestore.rules and docs/FIRESTORE_SCHEMA.md.
abstract final class FirestorePaths {
  static const users = 'users';
  static const tours = 'tours';
  static const invites = 'invites';

  static String user(String uid) => '$users/$uid';
  static String membershipIndex(String uid) => '$users/$uid/tourMemberships';
  static String membershipIndexEntry(String uid, String tourId) =>
      '${membershipIndex(uid)}/$tourId';
  static String inbox(String uid) => '$users/$uid/inbox';

  static String tour(String tourId) => '$tours/$tourId';
  static String members(String tourId) => '${tour(tourId)}/members';
  static String member(String tourId, String uid) => '${members(tourId)}/$uid';
  static String joinRequests(String tourId) => '${tour(tourId)}/joinRequests';
  static String joinRequest(String tourId, String uid) =>
      '${joinRequests(tourId)}/$uid';
  static String expenses(String tourId) => '${tour(tourId)}/expenses';
  static String expense(String tourId, String id) => '${expenses(tourId)}/$id';
  static String expenseRevisions(String tourId, String id) =>
      '${expense(tourId, id)}/revisions';
  static String settlements(String tourId) => '${tour(tourId)}/settlements';
  static String activities(String tourId) => '${tour(tourId)}/activities';
  static String notes(String tourId) => '${tour(tourId)}/notes';
  static String noteRevisions(String tourId, String id) =>
      '${notes(tourId)}/$id/revisions';
  static String packingItems(String tourId) => '${tour(tourId)}/packingItems';
  static String activityFeed(String tourId) => '${tour(tourId)}/activityFeed';
}
