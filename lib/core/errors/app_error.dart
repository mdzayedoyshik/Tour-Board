import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

import '../../data/backend/backend_client.dart';
import '../localization/l10n.dart';

/// Broad error categories used to pick a calm, actionable message.
enum AppErrorKind {
  network,
  permissionDenied,
  notFound,
  conflict,
  cancelled,
  quota,
  invalid,
  unknown,
}

/// Domain-level failure with a category; raised by repositories for
/// expected situations (e.g. an edit conflict) so the UI can react.
class AppException implements Exception {
  const AppException(this.kind, [this.detail]);
  final AppErrorKind kind;
  final String? detail;

  @override
  String toString() =>
      'AppException($kind${detail == null ? '' : ': $detail'})';
}

AppErrorKind classifyError(Object error) {
  if (error is AppException) return error.kind;
  if (error is TimeoutException) return AppErrorKind.network;
  if (error is BackendException) {
    return switch (error.status) {
      0 => AppErrorKind.network,
      401 || 403 => AppErrorKind.permissionDenied,
      404 => AppErrorKind.notFound,
      409 => AppErrorKind.conflict,
      429 => AppErrorKind.quota,
      400 => AppErrorKind.invalid,
      _ => AppErrorKind.unknown,
    };
  }
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
      case 'unauthenticated':
        return AppErrorKind.permissionDenied;
      case 'not-found':
        return AppErrorKind.notFound;
      case 'unavailable':
      case 'deadline-exceeded':
      case 'network-request-failed':
        return AppErrorKind.network;
      case 'aborted':
      case 'failed-precondition':
        return AppErrorKind.conflict;
      case 'resource-exhausted':
      case 'too-many-requests':
        return AppErrorKind.quota;
      case 'cancelled':
        return AppErrorKind.cancelled;
      case 'invalid-argument':
        return AppErrorKind.invalid;
    }
  }
  if (error is FirebaseAuthException &&
      error.code == 'network-request-failed') {
    return AppErrorKind.network;
  }
  return AppErrorKind.unknown;
}

String errorMessage(BuildContext context, Object error) {
  final l10n = context.l10n;
  return switch (classifyError(error)) {
    AppErrorKind.network => l10n.errorNetwork,
    AppErrorKind.permissionDenied => l10n.errorPermission,
    AppErrorKind.notFound => l10n.errorNotFound,
    AppErrorKind.conflict => l10n.errorConflict,
    AppErrorKind.cancelled => l10n.errorCancelled,
    AppErrorKind.quota => l10n.errorQuota,
    AppErrorKind.invalid => l10n.errorInvalid,
    AppErrorKind.unknown => l10n.errorGeneric,
  };
}
