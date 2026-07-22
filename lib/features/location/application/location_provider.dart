import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:geolocator/geolocator.dart';

class UserLocation {
  const UserLocation({
    this.latitude,
    this.longitude,
    required this.isPermissionGranted,
  });

  final double? latitude;
  final double? longitude;
  final bool isPermissionGranted;

  bool get hasCoordinates => latitude != null && longitude != null;
}

enum LocationRequestResult {
  granted,
  denied,
  settingsOpened,
}

class LocationNotifier extends StateNotifier<UserLocation> {
  LocationNotifier() : super(const UserLocation(isPermissionGranted: false)) {
    checkPermission();
  }

  /// Check current permission status. If already granted, fetch coordinates.
  Future<void> checkPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
        state = UserLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          isPermissionGranted: true,
        );
      } else {
        state = const UserLocation(isPermissionGranted: false);
      }
    } catch (_) {
      state = const UserLocation(isPermissionGranted: false);
    }
  }

  /// Request permissions and get current position.
  Future<LocationRequestResult> requestPermission() async {
    try {
      // Check service enablement
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        state = const UserLocation(isPermissionGranted: false);
        return LocationRequestResult.settingsOpened;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          state = const UserLocation(isPermissionGranted: false);
          return LocationRequestResult.denied;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        state = const UserLocation(isPermissionGranted: false);
        return LocationRequestResult.settingsOpened;
      }

      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      state = UserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        isPermissionGranted: true,
      );
      return LocationRequestResult.granted;
    } catch (_) {
      state = const UserLocation(isPermissionGranted: false);
      return LocationRequestResult.denied;
    }
  }

  /// Manually mock/set coordinates if user selects fallback
  void setMockLocation() {
    state = const UserLocation(
      latitude: 19.0760,
      longitude: 72.8777,
      isPermissionGranted: false,
    );
  }
}

final userLocationProvider = StateNotifierProvider<LocationNotifier, UserLocation>((ref) {
  return LocationNotifier();
});
