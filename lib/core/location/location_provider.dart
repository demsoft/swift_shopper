import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/shared/data/swift_shopper_repository.dart';
import 'location_service.dart';

class LocationState {
  const LocationState({
    this.location,
    this.isLoading = false,
    this.promptSeen = false,
  });

  final SavedLocation? location;
  final bool isLoading;

  /// True once the user has either granted location or dismissed the prompt.
  final bool promptSeen;

  LocationState copyWith({
    SavedLocation? location,
    bool? isLoading,
    bool? promptSeen,
  }) {
    return LocationState(
      location: location ?? this.location,
      isLoading: isLoading ?? this.isLoading,
      promptSeen: promptSeen ?? this.promptSeen,
    );
  }
}

class LocationNotifier extends Notifier<LocationState> {
  final _service = LocationService();

  @override
  LocationState build() {
    _init();
    return const LocationState(isLoading: true);
  }

  Future<void> _init() async {
    final seen = await _service.hasLocationBeenSet();
    final saved = await _service.getSavedLocation();

    // Sync saved location to backend in case it wasn't sent before
    if (saved != null) {
      _syncToBackend(saved);
    }

    state = LocationState(
      location: saved,
      promptSeen: seen,
      isLoading: false,
    );
  }

  /// Called when user taps "Allow" on the location screen.
  Future<void> requestLocation() async {
    state = state.copyWith(isLoading: true);
    final location = await _service.requestAndFetchLocation();
    if (location != null) {
      await _service.saveLocation(location.latitude, location.longitude);
      _syncToBackend(location);
    } else {
      await _service.markLocationPromptSeen();
    }
    state = LocationState(
      location: location,
      promptSeen: true,
      isLoading: false,
    );
  }

  /// Called when user taps "Skip" on the location screen.
  Future<void> skipLocation() async {
    await _service.markLocationPromptSeen();
    state = state.copyWith(promptSeen: true, isLoading: false);
  }

  void _syncToBackend(SavedLocation location) {
    try {
      final repo = ref.read(swiftShopperRepositoryProvider);
      repo.updateUserLocation(
        latitude: location.latitude,
        longitude: location.longitude,
      );
    } catch (_) {
      // Best-effort — don't block the UI if backend is unreachable
    }
  }
}

final locationProvider =
    NotifierProvider<LocationNotifier, LocationState>(LocationNotifier.new);
