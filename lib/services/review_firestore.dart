import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/review_model.dart'; 
import 'package:restroom_near_u/services/user_firestore.dart';

class ReviewService {
  final CollectionReference _reviewCollection =
      FirebaseFirestore.instance.collection('reviews');

  // CREATE: เขียนรีวิวใหม่
  Future<void> addReviewWithRatingUpdate(ReviewModel review) async {
    final firestore = FirebaseFirestore.instance;
    final restroomRef = firestore.collection('restrooms').doc(review.restroomId);
    final reviewRef = _reviewCollection.doc(review.reviewId); 

    return firestore.runTransaction((transaction) async {
      // 1. อ่านข้อมูลห้องน้ำปัจจุบันมาก่อน
      DocumentSnapshot restroomSnapshot = await transaction.get(restroomRef);
      if (!restroomSnapshot.exists) {
        throw Exception("Restroom does not exist!");
      }

      // 2. คำนวณค่าเฉลี่ยใหม่สำหรับทุกหมวดหมู่
      int currentTotal = (restroomSnapshot.get('totalRatings') ?? 0).toInt();
      int newTotal = currentTotal + 1;

      double currentAvg = (restroomSnapshot.get('avgRating') ?? 0.0).toDouble();
      double newAvg = ((currentAvg * currentTotal) + review.rating) / newTotal;

      double currentClean = (restroomSnapshot.get('avgCleanliness') ?? 0.0).toDouble();
      double newClean = ((currentClean * currentTotal) + review.cleanlinessRating) / newTotal;

      double currentAvail = (restroomSnapshot.get('avgAvailability') ?? 0.0).toDouble();
      double newAvail = ((currentAvail * currentTotal) + review.availabilityRating) / newTotal;

      double currentAmen = (restroomSnapshot.get('avgAmenities') ?? 0.0).toDouble();
      double newAmen = ((currentAmen * currentTotal) + review.amenitiesRating) / newTotal;

      double currentScent = (restroomSnapshot.get('avgScent') ?? 0.0).toDouble();
      double newScent = ((currentScent * currentTotal) + review.smellRating) / newTotal;

      // 3. เตรียมข้อมูลรีวิว
      Map<String, dynamic> reviewData = review.toMap();
      reviewData['reviewId'] = reviewRef.id;
      
      // Override ALL time fields to guarantee they match perfectly on the server
      reviewData['timestamp'] = FieldValue.serverTimestamp();
      reviewData['createdAt'] = FieldValue.serverTimestamp();
      reviewData['updatedAt'] = FieldValue.serverTimestamp();

      // 4. เขียนลง database (ทำพร้อมกันทั้ง 2 ที่)
      transaction.set(reviewRef, reviewData); // สร้างรีวิว
      transaction.update(restroomRef, {       // อัปเดตคะแนนห้องน้ำ
        'avgRating': newAvg,
        'avgCleanliness': newClean,
        'avgAvailability': newAvail,
        'avgAmenities': newAmen,
        'avgScent': newScent,
        'totalRatings': newTotal,
      });
    });

    // ✅ Increment review count AFTER transaction completes
    await UserService().incrementReviewCount(reviewRef.id);
  }

  // READ: อ่านข้อมูลรีวิว

  Stream<List<ReviewModel>> getReviewsByRestroom(String restroomId) {
    return _reviewCollection
        .where('restroomId', isEqualTo: restroomId) 
        .orderBy('timestamp', descending: true)     
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ReviewModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  Stream<List<ReviewModel>> getReviewsByUser(String userId) {
    return _reviewCollection
        .where('reviewerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return ReviewModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }

  Stream<List<ReviewModel>> getReviewsByRestroomId(String restroomId) {
    return _reviewCollection
        .where('restroomId', isEqualTo: restroomId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return ReviewModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }

  // UPDATE: แก้ไขรีวิว
  Future<void> updateReview(String reviewId, String restroomId, double oldRating, double newRating, String newComment) async {
    final firestore = FirebaseFirestore.instance;
    final restroomRef = firestore.collection('restrooms').doc(restroomId);
    final reviewRef = _reviewCollection.doc(reviewId);

    return firestore.runTransaction((transaction) async {
      DocumentSnapshot restroomSnapshot = await transaction.get(restroomRef);
      if (!restroomSnapshot.exists) {
        throw Exception("Restroom does not exist!");
      }

      double currentAvg = (restroomSnapshot.get('avgRating') ?? 0.0).toDouble();
      int currentTotal = (restroomSnapshot.get('totalRatings') ?? 0).toInt();

      double newAvg = currentTotal <= 0 ? newRating : ((currentAvg * currentTotal) - oldRating + newRating) / currentTotal;

      transaction.update(reviewRef, {
        'comment': newComment,
        'rating': newRating,
        'timestamp': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.update(restroomRef, {
        'avgRating': newAvg,
      });
    });
  }
  
  Future<void> toggleLikeReview(String reviewId, String userId) async {
    final reviewRef = _reviewCollection.doc(reviewId);
    final snapshot = await reviewRef.get();

    if (!snapshot.exists) return;

    final data = snapshot.data() as Map<String, dynamic>;
    final List likedBy = data['likedBy'] ?? [];
    final bool alreadyLiked = likedBy.contains(userId);
    final String reviewerId = data['reviewerId'] ?? '';

    await reviewRef.update({
      'totalLikes': FieldValue.increment(alreadyLiked ? -1 : 1),
      'likedBy': alreadyLiked 
          ? FieldValue.arrayRemove([userId]) 
          : FieldValue.arrayUnion([userId]),
    });

    if (reviewerId.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(reviewerId)
          .update({'totalHelpful': FieldValue.increment(alreadyLiked ? -1 : 1)});
    }
  }

  // DELETE: ลบรีวิว
  Future<void> deleteReview(String reviewId, double rating, String restroomId) async {
    final firestore = FirebaseFirestore.instance;
    final restroomRef = firestore.collection('restrooms').doc(restroomId);
    final reviewRef = _reviewCollection.doc(reviewId);

    await firestore.runTransaction((transaction) async {
      DocumentSnapshot restroomSnapshot = await transaction.get(restroomRef);
      if (!restroomSnapshot.exists) {
        throw Exception("Restroom does not exist!");
      }

      double currentAvg = (restroomSnapshot.get('avgRating') ?? 0.0).toDouble();
      int currentTotal = (restroomSnapshot.get('totalRatings') ?? 0).toInt();

      int newTotal = currentTotal - 1;
      double newAvg = newTotal <= 0 ? 0.0 : ((currentAvg * currentTotal) - rating) / newTotal;

      transaction.delete(reviewRef);
      transaction.update(restroomRef, {
        'avgRating': newAvg,
        'totalRatings': newTotal < 0 ? 0 : newTotal, 
      });
    });
    await UserService().incrementReviewCount(reviewRef.id);
  }

  String getRatingBadge(double rating) {
    if (rating >= 4.5) return 'Awesome!';
    if (rating >= 3.5) return 'Good';
    if (rating >= 2.5) return 'Average';
    if (rating >= 1.5) return 'Poor';
    return 'Terrible';
  }
}