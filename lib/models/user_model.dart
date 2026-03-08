enum Role { user, admin }

class UserModel { 
  final String userId;
  final String displayName;
  final String email;
  final Role role;
  final int totalReviews;
  final int totalAdded;
  final int totalHelpful;
  final int points; // Added for Level system
  final List<String> reviewIds;
  final String? photoUrl;
  final List<String> favoriteRestrooms;

  UserModel({
    required this.userId,
    required this.displayName,
    required this.email,
    this.role = Role.user, 
    this.totalReviews = 0,
    this.totalAdded = 0,
    this.totalHelpful = 0,
    this.points = 0, // Default points
    this.reviewIds = const [],
    this.photoUrl,
    this.favoriteRestrooms = const []
  });

  // Calculate level based on points
  int get level {
    if (points < 100) return 1;
    if (points < 300) return 2;
    if (points < 600) return 3;
    if (points < 1000) return 4;
    return 5; // Elite
  }

  // Get Badge name based on level
  String get badgeName {
    switch (level) {
      case 1: return 'Newbie';
      case 2: return 'Explorer';
      case 3: return 'Reviewer';
      case 4: return 'Expert';
      case 5: return 'Restroom Legend';
      default: return 'Newbie';
    }
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['userId'] ?? '',
      displayName: map['displayName'] ?? '',
      email: map['email'] ?? '',
      role: Role.values.firstWhere(
        (e) => e.name == map['role'], 
        orElse: () => Role.user
      ),
      totalReviews: map['totalReviews']?.toInt() ?? 0,
      totalAdded: map['totalAdded']?.toInt() ?? 0,
      totalHelpful: map['totalHelpful']?.toInt() ?? 0,
      points: map['points']?.toInt() ?? 0,
      reviewIds: List<String>.from(map['reviewIds'] ?? []),
      photoUrl: map['photoUrl'] as String?,
      favoriteRestrooms: List<String>.from(map['favoriteRestrooms'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'email': email,
      'role': role.name,
      'totalReviews': totalReviews,
      'totalAdded': totalAdded,
      'totalHelpful': totalHelpful,
      'points': points,
      'reviewIds': reviewIds,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'favoriteRestrooms': favoriteRestrooms
    };
  }

  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    int? points,
    int? totalReviews,
    int? totalAdded,
    int? totalHelpful,
  }) {
    return UserModel(
      userId: userId,
      displayName: displayName ?? this.displayName,
      email: email,
      role: role,
      totalReviews: totalReviews ?? this.totalReviews,
      totalAdded: totalAdded ?? this.totalAdded,
      totalHelpful: totalHelpful ?? this.totalHelpful,
      points: points ?? this.points,
      reviewIds: reviewIds,
      photoUrl: photoUrl ?? this.photoUrl,
      favoriteRestrooms: favoriteRestrooms,
    );
  }
}
