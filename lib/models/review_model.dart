import 'package:cloud_firestore/cloud_firestore.dart'; 

class ReviewModel {
  final String reviewId;
  final String restroomId;
  final String reviewerId;
  final String reviewerName;
  final String reviewerPhotoUrl;
  final double rating;
  final double cleanlinessRating;
  final double availabilityRating;
  final double amenitiesRating;
  final double smellRating;
  final Map<String, bool> amenitiesFound;
  final String comment;
  final DateTime timestamp;      // When the review was posted (same as createdAt)
  final DateTime createdAt;      // When created
  final DateTime updatedAt;      // When last edited
  final int totalLikes;
  final int helpfulCount;
  final List<String> likedBy;
  final List<String> photos;

  ReviewModel({
    required this.reviewId,
    required this.restroomId,
    required this.reviewerId,
    required this.reviewerName,
    this.reviewerPhotoUrl = '',
    required this.rating,
    this.cleanlinessRating = 0.0,
    this.availabilityRating = 0.0,
    this.amenitiesRating = 0.0,
    this.smellRating = 0.0,
    this.amenitiesFound = const {},
    required this.comment,
    DateTime? timestamp,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.totalLikes = 0,
    this.helpfulCount = 0,
    this.likedBy = const [],
    this.photos = const [],
  }) : 
    timestamp = timestamp ?? DateTime.now(),
    createdAt = createdAt ?? timestamp ?? DateTime.now(),
    updatedAt = updatedAt ?? timestamp ?? DateTime.now();

  // 1. Convert from Firestore (Map) -> Object
  factory ReviewModel.fromMap(Map<String, dynamic> map, String id) {
    final DateTime reviewTime = map['timestamp'] != null
        ? (map['timestamp'] as Timestamp).toDate()
        : DateTime.now();
    
    return ReviewModel(
      reviewId: id,
      restroomId: map['restroomId'] ?? '',
      reviewerId: map['reviewerId'] ?? '',
      reviewerName: map['reviewerName'] ?? 'Anonymous',
      reviewerPhotoUrl: map['reviewerPhotoUrl'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      cleanlinessRating: (map['cleanlinessRating'] ?? 0.0).toDouble(),
      availabilityRating: (map['availabilityRating'] ?? 0.0).toDouble(),
      amenitiesRating: (map['amenitiesRating'] ?? 0.0).toDouble(),
      smellRating: (map['smellRating'] ?? 0.0).toDouble(),
      amenitiesFound: Map<String, bool>.from(map['amenitiesFound'] ?? {}),
      comment: map['comment'] ?? '',
      timestamp: reviewTime,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : reviewTime,
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : reviewTime,
      totalLikes: (map['totalLikes'] ?? 0).toInt(),
      helpfulCount: (map['helpfulCount'] ?? 0).toInt(),
      likedBy: List<String>.from(map['likedBy'] ?? []),
      photos: List<String>.from(map['photos'] ?? []),
    );
  }

  // 2. Convert from Object -> Map for saving
  Map<String, dynamic> toMap() {
    return {
      'restroomId': restroomId,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'reviewerPhotoUrl': reviewerPhotoUrl,
      'rating': rating,
      'cleanlinessRating': cleanlinessRating,
      'availabilityRating': availabilityRating,
      'amenitiesRating': amenitiesRating,
      'smellRating': smellRating,
      'amenitiesFound': amenitiesFound,
      'comment': comment,
      'timestamp': Timestamp.fromDate(timestamp),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'totalLikes': totalLikes,
      'helpfulCount': helpfulCount,
      'likedBy': likedBy,
      'photos': photos,
    };
  }

  // Helper to check if review was edited
  bool get isEdited => updatedAt.isAfter(createdAt.add(const Duration(seconds: 5)));

  // Helper method to create a copy with updated fields.
  // Use the sentinel [_clearSuspension] pattern isn't needed here, but for
  // nullable list fields we always pass through to avoid accidental resets.
  ReviewModel copyWith({
    double? rating,
    double? cleanlinessRating,
    double? availabilityRating,
    double? amenitiesRating,
    double? smellRating,
    Map<String, bool>? amenitiesFound,
    String? comment,
    List<String>? photos,
    int? totalLikes,
    int? helpfulCount,
    List<String>? likedBy,   // ✅ FIX #1: was missing — omitting it silently wiped likes
    DateTime? updatedAt,
  }) {
    return ReviewModel(
      reviewId: reviewId,
      restroomId: restroomId,
      reviewerId: reviewerId,
      reviewerName: reviewerName,
      reviewerPhotoUrl: reviewerPhotoUrl,
      rating: rating ?? this.rating,
      cleanlinessRating: cleanlinessRating ?? this.cleanlinessRating,
      availabilityRating: availabilityRating ?? this.availabilityRating,
      amenitiesRating: amenitiesRating ?? this.amenitiesRating,
      smellRating: smellRating ?? this.smellRating,
      amenitiesFound: amenitiesFound ?? this.amenitiesFound,
      comment: comment ?? this.comment,
      timestamp: timestamp,       // Keep original post time
      createdAt: createdAt,       // Never change
      updatedAt: updatedAt ?? DateTime.now(),
      totalLikes: totalLikes ?? this.totalLikes,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      likedBy: likedBy ?? this.likedBy,   // ✅ preserve existing list
      photos: photos ?? this.photos,
    );
  }
}
