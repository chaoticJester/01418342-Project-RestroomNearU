import 'dart:math';

/// Helper functions for the app
class AppHelpers {
  
  /// Calculate distance between two coordinates (Haversine formula)
  static double calculateDistance(
    double lat1, 
    double lon1, 
    double lat2, 
    double lon2
  ) {
    const double earthRadius = 6371; // Radius of earth in kilometers
    
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = earthRadius * c;
    
    return distance; // Returns distance in kilometers
  }
  
  /// Format distance to readable string
  static String formatDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      return '${(distanceInKm * 1000).toStringAsFixed(0)}m from you';
    } else {
      return '${distanceInKm.toStringAsFixed(1)}km from you';
    }
  }
  
  /// Convert degrees to radians
  static double _toRadians(double degree) {
    return degree * pi / 180;
  }
  
  /// Format time from DateTime — 24-hour HH:mm
  static String formatTime(DateTime dateTime) {
    final hour   = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Format full date + time — dd-MM-yyyy HH:mm (24-hour)
  static String formatDateTime(DateTime dateTime) {
    final day    = dateTime.day.toString().padLeft(2, '0');
    final month  = dateTime.month.toString().padLeft(2, '0');
    final year   = dateTime.year.toString();
    final hour   = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day-$month-$year  $hour:$minute';
  }

  /// Format date only — dd-MM-yyyy
  static String formatDateOnly(DateTime dateTime) {
    final day   = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year  = dateTime.year.toString();
    return '$day-$month-$year';
  }
  
  /// Format date from DateTime
  static String formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else {
      return '${(difference.inDays / 365).floor()} years ago';
    }
  }
  
  /// Format amenity name from camelCase to Title Case
  static String formatAmenityName(String key) {
    return key.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(0)}',
    ).trim();
  }
  
  /// Validate email format
  static bool isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    ).hasMatch(email);
  }
  
  /// Validate phone number format
  static bool isValidPhoneNumber(String phone) {
    // Thai phone number format: 02-xxx-xxxx or 0x-xxxx-xxxx
    return RegExp(r'^0[0-9]{1}-[0-9]{3,4}-[0-9]{4}$').hasMatch(phone);
  }
}
