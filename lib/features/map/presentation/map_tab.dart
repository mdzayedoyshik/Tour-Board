import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/providers.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/states.dart';
import '../../itinerary/data/plan_repository.dart';
import '../../itinerary/domain/plan_item.dart';
import '../../location_sharing/data/location_repository.dart';
import '../../location_sharing/data/location_sharing_controller.dart';
import '../../location_sharing/domain/location_share.dart';
import '../../membership/data/membership_repository.dart';
import '../../membership/domain/member.dart';
import '../../tours/domain/tour.dart';
import '../data/map_provider.dart';

/// Map of saved places and opted-in members. The location listener lives
/// only while this tab is visible.
class MapTab extends ConsumerStatefulWidget {
  const MapTab({required this.tour, super.key});

  final Tour tour;

  @override
  ConsumerState<MapTab> createState() => _MapTabState();
}

class _MapTabState extends ConsumerState<MapTab> {
  bool _tilesFailing = false;
  bool _cleanedUp = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Re-evaluate live/stale labels once a minute without any reads.
    _ticker = Timer.periodic(
      const Duration(minutes: 1),
      (_) => mounted ? setState(() {}) : null,
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tour = widget.tour;
    final l10n = context.l10n;
    final now = ref.watch(clockProvider)().toUtc();
    final source = ref.watch(mapTileSourceProvider);
    final plans =
        ref.watch(planItemsProvider(tour.id)).value?.items ?? const [];
    final locationsAsync = ref.watch(locationsProvider(tour.id));
    final members = ref.watch(memberMapProvider(tour.id));
    final uid = ref.watch(currentUidProvider);
    final sharing = ref.watch(locationSharingProvider(tour.id));
    final permissions = ref.watch(permissionsProvider(tour.id));

    // Stop sharing if the tour closes (outside build: it changes state).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(locationSharingProvider(tour.id).notifier)
            .updateTourOpen(tour.isOpen);
      }
    });

    // Bounded, lazy cleanup of expired location docs the first time the
    // map loads. The UI hides expired data regardless.
    ref.listen(locationsProvider(tour.id), (_, next) {
      final snap = next.value;
      if (_cleanedUp || snap == null || snap.fromCache) return;
      _cleanedUp = true;
      unawaited(
        ref
            .read(locationRepositoryProvider)
            .cleanupExpired(tour.id, snap.items, now),
      );
    });

    // Only active members' unexpired, unpaused locations are drawn.
    final shares = (locationsAsync.value?.items ?? const <LocationShare>[])
        .where((s) => members[s.uid]?.isActive ?? false)
        .toList();
    final visible = shares.where((s) => s.isVisibleAt(now)).toList();
    final places = plans.where((p) => p.hasCoordinates).toList();

    final points = [
      for (final p in places) LatLng(p.latitude!, p.longitude!),
      for (final s in visible) LatLng(s.latitude, s.longitude),
    ];

    final myShare = shares.where((s) => s.uid == uid).firstOrNull;

    return Stack(
      children: [
        FlutterMap(
          key: ValueKey(points.isEmpty),
          options: MapOptions(
            initialCenter: points.isEmpty ? const LatLng(20, 0) : points.first,
            initialZoom: points.isEmpty ? 2 : 13,
            initialCameraFit: points.length > 1
                ? CameraFit.coordinates(
                    coordinates: points,
                    padding: const EdgeInsets.fromLTRB(48, 160, 48, 96),
                    maxZoom: 15,
                  )
                : null,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: source.urlTemplate,
              userAgentPackageName: source.userAgentPackageName,
              errorTileCallback: (_, _, _) {
                if (!_tilesFailing && mounted) {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) =>
                        mounted ? setState(() => _tilesFailing = true) : null,
                  );
                }
              },
            ),
            MarkerLayer(
              markers: [
                for (final p in places)
                  Marker(
                    point: LatLng(p.latitude!, p.longitude!),
                    width: 44,
                    height: 44,
                    alignment: Alignment.topCenter,
                    child: _PlaceMarker(
                      item: p,
                      onTap: () => _showPlace(context, p),
                    ),
                  ),
                for (final s in visible)
                  Marker(
                    point: LatLng(s.latitude, s.longitude),
                    width: 48,
                    height: 48,
                    child: _MemberMarker(
                      member: members[s.uid],
                      stale: s.statusAt(now) == LocationShareStatus.stale,
                      onTap: () => _showMember(
                        context,
                        members[s.uid],
                        s,
                        sharing.lastPosition,
                        now,
                      ),
                    ),
                  ),
              ],
            ),
            RichAttributionWidget(
              alignment: AttributionAlignment.bottomLeft,
              attributions: [
                TextSourceAttribution(
                  source.attribution,
                  onTap: () => launchUrl(
                    source.attributionUrl,
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ],
            ),
          ],
        ),
        Positioned(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.md,
          child: Column(
            children: [
              _SharingPanel(
                tour: tour,
                state: sharing,
                myShare: myShare,
                canShare: permissions?.canShareLocation ?? false,
                now: now,
              ),
              if (_tilesFailing) ...[
                const SizedBox(height: AppSpacing.sm),
                Material(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  clipBehavior: Clip.antiAlias,
                  child: InlineBanner(
                    icon: Icons.map_outlined,
                    message: l10n.mapTilesUnavailable,
                  ),
                ),
              ],
              if (locationsAsync.hasError) ...[
                const SizedBox(height: AppSpacing.sm),
                Material(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  clipBehavior: Clip.antiAlias,
                  child: InlineBanner(
                    icon: Icons.error_outline,
                    message: l10n.mapLocationsUnavailable,
                  ),
                ),
              ],
            ],
          ),
        ),
        Positioned(
          right: AppSpacing.md,
          bottom: AppSpacing.xl,
          child: FloatingActionButton.small(
            heroTag: 'people',
            tooltip: l10n.mapPeople,
            onPressed: () => _showPeople(context, shares, now),
            child: const Icon(Icons.people_outline),
          ),
        ),
        if (places.isEmpty && plans.isNotEmpty)
          Positioned(
            left: AppSpacing.md,
            right: 72,
            bottom: AppSpacing.xl,
            child: Material(
              borderRadius: BorderRadius.circular(AppRadii.md),
              clipBehavior: Clip.antiAlias,
              child: InlineBanner(
                icon: Icons.info_outline,
                message: l10n.mapNoPlaces,
              ),
            ),
          ),
      ],
    );
  }

  void _showPlace(BuildContext context, PlanItem item) {
    final l10n = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            0,
            AppSpacing.page,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                [
                  formatDayKey(context, item.dayKey),
                  if (item.startTime != null)
                    formatClock(context, item.startTime!),
                  ?item.placeName,
                ].join(' · '),
              ),
              if (item.estimatedCostMinor != null)
                Text(
                  l10n.planEstimated(
                    formatMoney(
                      item.estimatedCostMinor!,
                      item.currencyCode ?? widget.tour.currencyCode,
                      locale: context.localeTag,
                    ),
                  ),
                ),
              if (item.note != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(item.note!),
              ],
              const SizedBox(height: AppSpacing.lg),
              SecondaryButton(
                label: l10n.planOpenInMaps,
                icon: Icons.open_in_new,
                onPressed: () => openInMaps(
                  latitude: item.latitude,
                  longitude: item.longitude,
                  name: item.placeName ?? item.title,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMember(
    BuildContext context,
    Member? member,
    LocationShare share,
    Position? myPosition,
    DateTime now,
  ) {
    final l10n = context.l10n;
    final distance = myPosition == null
        ? null
        : Geolocator.distanceBetween(
            myPosition.latitude,
            myPosition.longitude,
            share.latitude,
            share.longitude,
          );
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            0,
            AppSpacing.page,
            AppSpacing.lg,
          ),
          child: Row(
            children: [
              MemberAvatar(
                name: member?.displayName ?? '?',
                photoUrl: member?.photoUrl,
                size: AppSizes.avatarLg,
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member?.displayName ?? l10n.commonUnknownMember,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      l10n.stateStale(
                        formatRelative(context, share.updatedAt, now),
                      ),
                    ),
                    _ShareStatusPill(status: share.statusAt(now)),
                    if (distance != null)
                      Text(
                        l10n.mapDistance(_formatDistance(context, distance)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPeople(
    BuildContext context,
    List<LocationShare> shares,
    DateTime now,
  ) {
    final active = ref.read(activeMembersProvider(widget.tour.id));
    final byUid = {for (final s in shares) s.uid: s};
    final l10n = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.7,
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.page,
                ),
                child: Text(
                  l10n.mapPeople,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              for (final m in active)
                ListTile(
                  leading: MemberAvatar(
                    name: m.displayName,
                    photoUrl: m.photoUrl,
                  ),
                  title: Text(m.displayName),
                  subtitle:
                      byUid[m.uid] == null ||
                          !byUid[m.uid]!.isVisibleAt(now) &&
                              byUid[m.uid]!.statusAt(now) !=
                                  LocationShareStatus.paused
                      ? null
                      : Text(
                          l10n.stateStale(
                            formatRelative(
                              context,
                              byUid[m.uid]!.updatedAt,
                              now,
                            ),
                          ),
                        ),
                  trailing: _ShareStatusPill(
                    status:
                        byUid[m.uid]?.statusAt(now) ??
                        LocationShareStatus.notSharing,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDistance(BuildContext context, double meters) {
    final l10n = context.l10n;
    if (meters < 1000) return l10n.distanceMeters(meters.round());
    return l10n.distanceKm((meters / 1000).toStringAsFixed(1));
  }
}

class _ShareStatusPill extends StatelessWidget {
  const _ShareStatusPill({required this.status});

  final LocationShareStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = StatusColors.of(context);
    final (label, color, icon) = switch (status) {
      LocationShareStatus.live => (l10n.shareLive, c.success, Icons.circle),
      LocationShareStatus.stale => (l10n.shareStale, c.warning, Icons.history),
      LocationShareStatus.paused => (
        l10n.sharePaused,
        c.muted,
        Icons.pause_circle_outline,
      ),
      LocationShareStatus.notSharing => (
        l10n.shareNotSharing,
        c.muted,
        Icons.location_off_outlined,
      ),
    };
    return StatusPill(label: label, color: color, icon: icon);
  }
}

class _PlaceMarker extends StatelessWidget {
  const _PlaceMarker({required this.item, required this.onTap});

  final PlanItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: item.title,
      child: GestureDetector(
        onTap: onTap,
        child: Icon(
          item.favorite ? Icons.stars : Icons.location_on,
          size: 40,
          color: scheme.secondary,
          shadows: const [Shadow(blurRadius: 4, color: Colors.black26)],
        ),
      ),
    );
  }
}

/// Members are round avatars (distinct from pin-shaped places); stale ones
/// are dimmed with a dashed-looking ring, never shown as live.
class _MemberMarker extends StatelessWidget {
  const _MemberMarker({
    required this.member,
    required this.stale,
    required this.onTap,
  });

  final Member? member;
  final bool stale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = StatusColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label:
          '${member?.displayName ?? ''}, '
          '${stale ? context.l10n.shareStale : context.l10n.shareLive}',
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: stale ? 0.55 : 1,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.surface,
              border: Border.all(
                color: stale ? colors.muted : colors.success,
                width: 3,
              ),
              boxShadow: const [
                BoxShadow(blurRadius: 4, color: Colors.black26),
              ],
            ),
            child: MemberAvatar(
              name: member?.displayName ?? '?',
              photoUrl: member?.photoUrl,
              size: 34,
            ),
          ),
        ),
      ),
    );
  }
}

