import 'package:cloud_firestore/cloud_firestore.dart'; // อย่าลืม import อันนี้เพื่อใช้ Timestamp

class ReviewModel {
  final String reviewId;
  final String restroomId;
  final String reviewerId;
  final String reviewerName;     // เพิ่ม: ชื่อคนรีวิว (เก็บไว้เลย โหลดเร็วไม่ต้อง join)
  final String reviewerPhotoUrl; // เพิ่ม: รูปโปรไฟล์คนรีวิว
  final double rating;
  final String comment;
  final DateTime timestamp;      // แก้: ใช้ DateTime แทน String
  final int totalLikes;
  final List<String> photos;     // เพิ่ม: รีวิวอาจจะมีรูปประกอบ

  ReviewModel({
    required this.reviewId,
    required this.restroomId,
    required this.reviewerId,
    required this.reviewerName,
    this.reviewerPhotoUrl = '',
    required this.rating,
    required this.comment,
    required this.timestamp,
    this.totalLikes = 0,
    this.photos = const [],
  });

  // 1. แปลงจาก Firestore (Map) -> Object
  factory ReviewModel.fromMap(Map<String, dynamic> map, String id) {
    return ReviewModel(
      reviewId: id,
      restroomId: map['restroomId'] ?? '',
      reviewerId: map['reviewerId'] ?? '',
      reviewerName: map['reviewerName'] ?? 'Anonymous',
      reviewerPhotoUrl: map['reviewerPhotoUrl'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      comment: map['comment'] ?? '',
      // แปลง Firestore Timestamp เป็น DateTime ของ Dart
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      totalLikes: (map['totalLikes'] ?? 0).toInt(),
      photos: List<String>.from(map['photos'] ?? []),
    );
  }

  // 2. แปลงจาก Object -> Map เพื่อบันทึก
  Map<String, dynamic> toMap() {
    return {
      'restroomId': restroomId,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'reviewerPhotoUrl': reviewerPhotoUrl,
      'rating': rating,
      'comment': comment,
      // แปลง DateTime กลับเป็น Server Timestamp
      'timestamp': Timestamp.fromDate(timestamp), 
      'totalLikes': totalLikes,
      'photos': photos,
    };
  }
}