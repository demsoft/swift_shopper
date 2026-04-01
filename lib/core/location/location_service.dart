import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedLocation {
  const SavedLocation({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class LocationService {
  static const _keyLat = 'location_lat';
  static const _keyLng = 'location_lng';
  static const _keySet = 'location_set';

  /// Returns true if the user has previously gone through the location prompt.
  Future<bool> hasLocationBeenSet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySet) ?? false;
  }

  /// Returns the saved location, or null if not yet set.
  Future<SavedLocation?> getSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_keyLat);
    final lng = prefs.getDouble(_keyLng);
    if (lat == null || lng == null) return null;
    return SavedLocation(latitude: lat, longitude: lng);
  }

  /// Saves a location and marks it as set.
  Future<void> saveLocation(double lat, double lng) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyLat, lat);
    await prefs.setDouble(_keyLng, lng);
    await prefs.setBool(_keySet, true);
  }

  /// Marks that the user dismissed the prompt without granting permission.
  Future<void> markLocationPromptSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySet, true);
  }

  /// Requests permission and fetches the current device position.
  /// Returns null if permission denied or GPS unavailable.
  Future<SavedLocation?> requestAndFetchLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return SavedLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      return null;
    }
  }
}