class _SharingPanel extends ConsumerWidget {
  const _SharingPanel({
    required this.tour,
    required this.state,
    required this.myShare,
    required this.canShare,
    required this.now,
  });

  final Tour tour;
  final SharingState state;
  final LocationShare? myShare;
  final bool canShare;
  final DateTime now;

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final choice = await showModalBottomSheet<SharingDuration>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.shareStartTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(l10n.shareStartBody),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final d in SharingDuration.values)
              ListTile(
                leading: Icon(
                  d == SharingDuration.twoHours
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                title: Text(switch (d) {
                  SharingDuration.thirtyMinutes => l10n.share30Min,
                  SharingDuration.twoHours => l10n.share2Hours,
                  SharingDuration.untilTripEnds => l10n.shareUntilTripEnds,
                }),
                onTap: () => Navigator.pop(context, d),
              ),
          ],
        ),
      ),
    );
    if (choice == null) return;
    await ref
        .read(locationSharingProvider(tour.id).notifier)
        .start(duration: choice, tripEndUtc: tour.endAt);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final controller = ref.read(locationSharingProvider(tour.id).notifier);
    final colors = StatusColors.of(context);

    final problemText = switch (state.problem) {
      SharingProblem.serviceDisabled => l10n.shareServiceOff,
      SharingProblem.permissionDenied => l10n.sharePermissionDenied,
      SharingProblem.permissionDeniedForever => l10n.sharePermissionForever,
      SharingProblem.writeFailed => l10n.shareWriteFailed,
      null => null,
    };

    Widget content;
    if (state.active) {
      content = Row(
        children: [
          Icon(Icons.my_location, color: colors.success),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.paused ? l10n.shareActivePaused : l10n.shareActive,
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  l10n.shareUntil(formatDateTime(context, state.until!)),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          FilledButton.tonal(
            onPressed: controller.stop,
            child: Text(l10n.shareStop),
          ),
        ],
      );
    } else if (myShare != null && !myShare!.isExpired(now)) {
      // A record left from an earlier session (e.g. app was closed).
      content = Row(
        children: [
          Icon(Icons.location_on_outlined, color: colors.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              l10n.shareLeftover(
                formatRelative(context, myShare!.updatedAt, now),
              ),
              style: theme.textTheme.bodySmall,
            ),
          ),
          TextButton(
            onPressed: () => controller.stop(),
            child: Text(l10n.shareStop),
          ),
        ],
      );
    } else if (canShare) {
      content = Row(
        children: [
          Icon(Icons.location_off_outlined, color: colors.muted),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(l10n.shareOff, style: theme.textTheme.bodySmall),
          ),
          FilledButton.tonal(
            onPressed: state.starting ? null : () => _start(context, ref),
            child: state.starting
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.shareStart),
          ),
        ],
      );
    } else {
      content = Text(l10n.shareClosedTour, style: theme.textTheme.bodySmall);
    }

    return Semantics(
      liveRegion: true,
      child: Material(
        color: theme.colorScheme.surface,
        elevation: 2,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              content,
              if (problemText != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  problemText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                if (state.problem == SharingProblem.permissionDeniedForever ||
                    state.problem == SharingProblem.serviceDisabled)
                  TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: () =>
                        state.problem == SharingProblem.serviceDisabled
                        ? Geolocator.openLocationSettings()
                        : Geolocator.openAppSettings(),
                    child: Text(l10n.shareOpenSettings),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
