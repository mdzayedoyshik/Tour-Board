import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/common.dart';
import '../data/place_service.dart';
import 'map_style.dart';

/// Opens the picker and returns the chosen place (or null if dismissed).
Future<PickedPlace?> pickPlace(
  BuildContext context, {
  PickedPlace? initial,
  LatLng? near,
}) => Navigator.of(context).push<PickedPlace>(
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => PlacePickerScreen(initial: initial, near: near),
  ),
);

/// Full-screen map to choose a place: search with suggestions, or tap /
/// long-press anywhere to drop a pin. No coordinates are ever typed.
class PlacePickerScreen extends ConsumerStatefulWidget {
  const PlacePickerScreen({this.initial, this.near, super.key});

  final PickedPlace? initial;

  /// Where to centre the map when nothing is chosen yet (e.g. other stops).
  final LatLng? near;

  @override
  ConsumerState<PlacePickerScreen> createState() => _PlacePickerScreenState();
}

class _PlacePickerScreenState extends ConsumerState<PlacePickerScreen> {
  final _search = TextEditingController();
  final _focus = FocusNode();
  GoogleMapController? _map;
  Timer? _debounce;
  List<PlaceSuggestion> _suggestions = const [];
  bool _searching = false;
  bool _resolving = false;
  String? _searchError;
  PickedPlace? _place;
  MapType _mapType = MapType.normal;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _place = widget.initial;
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _focus.dispose();
    super.dispose();
  }

  String get _language => Localizations.localeOf(context).languageCode;

  LatLng get _initialTarget {
    final p = widget.initial;
    if (p != null) return LatLng(p.latitude, p.longitude);
    return widget.near ?? const LatLng(23.8103, 90.4125);
  }

  void _onQueryChanged(String text) {
    _debounce?.cancel();
    setState(() => _searchError = null);
    if (text.trim().length < PlaceService.minQueryLength) {
      setState(() => _suggestions = const []);
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 450),
      () => _runSearch(text),
    );
  }

  Future<void> _runSearch(String text) async {
    final id = ++_requestId;
    setState(() => _searching = true);
    final center = _place != null
        ? LatLng(_place!.latitude, _place!.longitude)
        : widget.near;
    try {
      final results = await ref
          .read(placeServiceProvider)
          .autocomplete(
            text,
            language: _language,
            nearLat: center?.latitude,
            nearLng: center?.longitude,
          );
      if (!mounted || id != _requestId) return;
      setState(() {
        _suggestions = results;
        _searchError = results.isEmpty ? context.l10n.placeNoResults : null;
      });
    } on PlaceException catch (e) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _suggestions = const [];
        _searchError = _errorText(e.kind);
      });
    } finally {
      if (mounted && id == _requestId) setState(() => _searching = false);
    }
  }

  String _errorText(PlaceErrorKind kind) {
    final l10n = context.l10n;
    return switch (kind) {
      PlaceErrorKind.quota => l10n.placeQuota,
      PlaceErrorKind.offline => l10n.placeOffline,
      PlaceErrorKind.unavailable => l10n.placeUnavailable,
    };
  }

  Future<void> _choose(PlaceSuggestion s) async {
    _focus.unfocus();
    setState(() {
      _suggestions = const [];
      _resolving = true;
      _search.text = s.primary;
    });
    try {
      final place = await ref
          .read(placeServiceProvider)
          .details(s, language: _language);
      if (!mounted) return;
      setState(() => _place = place);
      await _map?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(place.latitude, place.longitude), 16),
      );
    } on PlaceException catch (e) {
      if (mounted) showAppSnack(context, _errorText(e.kind), error: true);
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  Future<void> _dropPin(LatLng point) async {
    _focus.unfocus();
    unawaited(HapticFeedback.selectionClick());
    final l10n = context.l10n;
    final id = ++_requestId;
    setState(() {
      _suggestions = const [];
      _place = PickedPlace(
        name: l10n.placeDroppedPin,
        latitude: point.latitude,
        longitude: point.longitude,
      );
      _resolving = true;
    });
    unawaited(_map?.animateCamera(CameraUpdate.newLatLng(point)));
    try {
      final named = await ref
          .read(placeServiceProvider)
          .reverse(point.latitude, point.longitude, language: _language);
      if (!mounted || id != _requestId) return;
      if (named.name.isNotEmpty) setState(() => _place = named);
    } on PlaceException {
      // Keep "Dropped pin"; the user can rename it.
    } finally {
      if (mounted && id == _requestId) setState(() => _resolving = false);
    }
  }

  Future<void> _rename() async {
    final place = _place;
    if (place == null) return;
    final l10n = context.l10n;
    final name = await promptText(
      context,
      title: l10n.placeRename,
      label: l10n.planPlaceName,
      confirmLabel: l10n.commonSave,
      maxLength: 120,
      initial: place.name == l10n.placeDroppedPin ? '' : place.name,
    );
    if (name != null && name.trim().isNotEmpty) {
      setState(() => _place = place.copyWith(name: name.trim()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final shadows = Elevations.of(context).floating;
    final place = _place;
    final topInset = MediaQuery.paddingOf(context).top;
    final showSuggestions =
        _focus.hasFocus && (_suggestions.isNotEmpty || _searchError != null);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialTarget,
              zoom: widget.initial != null || widget.near != null ? 14 : 11,
            ),
            style: MapStyles.forBrightness(theme.brightness),
            mapType: _mapType,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            padding: EdgeInsets.only(
              top: topInset + 72,
              bottom: place == null ? 24 : 190,
            ),
            onMapCreated: (c) => _map = c,
            onTap: _dropPin,
            onLongPress: _dropPin,
            markers: {
              if (place != null)
                Marker(
                  markerId: const MarkerId('picked'),
                  position: LatLng(place.latitude, place.longitude),
                  draggable: true,
                  onDragEnd: _dropPin,
                ),
            },
          ),
          // Floating search bar.
          Positioned(
            top: topInset + AppSpacing.sm,
            left: AppSpacing.md,
            right: AppSpacing.md,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark
                        ? scheme.surfaceContainerHigh
                        : Colors.white,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    boxShadow: shadows,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: l10n.commonBack,
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _search,
                          focusNode: _focus,
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: l10n.placeSearchHint,
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                          ),
                          onChanged: _onQueryChanged,
                          onSubmitted: (t) {
                            if (_suggestions.isNotEmpty) {
                              _choose(_suggestions.first);
                            } else {
                              _runSearch(t);
                            }
                          },
                        ),
                      ),
                      if (_searching)
                        const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else if (_search.text.isNotEmpty)
                        IconButton(
                          tooltip: l10n.commonClear,
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() {
                            _search.clear();
                            _suggestions = const [];
                            _searchError = null;
                          }),
                        ),
                    ],
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  child: showSuggestions
                      ? Container(
                          margin: const EdgeInsets.only(top: AppSpacing.sm),
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.sizeOf(context).height * 0.45,
                          ),
                          decoration: BoxDecoration(
                            color: theme.brightness == Brightness.dark
                                ? scheme.surfaceContainerHigh
                                : Colors.white,
                            borderRadius: BorderRadius.circular(AppRadii.lg),
                            boxShadow: shadows,
                          ),
                          child: _searchError != null
                              ? Padding(
                                  padding: const EdgeInsets.all(AppSpacing.lg),
                                  child: Text(
                                    _searchError!,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.xs,
                                  ),
                                  itemCount: _suggestions.length,
                                  separatorBuilder: (_, _) =>
                                      const Divider(indent: 64),
                                  itemBuilder: (context, i) {
                                    final s = _suggestions[i];
                                    return ListTile(
                                      leading: CircleAvatar(
                                        radius: 18,
                                        backgroundColor:
                                            scheme.surfaceContainerHigh,
                                        child: Icon(
                                          Icons.place_outlined,
                                          size: 20,
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                      title: Text(
                                        s.primary,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: s.secondary.isEmpty
                                          ? null
                                          : Text(
                                              s.secondary,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                      onTap: () => _choose(s),
                                    );
                                  },
                                ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ],
            ),
          ),
          // Map type toggle.
          Positioned(
            right: AppSpacing.md,
            bottom: (place == null ? 96 : 206),
            child: FloatingActionButton.small(
              heroTag: 'mapType',
              tooltip: l10n.mapLayers,
              backgroundColor: theme.brightness == Brightness.dark
                  ? scheme.surfaceContainerHigh
                  : Colors.white,
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
          ),
          // Hint or selected-place card.
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.md,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, a) => SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(a),
                child: FadeTransition(opacity: a, child: child),
              ),
              child: place == null
                  ? _HintChip(
                      key: const ValueKey('hint'),
                      text: l10n.placeTapHint,
                    )
                  : _PlaceCard(
                      key: const ValueKey('card'),
                      place: place,
                      loading: _resolving,
                      onRename: _rename,
                      onConfirm: () => Navigator.pop(context, place),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HintChip extends StatelessWidget {
  const _HintChip({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? theme.colorScheme.surfaceContainerHigh
              : Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          boxShadow: Elevations.of(context).floating,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.touch_app_outlined,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(text, style: theme.textTheme.labelLarge),
          ],
        ),
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({
    required this.place,
    required this.loading,
    required this.onRename,
    required this.onConfirm,
    super.key,
  });

  final PickedPlace place;
  final bool loading;
  final VoidCallback onRename;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? scheme.surfaceContainerHigh
            : Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        boxShadow: Elevations.of(context).floating,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(Icons.place, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (loading)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: const LinearProgressIndicator(minHeight: 3),
                        ),
                      )
                    else if ((place.address ?? '').isNotEmpty)
                      Text(
                        place.address!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: l10n.placeRename,
                icon: const Icon(Icons.edit_outlined),
                onPressed: onRename,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: l10n.placeUseThis,
            icon: Icons.check,
            onPressed: loading ? null : onConfirm,
          ),
        ],
      ),
    );
  }
}
