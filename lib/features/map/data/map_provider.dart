import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../app/providers.dart';

/// Tile source for the map. Configurable so the owner can switch to another
/// policy-compliant provider without code changes. The default public OSM
/// tile server is for light use only and requires attribution; it is not
/// an unlimited free service (see docs/FREE_TIER_LIMITS.md).
class MapTileSource {
  const MapTileSource({
    required this.urlTemplate,
    required this.attribution,
    required this.attributionUrl,
    required this.userAgentPackageName,
  });

  final String urlTemplate;
  final String attribution;
  final Uri attributionUrl;

  /// Identifies the app to the tile server, as the OSM policy requires.
  final String userAgentPackageName;
}

final mapTileSourceProvider = Provider<MapTileSource>((ref) {
  final config = ref.watch(appConfigProvider);
  return MapTileSource(
    urlTemplate: config.mapTileUrl,
    attribution: config.mapTileAttribution,
    attributionUrl: Uri.parse(config.mapAttributionUrl),
    userAgentPackageName: 'com.techorbit.tour_board',
  );
});

class PlaceResult {
  const PlaceResult({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.detail,
  });

  final String name;
  final String? detail;
  final double latitude;
  final double longitude;
}

enum PlaceSearchFailure { unavailable, rateLimited, network }

class PlaceSearchException implements Exception {
  const PlaceSearchException(this.reason);
  final PlaceSearchFailure reason;
}

/// Place search behind an interface so the provider can change later. The
/// app always also supports manual place entry, so search is optional.
abstract class PlaceSearchProvider {
  bool get isAvailable;

  /// Minimum query length before a request is made.
  int get minQueryLength => 3;

  Future<List<PlaceResult>> search(String query, {String? language});
}

/// Manual-entry-only mode (PLACE_SEARCH_PROVIDER=none).
class DisabledPlaceSearch extends PlaceSearchProvider {
  @override
  bool get isAvailable => false;

  @override
  Future<List<PlaceResult>> search(String query, {String? language}) async =>
      throw const PlaceSearchException(PlaceSearchFailure.unavailable);
}

/// Nominatim (OpenStreetMap) geocoding, following its usage policy
/// (https://operations.osmfoundation.org/policies/nominatim/): at most one
/// request per second, an identifying User-Agent, results cached in memory,
/// and no autocomplete — callers search only on an explicit submit.
class NominatimPlaceSearch extends PlaceSearchProvider {
  NominatimPlaceSearch({
    required this.baseUrl,
    required this.contactEmail,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final String contactEmail;
  final http.Client _client;
  final _cache = <String, List<PlaceResult>>{};
  DateTime? _lastRequest;

  static const _minInterval = Duration(milliseconds: 1100);
  static const _maxCache = 50;

  @override
  bool get isAvailable => true;

  @override
  Future<List<PlaceResult>> search(String query, {String? language}) async {
    final q = query.trim();
    if (q.length < minQueryLength) return const [];
    final key = '${language ?? ''}|${q.toLowerCase()}';
    final cached = _cache[key];
    if (cached != null) return cached;

    // Client-side throttle to respect the 1 request/second limit.
    final last = _lastRequest;
    if (last != null) {
      final wait = _minInterval - DateTime.now().difference(last);
      if (!wait.isNegative) await Future<void>.delayed(wait);
    }
    _lastRequest = DateTime.now();

    final uri = Uri.parse('$baseUrl/search').replace(
      queryParameters: {
        'q': q,
        'format': 'jsonv2',
        'limit': '8',
        'addressdetails': '0',
        if (contactEmail.isNotEmpty) 'email': contactEmail,
      },
    );
    final http.Response response;
    try {
      response = await _client
          .get(
            uri,
            headers: {
              'User-Agent':
                  'TourBoard/1.0 (com.techorbit.tour_board'
                  '${contactEmail.isEmpty ? '' : '; $contactEmail'})',
              'Accept-Language': ?language,
            },
          )
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw const PlaceSearchException(PlaceSearchFailure.network);
    } catch (_) {
      throw const PlaceSearchException(PlaceSearchFailure.network);
    }
    if (response.statusCode == 429 || response.statusCode == 403) {
      throw const PlaceSearchException(PlaceSearchFailure.rateLimited);
    }
    if (response.statusCode != 200) {
      throw const PlaceSearchException(PlaceSearchFailure.unavailable);
    }
    final results = parseNominatim(response.body);
    if (_cache.length >= _maxCache) _cache.remove(_cache.keys.first);
    _cache[key] = results;
    return results;
  }

  /// Parses a jsonv2 response, skipping entries with invalid coordinates.
  static List<PlaceResult> parseNominatim(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! List) return const [];
    final results = <PlaceResult>[];
    for (final item in decoded.whereType<Map>()) {
      final lat = double.tryParse('${item['lat']}');
      final lon = double.tryParse('${item['lon']}');
      final display = '${item['display_name'] ?? ''}';
      if (lat == null || lon == null || display.isEmpty) continue;
      if (lat < -90 || lat > 90 || lon < -180 || lon > 180) continue;
      final name = '${item['name'] ?? ''}';
      results.add(
        PlaceResult(
          name: name.isNotEmpty ? name : display.split(',').first.trim(),
          detail: display,
          latitude: lat,
          longitude: lon,
        ),
      );
    }
    return results;
  }
}

final placeSearchProvider = Provider<PlaceSearchProvider>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.placeSearchProvider == 'nominatim') {
    return NominatimPlaceSearch(
      baseUrl: config.nominatimUrl,
      contactEmail: config.placeSearchContactEmail,
    );
  }
  return DisabledPlaceSearch();
});

/// Opens a place in the platform's map app (or the browser) using normal
/// URL schemes — no SDK or API key involved.
Future<bool> openInMaps({
  double? latitude,
  double? longitude,
  String? name,
}) async {
  final label = name ?? '';
  final candidates = <Uri>[];
  if (latitude != null && longitude != null) {
    if (Platform.isIOS) {
      candidates.add(
        Uri.parse(
          'https://maps.apple.com/?ll=$latitude,$longitude'
          '&q=${Uri.encodeComponent(label.isEmpty ? '$latitude,$longitude' : label)}',
        ),
      );
    } else {
      candidates.add(
        Uri.parse(
          'geo:$latitude,$longitude?q=$latitude,$longitude'
          '(${Uri.encodeComponent(label)})',
        ),
      );
    }
    candidates.add(
      Uri.parse(
        'https://www.openstreetmap.org/?mlat=$latitude&mlon=$longitude'
        '#map=16/$latitude/$longitude',
      ),
    );
  } else if (label.isNotEmpty) {
    candidates.add(
      Uri.parse(
        'https://www.openstreetmap.org/search?query=${Uri.encodeComponent(label)}',
      ),
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
