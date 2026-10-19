import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/routes.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/states.dart';
import '../../itinerary/data/plan_repository.dart';
import '../../itinerary/domain/plan_item.dart';
import '../../membership/data/membership_repository.dart';
import '../../tours/domain/tour.dart';
import '../data/map_provider.dart';

/// Map of the itinerary's places. Shows only plan items that have
/// coordinates; nothing about members' locations.
class MapTab extends ConsumerStatefulWidget {
  const MapTab({required this.tour, super.key});

  final Tour tour;

  @override
  ConsumerState<MapTab> createState() => _MapTabState();
}

class _MapTabState extends ConsumerState<MapTab> {
  bool _tilesFailing = false;

  @override
  Widget build(BuildContext context) {
    final tour = widget.tour;
    final l10n = context.l10n;
    final source = ref.watch(mapTileSourceProvider);
    final plans =
        ref.watch(planItemsProvider(tour.id)).value?.items ?? const [];
    final canAdd =
        ref.watch(permissionsProvider(tour.id))?.canAddContent ?? false;
    final places = sortPlanItems(plans.where((p) => p.hasCoordinates)).toList()
      ..sort((a, b) => a.dayKey.compareTo(b.dayKey));
    final points = [for (final p in places) LatLng(p.latitude!, p.longitude!)];

    return Stack(
      children: [
        FlutterMap(
          key: ValueKey(points.length),
          options: MapOptions(
            initialCenter: points.isEmpty ? const LatLng(20, 0) : points.first,
            initialZoom: points.isEmpty ? 2 : 13,
            initialCameraFit: points.length > 1
                ? CameraFit.coordinates(
                    coordinates: points,
                    padding: const EdgeInsets.fromLTRB(48, 96, 48, 96),
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
        if (_tilesFailing || places.isEmpty)
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.md,
            child: Material(
              borderRadius: BorderRadius.circular(AppRadii.md),
              clipBehavior: Clip.antiAlias,
              elevation: 2,
              child: InlineBanner(
                icon: _tilesFailing ? Icons.map_outlined : Icons.info_outline,
                message: _tilesFailing
                    ? l10n.mapTilesUnavailable
                    : l10n.mapNoPlaces,
                action: places.isEmpty && canAdd
                    ? TextButton(
                        onPressed: () => context.push(Routes.newPlan(tour.id)),
                        child: Text(l10n.planAdd),
                      )
                    : null,
              ),
            ),
          ),
        if (places.isNotEmpty)
          Positioned(
            right: AppSpacing.md,
            bottom: AppSpacing.xl,
            child: FloatingActionButton.small(
              heroTag: 'places',
              tooltip: l10n.mapPlaces,
              onPressed: () => _showList(context, places),
              child: const Icon(Icons.list),
            ),
          ),
      ],
    );
  }

  void _showList(BuildContext context, List<PlanItem> places) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.7,
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.page,
                ),
                child: Text(
                  sheetContext.l10n.mapPlaces,
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
              ),
              for (final p in places)
                ListTile(
                  leading: Icon(p.favorite ? Icons.stars : Icons.location_on),
                  title: Text(p.title),
                  subtitle: Text(
                    [
                      formatDayKey(sheetContext, p.dayKey),
                      if (p.startTime != null)
                        formatClock(sheetContext, p.startTime!),
                      ?p.placeName,
                    ].join(' · '),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showPlace(context, p);
                  },
                ),
            ],
          ),
        ),
      ),
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
