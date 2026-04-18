import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../config/app_env.dart';
import '../network/network_providers.dart';
import 'place_result.dart';
import 'places_cache_service.dart';

class PlacesService {
  PlacesService({required http.Client client, required PlacesCacheService cache})
      : _client = client,
        _cache = cache;

  final http.Client _client;
  final PlacesCacheService _cache;
  final Set<String> _inFlightQueries = {};

  static const String _autocompleteBase =
      'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  static const String _detailsBase =
      'https://maps.googleapis.com/maps/api/place/details/json';

  /// Returns predictions for [query].
  /// - Returns `[]` on empty results or missing API key.
  /// - Returns `null` on network error or deduplicated in-flight request
  ///   (widget should show stale cache if available).
  Future<List<PlacePrediction>?> getAutocomplete(
    String query,
    String sessionToken,
  ) async {
    if (AppEnv.googlePlacesApiKey.isEmpty) {
      debugPrint('[Places] WARNING: GOOGLE_PLACES_API_KEY not configured');
      return [];
    }

    final normalized = query.toLowerCase().trim();
    if (normalized.length < 3) return [];

    if (_inFlightQueries.contains(normalized)) return null;

    final cached = await _cache.getPredictions(normalized);
    if (cached != null) return cached;

    _inFlightQueries.add(normalized);
    try {
      final uri = Uri.parse(_autocompleteBase).replace(queryParameters: {
        'input': query,
        'key': AppEnv.googlePlacesApiKey,
        'sessiontoken': sessionToken,
        'components': 'country:ng',
        'language': 'en',
        'location': '6.5244,3.3792',
        'radius': '50000',
      });

      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        debugPrint('[Places] HTTP ${response.statusCode}');
        return null;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final status = json['status'] as String? ?? '';

      if (status == 'OVER_QUERY_LIMIT' || status == 'REQUEST_DENIED') {
        debugPrint('[Places] API status: $status');
        return null;
      }

      if (status == 'ZERO_RESULTS') return [];

      final raw = json['predictions'] as List<dynamic>? ?? [];
      final predictions = raw
          .map((e) => PlacePrediction.fromJson(e as Map<String, dynamic>))
          .where((p) => p.placeId.isNotEmpty && p.description.isNotEmpty)
          .toList();

      await _cache.setPredictions(normalized, predictions);
      return predictions;
    } catch (e) {
      debugPrint('[Places] autocomplete error: $e');
      return null;
    } finally {
      _inFlightQueries.remove(normalized);
    }
  }

  /// Fetches lat/lng for [prediction] and closes the billing session.
  /// Returns `null` on failure — caller should fire callback with 0.0,0.0.
  Future<PlaceResult?> getPlaceDetails(
    PlacePrediction prediction,
    String sessionToken,
  ) async {
    if (AppEnv.googlePlacesApiKey.isEmpty) return null;

    try {
      final uri = Uri.parse(_detailsBase).replace(queryParameters: {
        'place_id': prediction.placeId,
        'key': AppEnv.googlePlacesApiKey,
        'sessiontoken': sessionToken,
        'fields': 'geometry,formatted_address',
      });

      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final status = json['status'] as String? ?? '';
      if (status != 'OK') {
        debugPrint('[Places] details status: $status');
        return null;
      }

      final result = json['result'] as Map<String, dynamic>?;
      if (result == null) return null;

      final location = (result['geometry'] as Map<String, dynamic>?)?['location']
          as Map<String, dynamic>?;
      if (location == null) return null;

      final lat = (location['lat'] as num?)?.toDouble();
      final lng = (location['lng'] as num?)?.toDouble();
      final address =
          result['formatted_address'] as String? ?? prediction.description;

      if (lat == null || lng == null) return null;

      return PlaceResult(
        placeId: prediction.placeId,
        description: address,
        lat: lat,
        lng: lng,
      );
    } catch (e) {
      debugPrint('[Places] details error: $e');
      return null;
    }
  }
}

final placesCacheServiceProvider = Provider<PlacesCacheService>(
  (_) => PlacesCacheService(),
);

final placesServiceProvider = Provider<PlacesService>((ref) {
  return PlacesService(
    client: ref.watch(httpClientProvider),
    cache: ref.watch(placesCacheServiceProvider),
  );
});
