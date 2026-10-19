import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../app/providers.dart';
import '../../../data/firebase/firestore_streams.dart';
import '../domain/location_share.dart';
import 'location_repository.dart';

enum SharingProblem {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  writeFailed,
}

class SharingState {
  const SharingState({
    this.active = false,
    this.starting = false,
    this.paused = false,
    this.until,
    this.lastWriteAt,
    this.lastPosition,
    this.problem,
  });

  final bool active;
  final bool starting;

  /// App is in the background; GPS is stopped and others see "paused".
  final bool paused;
  final DateTime? until;
  final DateTime? lastWriteAt;
  final Position? lastPosition;
  final SharingProblem? problem;

  SharingState copyWith({
    bool? active,
    bool? starting,
    bool? paused,
    DateTime? until,
    DateTime? lastWriteAt,
    Position? lastPosition,
    SharingProblem? Function()? problem,
  }) => SharingState(
    active: active ?? this.active,
    starting: starting ?? this.starting,
    paused: paused ?? this.paused,
    until: until ?? this.until,
    lastWriteAt: lastWriteAt ?? this.lastWriteAt,
    lastPosition: lastPosition ?? this.lastPosition,
    problem: problem != null ? problem() : this.problem,
  );
}

/// Opt-in, foreground-only live location for one tour.
///
/// Lifecycle (brief §11):
/// * Off by default; permission is requested only when the user starts.
/// * Uses balanced accuracy and a distance filter, and writes through
///   [LocationWritePolicy] — never once per GPS callback.
/// * Overwrites a single latest-location document; no history.
/// * Stops when the window expires, the user stops, the tour closes, or the
///   user signs out (this provider rebuilds on auth change). When the app is
///   backgrounded GPS stops and the record is marked "paused"; Android/iOS
///   may suspend the app at any time, so this is not background tracking.
/// * Skips writes while Firestore appears offline, so stale coordinates are
///   not queued and delivered later with a fresh timestamp.
class LocationSharingController extends Notifier<SharingState> {
  LocationSharingController(this.tourId);

  final String tourId;

  StreamSubscription<Position>? _positions;
  Timer? _expiryTimer;
  AppLifecycleListener? _lifecycle;
  bool _tourOpen = true;

  static const _policy = LocationWritePolicy();
  static const _settings = LocationSettings(
    accuracy: LocationAccuracy.medium,
    distanceFilter: 50,
  );

  @override
  SharingState build() {
    ref.watch(currentUidProvider); // Rebuild (and stop) on sign-out.
    ref.onDispose(_teardown);
    return const SharingState();
  }

  String? get _uid => ref.read(currentUidProvider);
  DateTime _now() => ref.read(clockProvider)().toUtc();

  /// Called by the Map screen with the latest tour status.
  void updateTourOpen(bool open) {
    _tourOpen = open;
    if (!open && state.active) unawaited(stop());
  }

  Future<void> start({
    required SharingDuration duration,
    required DateTime tripEndUtc,
  }) async {
    if (state.starting || _uid == null || !_tourOpen) return;
    state = state.copyWith(starting: true, problem: () => null);
    final problem = await _ensurePermission();
    if (problem != null) {
      state = state.copyWith(starting: false, problem: () => problem);
      return;
    }
    final until = sharingUntilFor(duration, _now(), tripEndUtc);
    state = SharingState(active: true, until: until);
    _lifecycle ??= AppLifecycleListener(
      onHide: _onBackground,
      onShow: _onForeground,
    );
    _expiryTimer?.cancel();
    _expiryTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (state.active && !_now().isBefore(state.until!)) unawaited(stop());
    });
    try {
      final first = await Geolocator.getCurrentPosition(
        locationSettings: _settings,
      ).timeout(const Duration(seconds: 20));
      await _write(first, force: true);
    } catch (_) {
      // The stream below will deliver a fix when one is available.
    }
    _listen();
  }

  Future<SharingProblem?> _ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return SharingProblem.serviceDisabled;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Foreground ("while in use") permission only.
      permission = await Geolocator.requestPermission();
    }
    return switch (permission) {
      LocationPermission.denied => SharingProblem.permissionDenied,
      LocationPermission.deniedForever =>
        SharingProblem.permissionDeniedForever,
      _ => null,
    };
  }

  void _listen() {
    _positions?.cancel();
    _positions = Geolocator.getPositionStream(locationSettings: _settings)
        .listen(
          (p) => unawaited(_write(p)),
          onError: (Object e) {
            // Permission revoked or service turned off while sharing.
            unawaited(stop(problem: SharingProblem.permissionDenied));
          },
        );
  }

  Future<void> _write(Position p, {bool force = false}) async {
    final uid = _uid;
    final until = state.until;
    if (uid == null || until == null || !state.active || state.paused) return;
    final now = _now();
    if (!now.isBefore(until) || !_tourOpen) {
      await stop();
      return;
    }
    final last = state.lastPosition;
    final moved = last == null
        ? null
        : Geolocator.distanceBetween(
            last.latitude,
            last.longitude,
            p.latitude,
            p.longitude,
          );
    if (!force &&
        !_policy.shouldWrite(
          now: now,
          lastWriteAt: state.lastWriteAt,
          metersSinceLastWrite: moved,
        )) {
      return;
    }
    if (lastSnapshotFromCache.value) return; // Offline: drop, don't queue.
    try {
      await ref
          .read(locationRepositoryProvider)
          .write(
            tourId: tourId,
            uid: uid,
            latitude: p.latitude,
            longitude: p.longitude,
            accuracyMeters: p.accuracy.isFinite ? p.accuracy : null,
            sharingUntil: until,
          );
      state = state.copyWith(
        lastWriteAt: now,
        lastPosition: p,
        problem: () => null,
      );
    } catch (_) {
      state = state.copyWith(problem: () => SharingProblem.writeFailed);
    }
  }

  void _onBackground() {
    if (!state.active || state.paused) return;
    _positions?.cancel();
    _positions = null;
    state = state.copyWith(paused: true);
    final uid = _uid;
    if (uid != null) {
      unawaited(
        ref
            .read(locationRepositoryProvider)
            .setPaused(tourId, uid, true)
            .catchError((Object _) {}),
      );
    }
  }

  void _onForeground() {
    if (!state.active || !state.paused) return;
    if (!_now().isBefore(state.until!)) {
      unawaited(stop());
      return;
    }
    state = state.copyWith(paused: false);
    final uid = _uid;
    if (uid != null) {
      unawaited(
        ref
            .read(locationRepositoryProvider)
            .setPaused(tourId, uid, false)
            .catchError((Object _) {}),
      );
    }
    _listen();
  }

  /// Stops immediately and removes the location record.
  Future<void> stop({SharingProblem? problem}) async {
    _teardown();
    final uid = _uid;
    state = SharingState(problem: problem);
    if (uid == null) return;
    try {
      await ref.read(locationRepositoryProvider).stop(tourId, uid);
    } catch (_) {
      // Expired records are hidden by timestamp regardless.
    }
  }

  void _teardown() {
    _positions?.cancel();
    _positions = null;
    _expiryTimer?.cancel();
    _expiryTimer = null;
    _lifecycle?.dispose();
    _lifecycle = null;
  }
}

final locationSharingProvider =
    NotifierProvider.family<LocationSharingController, SharingState, String>(
      LocationSharingController.new,
    );
