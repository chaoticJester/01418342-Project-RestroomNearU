import 'package:flutter/material.dart';

/// App-wide constants
class AppConstants {
  // Colors
  static const Color primaryColor = Color(0xFFBADFDB);
  static const Color backgroundColor = Color(0xFFFCF9EA);
  static const Color accentColor = Color(0xFFFFA4A4);
  static const Color darkColor = Color(0xFF2C2C2C);
  
  // Padding & Spacing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  
  // Border Radius
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusLarge = 12.0;
  static const double borderRadiusCircle = 100.0;
  
  // Text Sizes
  static const double textSizeSmall = 11.0;
  static const double textSizeNormal = 13.0;
  static const double textSizeMedium = 16.0;
  static const double textSizeLarge = 18.0;
  
  // Animation Duration
  static const Duration animationDuration = Duration(milliseconds: 200);
  
  // Validation
  static const int minCommentLength = 20;
  static const int maxCommentLength = 500;
  static const int maxPhotosPerReview = 10;
}

/// Route Names — ✅ FIX #13: kept in sync with the routes defined in main.dart.
/// Always update BOTH places if a route path changes.
class RouteNames {
  static const String login          = '/login_page';
  static const String userHome       = '/user_homepage';
  static const String addNewRestroom = '/add_new_restroom';
  static const String profile        = '/profile';
  static const String adminHome      = '/admin_homepage';
  static const String adminRequests  = '/admin_requests';
  static const String adminReports   = '/admin_reports';
  static const String adminToilets   = '/admin_toilets';
  static const String adminProfile   = '/admin_profile';
  static const String adminUsers     = '/admin_users';
}

/// Filter Options
class FilterOptions {
  static const List<String> reviewFilters = [
    'Recent',
    'Highest Rating',
    'Lowest Rating',
    'Most Helpful',
  ];
}

/// Rating Badges
class RatingBadges {
  static String getBadge(double rating) {
    if (rating >= 4.5) return 'Excellent';
    if (rating >= 3.5) return 'Good';
    if (rating >= 2.5) return 'Average';
    if (rating >= 1.5) return 'Poor';
    return 'Very Poor';
  }
  
  static Color getBadgeColor(double rating) {
    if (rating >= 4.5) return Colors.green;
    if (rating >= 3.5) return Colors.lightGreen;
    if (rating >= 2.5) return Colors.orange;
    if (rating >= 1.5) return Colors.deepOrange;
    return Colors.red;
  }
}
