import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'place_result.dart';

class PlacesCacheService {
  static const int _ttlSeconds = 86400; // 24 hours

  String _cacheKey(String query) =>
      'places_cache_${query.toLowerCase().trim()}';

  String _tsKey(String query) =>
      'places_cache_ts_${query.toLowerCase().trim()}';

  Future<List<PlacePrediction>?> getPredictions(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ts = prefs.getInt(_tsKey(query));
      if (ts == null) return null;

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (now - ts > _ttlSeconds) {
        await prefs.remove(_cacheKey(query));
        await prefs.remove(_tsKey(query));
        return null;
      }

      final raw = prefs.getString(_cacheKey(query));
      if (raw == null) return null;

      return PlacePrediction.listFromJsonString(raw);
    } catch (e) {
      debugPrint('[PlacesCache] read error: $e');
      return null;
    }
  }

  Future<void> setPredictions(
    String query,
    List<PlacePrediction> predictions,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = PlacePrediction.listToJsonString(predictions);
      await prefs.setString(_cacheKey(query), encoded);
      await prefs.setInt(
        _tsKey(query),
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
    } catch (e) {
      debugPrint('[PlacesCache] write error: $e');
    }
  }
}
