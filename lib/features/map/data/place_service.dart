import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/geo.dart';
import '../../../data/backend/backend_client.dart';

/// A search suggestion (Google Places autocomplete via the backend).
class PlaceSuggestion {
  const PlaceSuggestion({
    required this.placeId,
    required this.primary,
    required this.secondary,
  });

  factory PlaceSuggestion.fromJson(Map<String, dynamic> j) => PlaceSuggestion(
    placeId: j['placeId'] as String,
    primary: j['primary'] as String? ?? '',
    secondary: j['secondary'] as String? ?? '',
  );

  final String placeId;
  final String primary;
  final String secondary;
}

/// A chosen location for an itinerary item.
class PickedPlace {
  const PickedPlace({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address,
    this.placeId,
  });

  final String name;
  final String? address;
  final double latitude;
  final double longitude;
  final String? placeId;

  PickedPlace copyWith({String? name, String? address}) => PickedPlace(
    name: name ?? this.name,
    address: address ?? this.address,
    latitude: latitude,
    longitude: longitude,
    placeId: placeId,
  );
}

enum PlaceErrorKind { quota, unavailable, offline }

class PlaceException implements Exception {
  const PlaceException(this.kind);
  final PlaceErrorKind kind;
}

/// Place search through the Tour Board backend, which holds the Google key,
/// caches results and caps usage below the free tier.
///
/// One session token covers a run of autocomplete requests and the final
/// details lookup, which Google bills as a single (free-tier) session.
class PlaceService {
  PlaceService(this._client);

  final BackendClient _client;
  String _session = const Uuid().v4();

  /// Minimum characters before searching.
  static const minQueryLength = 3;

  void newSession() => _session = const Uuid().v4();

  Future<List<PlaceSuggestion>> autocomplete(
    String query, {
    String? language,
    double? nearLat,
    double? nearLng,
  }) async {
    final q = query.trim();
    if (q.length < minQueryLength) return const [];
    final json = await _guard(
      () => _client.get(
        '/v1/places/autocomplete',
        query: {
          'q': q,
          'session': _session,
          'lang': ?language,
          if (nearLat != null && nearLng != null) ...{
            'lat': nearLat.toStringAsFixed(4),
            'lng': nearLng.toStringAsFixed(4),
          },
        },
      ),
    );
    final list = (json['suggestions'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(PlaceSuggestion.fromJson)
        .toList();
    return list;
  }

  /// Resolves a suggestion to coordinates. Ends the billing session.
  Future<PickedPlace> details(
    PlaceSuggestion suggestion, {
    String? language,
  }) async {
    final json = await _guard(
      () => _client.get(
        '/v1/places/details/${Uri.encodeComponent(suggestion.placeId)}',
        query: {'session': _session, 'lang': ?language},
      ),
    );
    newSession();
    final p = json['place'] as Map<String, dynamic>;
    return PickedPlace(
      // The suggestion's main text is the best display name.
      name: suggestion.primary,
      address: p['address'] as String?,
      latitude: (p['lat'] as num).toDouble(),
      longitude: (p['lng'] as num).toDouble(),
      placeId: suggestion.placeId,
    );
  }

  /// Name/address for a dropped pin.
  Future<PickedPlace> reverse(
    double lat,
    double lng, {
    String? language,
  }) async {
    final json = await _guard(
      () => _client.get(
        '/v1/places/reverse',
        query: {
          'lat': lat.toStringAsFixed(6),
          'lng': lng.toStringAsFixed(6),
          'lang': ?language,
        },
      ),
    );
    final p = json['place'] as Map<String, dynamic>;
    return PickedPlace(
      name: p['name'] as String? ?? '',
      address: p['address'] as String?,
      latitude: lat,
      longitude: lng,
    );
  }

  Future<Map<String, dynamic>> _guard(
    Future<Map<String, dynamic>> Function() call,
  ) async {
    try {
      return await call();
    } on BackendException catch (e) {
      if (e.isRateLimited) throw const PlaceException(PlaceErrorKind.quota);
      if (e.status == 0) throw const PlaceException(PlaceErrorKind.offline);
      throw const PlaceException(PlaceErrorKind.unavailable);
    }
  }
}

final placeServiceProvider = Provider<PlaceService>(
  (ref) => PlaceService(ref.watch(backendClientProvider)),
);

/// Opens a place in Google Maps (or Apple Maps on iOS) via a URL — no SDK
/// navigation is involved.
Future<bool> openInMaps({
  double? latitude,
  double? longitude,
  String? name,
  String? placeId,
}) async {
  final label = name ?? '';
  final candidates = <Uri>[];
  if (isValidCoordinate(latitude, longitude)) {
    candidates.add(
      Uri.https('www.google.com', '/maps/search/', {
        'api': '1',
        'query': '$latitude,$longitude',
        'query_place_id': ?placeId,
      }),
    );
    if (Platform.isIOS) {
      candidates.add(
        Uri.https('maps.apple.com', '/', {
          'll': '$latitude,$longitude',
          'q': label.isEmpty ? '$latitude,$longitude' : label,
        }),
      );
    }
  } else if (label.isNotEmpty) {
    candidates.add(
      Uri.https('www.google.com', '/maps/search/', {
        'api': '1',
        'query': label,
      }),
    );
  }
  for (final uri in candidates) {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        return true;
      }
    } catch (_) {
      // Try the next candidate.
    }
  }
  return false;
}
