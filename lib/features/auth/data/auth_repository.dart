import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../app/providers.dart';
import '../../../core/errors/app_error.dart';
import '../../../data/firebase/firestore_helpers.dart';
import '../../../data/firebase/firestore_paths.dart';
import '../../../data/firebase/firestore_streams.dart';
import '../domain/user_profile.dart';

enum SignInFailure { cancelled, network, notConfigured, unknown }

class SignInException implements Exception {
  const SignInException(this.reason, [this.detail]);
  final SignInFailure reason;
  final String? detail;

  @override
  String toString() => 'SignInException($reason, $detail)';
}

/// Google sign-in through Firebase Authentication. No passwords are
/// collected and only name, email and photo URL are copied to the profile.
class AuthRepository {
  AuthRepository(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  Future<void>? _googleInit;

  /// Client IDs come from google-services.json (Android `default_web_client_id`)
  /// and GoogleService-Info.plist (iOS `CLIENT_ID`), both written by
  /// `flutterfire configure` once Google sign-in is enabled in Firebase.
  Future<void> _ensureGoogleInitialised() {
    return _googleInit ??= GoogleSignIn.instance.initialize();
  }

  User? get currentUser => _auth.currentUser;

  Future<User> signInWithGoogle() async {
    try {
      await _ensureGoogleInitialised();
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const SignInException(SignInFailure.notConfigured, 'no idToken');
      }
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final result = await _auth.signInWithCredential(credential);
      final user = result.user!;
      await ensureProfile(user);
      return user;
    } on GoogleSignInException catch (e) {
      // Allow a later retry to re-run initialisation if it failed.
      if (e.code == GoogleSignInExceptionCode.clientConfigurationError) {
        _googleInit = null;
        throw SignInException(SignInFailure.notConfigured, e.description);
      }
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        throw const SignInException(SignInFailure.cancelled);
      }
      throw SignInException(SignInFailure.unknown, e.description);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed') {
        throw const SignInException(SignInFailure.network);
      }
      throw SignInException(SignInFailure.unknown, e.code);
    } on FirebaseException catch (e) {
      if (classifyError(e) == AppErrorKind.network) {
        throw const SignInException(SignInFailure.network);
      }
      rethrow;
    }
  }

  /// Creates users/{uid} on first sign-in. Later sign-ins leave a
  /// user-edited name alone and only refresh provider-owned fields.
  Future<void> ensureProfile(User user, {String locale = 'en'}) async {
    final ref = _firestore.doc(FirestorePaths.user(user.uid));
    final snap = await ref.get();
    final email = user.email ?? '';
    final name = _boundedName(user.displayName, email);
    if (!snap.exists) {
      await ref.set({
        'uid': user.uid,
        'displayName': name,
        'email': email,
        'photoUrl': ?blankToNull(user.photoURL),
        'locale': locale,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }
    final data = snap.data()!;
    final photo = blankToNull(user.photoURL);
    if (data['email'] != email || data['photoUrl'] != photo) {
      await ref.update({
        'email': email,
        'photoUrl': photo,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<UserProfile?> watchProfile(String uid) => watchDoc(
    _firestore.doc(FirestorePaths.user(uid)),
    (doc) => UserProfile.fromDoc(doc.id, doc.data()!),
  );

  Future<void> updateProfile(
    String uid, {
    required String displayName,
    required String locale,
  }) => _firestore.doc(FirestorePaths.user(uid)).update({
    'displayName': displayName.trim(),
    'locale': locale,
    'updatedAt': FieldValue.serverTimestamp(),
  });

  Future<void> signOut() async {
    try {
      await _ensureGoogleInitialised();
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Signing out of Firebase is what matters; ignore Google SDK errors.
    }
    await _auth.signOut();
  }

  /// Re-authenticates with Google (required by Firebase before deleting an
  /// account), then deletes the auth user. Data cleanup happens before this
  /// in AccountDeletionService.
  Future<void> reauthenticateAndDelete() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _ensureGoogleInitialised();
    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const SignInException(SignInFailure.notConfigured);
    }
    await user.reauthenticateWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
    await user.delete();
    try {
      await GoogleSignIn.instance.disconnect();
    } catch (_) {}
  }

  static String _boundedName(String? displayName, String email) {
    var name = displayName?.trim() ?? '';
    if (name.isEmpty) name = email.split('@').first;
    if (name.isEmpty) name = 'Traveller';
    return name.length > UserProfile.maxNameLength
        ? name.substring(0, UserProfile.maxNameLength)
        : name;
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
  ),
);

/// The signed-in user's private profile.
final profileProvider = StreamProvider.autoDispose<UserProfile?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(authRepositoryProvider).watchProfile(uid);
});
