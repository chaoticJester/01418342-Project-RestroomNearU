import 'package:cloud_firestore/cloud_firestore.dart'; 

class ReviewModel {
  final String reviewId;
  final String restroomId;
  final String reviewerId;
  final String reviewerName;
  final String reviewerPhotoUrl;
  final double rating;
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

  // Helper method to create a copy with updated fields
  ReviewModel copyWith({
    double? rating,
    String? comment,
    List<String>? photos,
    int? totalLikes,
    int? helpfulCount,
    DateTime? updatedAt,
  }) {
    return ReviewModel(
      reviewId: this.reviewId,
      restroomId: this.restroomId,
      reviewerId: this.reviewerId,
      reviewerName: this.reviewerName,
      reviewerPhotoUrl: this.reviewerPhotoUrl,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      timestamp: this.timestamp, // Keep original post time
      createdAt: this.createdAt, // Never change
      updatedAt: updatedAt ?? DateTime.now(), // Auto-update to now
      totalLikes: totalLikes ?? this.totalLikes,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      photos: photos ?? this.photos,
    );
  }
}
