enum Role { user, admin }

class UserModel { 
  final String userId;
  final String displayName;
  final String email;
  final Role role;
  final int totalReviews;
  final int totalAdded;
  final int totalHelpful;
  final List<String> reviewIds;
  final String? photoUrl; // ✅ NEW: profile photo URL

  UserModel({
    required this.userId,
    required this.displayName,
    required this.email,
    this.role = Role.user, 
    this.totalReviews = 0,
    this.totalAdded = 0,
    this.totalHelpful = 0,
    this.reviewIds = const [],
    this.photoUrl,
  });

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
      reviewIds: List<String>.from(map['reviewIds'] ?? []),
      photoUrl: map['photoUrl'] as String?,
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
      'reviewIds': reviewIds,
      if (photoUrl != null) 'photoUrl': photoUrl,
    };
  }
}
