import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../app/providers.dart';
import '../../../app/routes.dart';
import '../../../data/firebase/firestore_paths.dart';
import '../../settings/data/preferences.dart';

/// Android channel used by the backend's pushes (see FcmMessenger).
const _channel = AndroidNotificationChannel(
  'tour_updates',
  'Tour updates',
  description: 'Join requests, payments, expenses and plan changes',
  importance: Importance.high,
);

/// Registers this device for push notifications and routes taps.
///
/// The FCM token is stored at users/{uid}/devices/{deviceId} (owner-only
/// in rules); the backend reads it to deliver pushes and prunes dead
/// tokens. Nothing is sent from the device itself.
class PushService {
  PushService(this._ref);

  final Ref _ref;
  final _local = FlutterLocalNotificationsPlugin();
  StreamSubscription<String>? _tokenSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedSub;
  String? _uid;
  bool _localReady = false;

  /// Called with a route when the user taps a notification. Static because
  /// the local-notifications plugin is a singleton shared with reminders.
  static void Function(String route)? onOpenRoute;

  /// Shared tap handler for every local notification (pushes shown in the
  /// foreground and itinerary reminders).
  static void handleLocalTap(NotificationResponse response) {
    final route = response.payload;
    if (route != null && route.startsWith('/')) onOpenRoute?.call(route);
  }

  static const _deviceIdKey = 'push.deviceId';

  String _deviceId(SharedPreferences prefs) {
    var id = prefs.getString(_deviceIdKey);
    if (id == null) {
      id = const Uuid().v4();
      unawaited(prefs.setString(_deviceIdKey, id));
    }
    return id;
  }

  DocumentReference<Map<String, dynamic>> _deviceRef(String uid) {
    final prefs = _ref.read(sharedPreferencesProvider);
    return _ref
        .read(firestoreProvider)
        .doc('${FirestorePaths.user(uid)}/devices/${_deviceId(prefs)}');
  }

  Future<void> _initLocal() async {
    if (_localReady) return;
    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: handleLocalTap,
    );
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
    _localReady = true;
  }

  /// Starts push for [uid]: asks permission (Android 13+/iOS), saves the
  /// token, and listens for refreshes, foreground messages and taps.
  Future<void> start(String uid) async {
    if (_uid == uid) return;
    await stop(deleteToken: false);
    _uid = uid;
    try {
      await _initLocal();
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      // The classic registration token is used deliberately: the backend
      // sends with firebase-admin multicast, which expects FCM tokens (the
      // newer register()/FID direct-send flow is not supported there yet).
      // ignore: deprecated_member_use
      final token = await messaging.getToken();
      if (token != null) await _saveToken(uid, token);
      // ignore: deprecated_member_use
      _tokenSub = messaging.onTokenRefresh.listen((t) => _saveToken(uid, t));
      _foregroundSub = FirebaseMessaging.onMessage.listen(_showForeground);
      _openedSub = FirebaseMessaging.onMessageOpenedApp.listen(_openFrom);
      final initial = await messaging.getInitialMessage();
      if (initial != null) _openFrom(initial);
      await syncPreferences(uid, _ref.read(preferencesProvider));
    } catch (e) {
      debugPrint('Push setup skipped: $e');
    }
  }

  Future<void> _saveToken(String uid, String token) => _deviceRef(uid).set({
    'token': token,
    'platform': defaultTargetPlatform.name,
    'updatedAt': FieldValue.serverTimestamp(),
  });

  /// Mirrors notification preferences to the profile so the server can
  /// respect them for push.
  Future<void> syncPreferences(String uid, AppPreferences prefs) async {
    try {
      await _ref.read(firestoreProvider).doc(FirestorePaths.user(uid)).update({
        'notificationPrefs': {
          'important': prefs.notifyImportant,
          'expenses': prefs.notifyExpenses,
          'plans': prefs.notifyPlans,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Notification preferences not synced: $e');
    }
  }

  /// Stops listening; on sign-out also unregisters this device so the
  /// previous account stops receiving pushes here.
  Future<void> stop({bool deleteToken = true}) async {
    final uid = _uid;
    _uid = null;
    await _tokenSub?.cancel();
    await _foregroundSub?.cancel();
    await _openedSub?.cancel();
    _tokenSub = _foregroundSub = _openedSub = null;
    if (deleteToken && uid != null) {
      try {
        await _deviceRef(uid).delete();
        // ignore: deprecated_member_use
        await FirebaseMessaging.instance.deleteToken();
      } catch (_) {
        // Best effort; the server prunes dead tokens anyway.
      }
    }
  }

  /// Android shows notification messages itself only in the background, so
  /// foreground ones are displayed through a local notification.
  Future<void> _showForeground(RemoteMessage message) async {
    final n = message.notification;
    if (n == null || defaultTargetPlatform != TargetPlatform.android) return;
    await _local.show(
      id: message.hashCode & 0x7fffffff,
      title: n.title,
      body: n.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_notification',
        ),
      ),
      payload: routeForMessage(message.data),
    );
  }

  void _openFrom(RemoteMessage message) {
    final route = routeForMessage(message.data);
    if (route != null) onOpenRoute?.call(route);
  }
}

/// Where a notification tap should land.
String? routeForMessage(Map<String, dynamic> data) {
  final tourId = data['tourId'] as String?;
  final refId = data['refId'] as String?;
  if (tourId == null || tourId.isEmpty) return Routes.inbox;
  return switch (data['type'] as String?) {
    'joinRequest' => Routes.members(tourId),
    'joinRejected' => Routes.inbox,
    'settlementSubmitted' ||
    'settlementConfirmed' ||
    'settlementDisputed' => Routes.balances(tourId),
    'expenseAdded' ||
    'expenseEdited' ||
    'expenseDeleted' when refId != null => Routes.expense(tourId, refId),
    'planAdded' || 'planEdited' => Routes.tour(tourId, tab: 1),
    _ => Routes.tour(tourId),
  };
}

final pushServiceProvider = Provider<PushService>((ref) {
  final service = PushService(ref);
  ref.onDispose(() => unawaited(service.stop(deleteToken: false)));
  return service;
});
