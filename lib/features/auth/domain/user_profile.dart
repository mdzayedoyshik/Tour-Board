import '../../../data/firebase/firestore_helpers.dart';

/// users/{uid}. Private to its owner; other members see only the name/photo
/// snapshots stored on their member records.
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.locale,
    required this.createdAt,
    required this.updatedAt,
    this.photoUrl,
    this.phoneNumber,
  });

  factory UserProfile.fromDoc(String id, Map<String, dynamic> data) =>
      UserProfile(
        uid: id,
        displayName: readString(data['displayName']),
        email: readString(data['email']),
        photoUrl: readStringOrNull(data['photoUrl']),
        phoneNumber: readStringOrNull(data['phoneNumber']),
        locale: readString(data['locale'], fallback: 'en'),
        createdAt: readDate(data['createdAt']),
        updatedAt: readDate(data['updatedAt']),
      );

  static const maxNameLength = 60;

  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final String? phoneNumber;
  final String locale;
  final DateTime createdAt;
  final DateTime updatedAt;
}
