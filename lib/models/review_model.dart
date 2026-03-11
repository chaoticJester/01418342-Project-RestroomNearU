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
  final DateTime createdAt;      // When created (Standardized naming)
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
    DateTime? createdAt,
    DateTime? updatedAt,
    this.totalLikes = 0,
    this.helpfulCount = 0,
    this.likedBy = const [],
    this.photos = const [],
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? createdAt ?? DateTime.now();

  // 1. Convert from Firestore (Map) -> Object
  factory ReviewModel.fromMap(Map<String, dynamic> map, String id) {
    // Check both for backward compatibility during migration
    final DateTime reviewTime = (map['createdAt'] ?? map['timestamp']) != null
        ? ((map['createdAt'] ?? map['timestamp']) as Timestamp).toDate()
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
      createdAt: reviewTime,
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
    List<String>? likedBy,
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
      createdAt: createdAt,       // Never change
      updatedAt: updatedAt ?? DateTime.now(),
      totalLikes: totalLikes ?? this.totalLikes,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      likedBy: likedBy ?? this.likedBy,
      photos: photos ?? this.photos,
    );
  }
}
