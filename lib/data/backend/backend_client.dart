import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../app/providers.dart';

/// Error returned by the Tour Board backend (`{"error": "<code>"}`).
class BackendException implements Exception {
  const BackendException(this.status, this.code);

  final int status;
  final String code;

  bool get isRateLimited => status == 429;
  bool get isUnavailable => status == 503 || status >= 500 || status == 0;

  @override
  String toString() => 'BackendException($status, $code)';
}

/// Authenticated JSON client for https://tour-board-backend.onrender.com.
///
/// Every call carries the user's Firebase ID token; the server verifies it
/// and checks permissions against Firestore. The free Render instance may
/// take up to a minute to wake, so timeouts are generous and callers that
/// don't need a reply use [EventReporter] in the background.
class BackendClient {
  BackendClient(this._baseUrl, this._auth, {http.Client? client})
    : _http = client ?? http.Client();

  final String _baseUrl;
  final FirebaseAuth _auth;
  final http.Client _http;

  static const _timeout = Duration(seconds: 75);

  Future<Map<String, String>> _headers() async {
    final token = await _auth.currentUser?.getIdToken();
    if (token == null) throw const BackendException(401, 'unauthenticated');
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$_baseUrl$path').replace(queryParameters: query);

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
  }) async => _send(
    () async => _http.get(_uri(path, query), headers: await _headers()),
  );

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, Object?> body,
  ) async => _send(
    () async => _http.post(
      _uri(path),
      headers: await _headers(),
      body: jsonEncode(body),
    ),
  );

  Future<Map<String, dynamic>> delete(String path) async =>
      _send(() async => _http.delete(_uri(path), headers: await _headers()));

  Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() request,
  ) async {
    final http.Response res;
    try {
      res = await request().timeout(_timeout);
    } on TimeoutException {
      throw const BackendException(0, 'timeout');
    } on BackendException {
      rethrow;
    } catch (_) {
      throw const BackendException(0, 'network');
    }
    Map<String, dynamic> body;
    try {
      body = res.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      body = {};
    }
    if (res.statusCode >= 400) {
      throw BackendException(
        res.statusCode,
        body['error'] as String? ?? 'error',
      );
    }
    return body;
  }
}

final backendClientProvider = Provider<BackendClient>(
  (ref) => BackendClient(
    ref.watch(appConfigProvider).apiBaseUrl,
    ref.watch(firebaseAuthProvider),
  ),
);

/// Events the server turns into inbox items and push notifications.
/// Keep in sync with the backend's `eventTypes`.
enum ServerEvent {
  joinRequest,
  joinApproved,
  joinRejected,
  settlementSubmitted,
  settlementConfirmed,
  settlementDisputed,
  tourClosed,
  tourReopened,
  roleChanged,
  expenseAdded,
  expenseEdited,
  expenseDeleted,
  planAdded,
  planEdited,
}

/// Reports what the user just did so the server can notify others.
///
/// Fire-and-forget: it never blocks or fails the user's action. The server
/// verifies each event against Firestore and de-duplicates retries.
class EventReporter {
  EventReporter(this._client);

  final BackendClient _client;

  void report(
    ServerEvent type, {
    required String tourId,
    String? refId,
    String? subjectUid,
  }) {
    unawaited(_send(type, tourId, refId, subjectUid));
  }

  Future<void> _send(
    ServerEvent type,
    String tourId,
    String? refId,
    String? subjectUid,
  ) async {
    final body = {
      'tourId': tourId,
      'type': type.name,
      'refId': ?refId,
      'subjectUid': ?subjectUid,
    };
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        await _client.post('/v1/events', body);
        return;
      } on BackendException catch (e) {
        // Only retry transient failures (cold start, network).
        if (!e.isUnavailable) {
          debugPrint('Event ${type.name} not delivered: $e');
          return;
        }
      }
      await Future<void>.delayed(const Duration(seconds: 5));
    }
    debugPrint('Event ${type.name} not delivered after retries');
  }
}

final eventReporterProvider = Provider<EventReporter>(
  (ref) => EventReporter(ref.watch(backendClientProvider)),
);
