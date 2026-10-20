import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../app/routes.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../itinerary/data/plan_repository.dart';
import '../../itinerary/domain/plan_item.dart';
import '../../itinerary/presentation/plan_item_actions.dart';
import '../../itinerary/presentation/plan_tab.dart';
import '../../membership/data/membership_repository.dart';
import '../../tours/domain/tour.dart';
import 'map_style.dart';

/// Colours for day pins (cycled). Bright enough on light and dark maps.
const _dayColors = [
  Color(0xFF1F6FEB),
  Color(0xFFF59E0B),
  Color(0xFF10B981),
  Color(0xFFEC4899),
  Color(0xFF8B5CF6),
  Color(0xFFEF4444),
  Color(0xFF0EA5E9),
];

/// The itinerary on a Google Map: numbered pins per day, a day filter and
/// a swipeable card carousel synced with the map.
class MapTab extends ConsumerStatefulWidget {
  const MapTab({required this.tour, super.key});

  final Tour tour;

  @override
  ConsumerState<MapTab> createState() => _MapTabState();
}

class _MapTabState extends ConsumerState<MapTab> {
  GoogleMapController? _map;
  final _pages = PageController(viewportFraction: 0.86);
  String? _day; // null = all days
  int _selected = 0;
  Set<Marker> _markers = {};
  String _markerSignature = '';
  MapType _mapType = MapType.normal;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  List<PlanItem> _stops(List<PlanItem> all) {
    final grouped = groupByDay(widget.tour, all);
    return [
      for (final e in grouped.entries)
        if (_day == null || e.key == _day)
          ...e.value.where((i) => i.hasCoordinates),
    ];
  }

  Color _colorFor(String dayKey, List<String> dayKeys) =>
      _dayColors[math.max(0, dayKeys.indexOf(dayKey)) % _dayColors.length];

  Future<void> _rebuildMarkers(
    List<PlanItem> stops,
    List<String> dayKeys,
    double dpr,
  ) async {
    final signature = [
      _selected,
      for (final s in stops) '${s.id}:${s.latitude}:${s.longitude}:${s.dayKey}',
    ].join('|');
    if (signature == _markerSignature) return;
    _markerSignature = signature;
    final markers = <Marker>{};
    for (var i = 0; i < stops.length; i++) {
      final s = stops[i];
      final icon = await MarkerPainter.pin(
        color: _colorFor(s.dayKey, dayKeys),
        label: '${i + 1}',
        devicePixelRatio: dpr,
        selected: i == _selected,
      );
      markers.add(
        Marker(
          markerId: MarkerId(s.id),
          position: LatLng(s.latitude!, s.longitude!),
          icon: icon,
          anchor: const Offset(0.5, 1),
          zIndexInt: i == _selected ? 10 : 1,
          onTap: () => _select(i, stops, animatePage: true),
        ),
      );
    }
    if (mounted) setState(() => _markers = markers);
  }

  void _select(int index, List<PlanItem> stops, {bool animatePage = false}) {
    if (index < 0 || index >= stops.length) return;
    setState(() => _selected = index);
    final s = stops[index];
    unawaited(
      _map?.animateCamera(
        CameraUpdate.newLatLng(LatLng(s.latitude!, s.longitude!)),
      ),
    );
    if (animatePage && _pages.hasClients) {
      unawaited(
        _pages.animateToPage(
          index,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        ),
      );
    }
  }

