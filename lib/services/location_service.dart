import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Centralises all location-permission and position-fetching logic.
/// Previously duplicated in user_homepage.dart and add_new_restroom_page.dart.
class LocationService {
  /// Returns the current [Position] if permission is granted and services
  /// are enabled, otherwise returns `null`.
  ///
  /// Handles the full permission-request flow internally.
  static Future<Position?> getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
    } catch (e) {
      debugPrint('LocationService.getCurrentPosition error: $e');
      return null;
    }
  }

  /// Returns `true` if location services are enabled and permission has been
  /// granted (does NOT prompt the user — use [getCurrentPosition] for that).
  static Future<bool> hasPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }
}
