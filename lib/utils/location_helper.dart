import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// Shared location-permission + position helper.
/// Replaces the duplicated `_checkLocationPermission` /
/// `_getInitialLocation` / `_getCurrentLocation` blocks that appear
/// in both `user_homepage.dart` and `add_new_restroom_page.dart`.
class LocationHelper {
  LocationHelper._();

  // ── Permission ──────────────────────────────────────────────────────────

  /// Requests location permission if not yet granted.
  /// Returns `true` if permission is granted and location services are enabled.
  static Future<bool> requestPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  // ── Position ────────────────────────────────────────────────────────────

  /// Returns the current [Position], or `null` if unavailable.
  /// Handles permission check internally.
  static Future<Position?> getCurrentPosition() async {
    final granted = await requestPermission();
    if (!granted) return null;

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
    } catch (e) {
      debugPrint('[LocationHelper] Error getting position: $e');
      return null;
    }
  }
}