  Future<void> _fit(List<PlanItem> stops) async {
    final map = _map;
    if (map == null || stops.isEmpty) return;
    if (stops.length == 1) {
      await map.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(stops.first.latitude!, stops.first.longitude!),
          14,
        ),
      );
      return;
    }
    var minLat = 90.0, maxLat = -90.0, minLng = 180.0, maxLng = -180.0;
    for (final s in stops) {
      minLat = math.min(minLat, s.latitude!);
      maxLat = math.max(maxLat, s.latitude!);
      minLng = math.min(minLng, s.longitude!);
      maxLng = math.max(maxLng, s.longitude!);
    }
    await map.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        64,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tour = widget.tour;
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final all = ref.watch(planItemsProvider(tour.id)).value?.items ?? const [];
    final permissions = ref.watch(permissionsProvider(tour.id));
    final canAdd = permissions?.canAddContent ?? false;
    final dayKeys = groupByDay(tour, all).keys.toList();
    final stops = _stops(all);
    if (_selected >= stops.length) _selected = 0;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    unawaited(_rebuildMarkers(stops, dayKeys, dpr));
    final floatingColor = theme.brightness == Brightness.dark
        ? scheme.surfaceContainerHigh
        : Colors.white;
    final initial = stops.isEmpty
        ? const LatLng(23.8103, 90.4125)
        : LatLng(stops.first.latitude!, stops.first.longitude!);

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: initial,
            zoom: stops.isEmpty ? 5 : 12,
          ),
          style: MapStyles.forBrightness(theme.brightness),
          mapType: _mapType,
          markers: _markers,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false,
          padding: EdgeInsets.only(top: 64, bottom: stops.isEmpty ? 0 : 170),
          onMapCreated: (c) {
            _map = c;
            Future<void>.delayed(
              const Duration(milliseconds: 300),
              () => _fit(stops),
            );
          },
        ),
        // Day filter.
        Positioned(
          top: AppSpacing.md,
          left: 0,
          right: 0,
          child: SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              children: [
                _FilterChip(
                  label: l10n.mapAllDays,
                  selected: _day == null,
                  color: scheme.primary,
                  background: floatingColor,
                  onTap: () {
                    setState(() {
                      _day = null;
                      _selected = 0;
                    });
                    unawaited(_fit(_stops(all)));
                  },
                ),
                for (final key in dayKeys)
                  if (all.any((i) => i.dayKey == key && i.hasCoordinates))
                    _FilterChip(
                      label: () {
                        final n = tripDayNumber(tour, key);
                        return n == null
                            ? formatDayKey(context, key)
                            : l10n.planDayShort(n);
                      }(),
                      selected: _day == key,
                      color: _colorFor(key, dayKeys),
                      background: floatingColor,
                      onTap: () {
                        setState(() {
                          _day = key;
                          _selected = 0;
                        });
                        unawaited(_fit(_stops(all)));
                      },
                    ),
              ],
            ),
          ),
        ),
        // Map controls.
        Positioned(
          right: AppSpacing.md,
          bottom: stops.isEmpty ? AppSpacing.xl : 186,
          child: Column(
            children: [
              FloatingActionButton.small(
                heroTag: 'mapType',
                tooltip: l10n.mapLayers,
                backgroundColor: floatingColor,
                foregroundColor: scheme.onSurface,
                onPressed: () => setState(
                  () => _mapType = _mapType == MapType.normal
                      ? MapType.hybrid
                      : MapType.normal,
                ),
                child: Icon(
                  _mapType == MapType.normal
                      ? Icons.satellite_alt_outlined
                      : Icons.map_outlined,
                ),
              ),
              if (stops.length > 1) ...[
                const SizedBox(height: AppSpacing.sm),
                FloatingActionButton.small(
                  heroTag: 'fit',
                  tooltip: l10n.mapShowAll,
                  backgroundColor: floatingColor,
                  foregroundColor: scheme.onSurface,
                  onPressed: () => _fit(stops),
                  child: const Icon(Icons.zoom_out_map),
                ),
              ],
            ],
          ),
        ),
        // Carousel or empty state.
        Positioned(
          left: 0,
          right: 0,
          bottom: AppSpacing.md,
          child: stops.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: floatingColor,
                      borderRadius: BorderRadius.circular(AppRadii.xl),
                      boxShadow: Elevations.of(context).floating,
                    ),
                    child: Row(
                      children: [
                        IconBadge(
                          icon: Icons.map_outlined,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            l10n.mapNoPlaces,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        if (canAdd)
                          TextButton(
                            onPressed: () =>
                                context.push(Routes.newPlan(tour.id)),
                            child: Text(l10n.planAdd),
                          ),
                      ],
                    ),
                  ),
                )
              : SizedBox(
                  height: 150,
                  child: PageView.builder(
                    controller: _pages,
                    itemCount: stops.length,
                    onPageChanged: (i) => _select(i, stops),
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      child: _StopCard(
                        item: stops[i],
                        number: i + 1,
                        color: _colorFor(stops[i].dayKey, dayKeys),
                        tour: tour,
                        background: floatingColor,
                        onTap: () => showPlanItemActions(
                          context,
                          ref,
                          tour: tour,
                          item: stops[i],
                          dayItems: sortPlanItems(
                            all.where((x) => x.dayKey == stops[i].dayKey),
                          ),
                          permissions: permissions,
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.background,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Material(
        color: selected ? color : background,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        elevation: 2,
        shadowColor: Colors.black26,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!selected) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: selected
                        ? Colors.white
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StopCard extends StatelessWidget {
  const _StopCard({
    required this.item,
    required this.number,
    required this.color,
    required this.tour,
    required this.background,
    required this.onTap,
  });

  final PlanItem item;
  final int number;
  final Color color;
  final Tour tour;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final n = tripDayNumber(tour, item.dayKey);
    final when = [
      n == null ? formatDayKey(context, item.dayKey) : l10n.planDayShort(n),
      if (item.startTime != null) formatClock(context, item.startTime!),
    ].join(' · ');
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(AppRadii.xl),
      elevation: 3,
      shadowColor: Colors.black26,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.xl),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color,
                child: Text(
                  '$number',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      when,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [?item.placeName, ?item.address]
                          .where((e) => e.isNotEmpty && e != item.title)
                          .join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        if (item.status != PlanStatus.planned)
                          StatusPill(label: planStatusLabel(l10n, item.status)),
                        const Spacer(),
                        Icon(Icons.directions, size: 18, color: scheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          l10n.planDirections,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.primary,
                          ),
                        ),
                      ],
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
}
