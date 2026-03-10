import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/review_model.dart'; 
import 'package:restroom_near_u/services/user_firestore.dart';
import 'package:flutter/foundation.dart';

class ReviewService {
  final CollectionReference _reviewCollection =
      FirebaseFirestore.instance.collection('reviews');

  // CREATE: เขียนรีวิวใหม่
  Future<void> addReviewWithRatingUpdate(ReviewModel review) async {
    final firestore = FirebaseFirestore.instance;
    final restroomRef = firestore.collection('restrooms').doc(review.restroomId);
    final reviewRef = _reviewCollection.doc(review.reviewId); 

    try {
      await firestore.runTransaction((transaction) async {
        // 1. อ่านข้อมูลห้องน้ำปัจจุบันมาก่อน
        DocumentSnapshot restroomSnapshot = await transaction.get(restroomRef);
        if (!restroomSnapshot.exists) {
          throw Exception("Restroom does not exist!");
        }

        final data = restroomSnapshot.data() as Map<String, dynamic>;

        // 2. คำนวณค่าเฉลี่ยใหม่สำหรับทุกหมวดหมู่
        int currentTotal = (data['totalRatings'] ?? 0).toInt();
        int newTotal = currentTotal + 1;

        double currentAvg = (data['avgRating'] ?? 0.0).toDouble();
        double newAvg = ((currentAvg * currentTotal) + review.rating) / newTotal;

        double currentClean = (data['avgCleanliness'] ?? 0.0).toDouble();
        double newClean = ((currentClean * currentTotal) + review.cleanlinessRating) / newTotal;

        double currentAvail = (data['avgAvailability'] ?? 0.0).toDouble();
        double newAvail = ((currentAvail * currentTotal) + review.availabilityRating) / newTotal;

        double currentAmen = (data['avgAmenities'] ?? 0.0).toDouble();
        double newAmen = ((currentAmen * currentTotal) + review.amenitiesRating) / newTotal;

        double currentScent = (data['avgScent'] ?? 0.0).toDouble();
        double newScent = ((currentScent * currentTotal) + review.smellRating) / newTotal;

        // 3. เตรียมข้อมูลรีวิว
        Map<String, dynamic> reviewData = review.toMap();
        reviewData['reviewId'] = reviewRef.id;
        
        // Override ALL time fields with server timestamp
        reviewData['timestamp'] = FieldValue.serverTimestamp();
        reviewData['createdAt'] = FieldValue.serverTimestamp();
        reviewData['updatedAt'] = FieldValue.serverTimestamp();

        // 4. เขียนลง database
        transaction.set(reviewRef, reviewData);
        transaction.update(restroomRef, {
          'avgRating': newAvg,
          'avgCleanliness': newClean,
          'avgAvailability': newAvail,
          'avgAmenities': newAmen,
          'avgScent': newScent,
          'totalRatings': newTotal,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }, timeout: const Duration(seconds: 15));

      // Increment review count AFTER transaction completes
      await UserService().incrementReviewCount(reviewRef.id);
      
    } catch (e) {
      debugPrint("Error in addReviewWithRatingUpdate: $e");
      rethrow;
    }
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
  // ✅ FIX #4: Now accepts all sub-ratings and updates them on the restroom document too.
  Future<void> updateReview({
    required String reviewId,
    required String restroomId,
    required double oldRating,
    required double newRating,
    required String newComment,
    // Sub-ratings — old values needed to recalculate the restroom averages
    required double oldCleanliness,
    required double newCleanliness,
    required double oldAvailability,
    required double newAvailability,
    required double oldAmenities,
    required double newAmenities,
    required double oldSmell,
    required double newSmell,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final restroomRef = firestore.collection('restrooms').doc(restroomId);
    final reviewRef = _reviewCollection.doc(reviewId);

    return firestore.runTransaction((transaction) async {
      DocumentSnapshot restroomSnapshot = await transaction.get(restroomRef);
      if (!restroomSnapshot.exists) {
        throw Exception("Restroom does not exist!");
      }

      final data = restroomSnapshot.data() as Map<String, dynamic>;
      int currentTotal = (data['totalRatings'] ?? 0).toInt();

      // ✅ Recalculate ALL averages by swapping old value for new value
      double _recalc(String field, double oldVal, double newVal) {
        double current = (data[field] ?? 0.0).toDouble();
        if (currentTotal <= 0) return newVal;
        return ((current * currentTotal) - oldVal + newVal) / currentTotal;
      }

      transaction.update(reviewRef, {
        'comment': newComment,
        'rating': newRating,
        'cleanlinessRating': newCleanliness,
        'availabilityRating': newAvailability,
        'amenitiesRating': newAmenities,
        'smellRating': newSmell,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.update(restroomRef, {
        'avgRating':       _recalc('avgRating',       oldRating,       newRating),
        'avgCleanliness':  _recalc('avgCleanliness',  oldCleanliness,  newCleanliness),
        'avgAvailability': _recalc('avgAvailability', oldAvailability, newAvailability),
        'avgAmenities':    _recalc('avgAmenities',    oldAmenities,    newAmenities),
        'avgScent':        _recalc('avgScent',        oldSmell,        newSmell),
        'updatedAt': FieldValue.serverTimestamp(),
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
      if (alreadyLiked) {
        await UserService().decrementHelpfulCount(reviewerId);
      } else {
        await UserService().incrementHelpfulCount(reviewerId);
      }
    }
  }

  // DELETE: ลบรีวิว
  // ✅ FIX #3: Now recalculates ALL sub-rating averages, not just avgRating.
  Future<void> deleteReview(ReviewModel review) async {
    final firestore = FirebaseFirestore.instance;
    final restroomRef = firestore.collection('restrooms').doc(review.restroomId);
    final reviewRef = _reviewCollection.doc(review.reviewId);

    await firestore.runTransaction((transaction) async {
      DocumentSnapshot restroomSnapshot = await transaction.get(restroomRef);
      if (!restroomSnapshot.exists) {
        throw Exception("Restroom does not exist!");
      }

      final data = restroomSnapshot.data() as Map<String, dynamic>;
      int currentTotal = (data['totalRatings'] ?? 0).toInt();
      int newTotal = currentTotal <= 1 ? 0 : currentTotal - 1;

      // ✅ Helper: recalculate an average after removing one value
      double _removeFromAvg(String field, double removedValue) {
        if (newTotal <= 0) return 0.0;
        double current = (data[field] ?? 0.0).toDouble();
        return ((current * currentTotal) - removedValue) / newTotal;
      }

      transaction.delete(reviewRef);
      transaction.update(restroomRef, {
        'totalRatings':    newTotal,
        'avgRating':       _removeFromAvg('avgRating',       review.rating),
        'avgCleanliness':  _removeFromAvg('avgCleanliness',  review.cleanlinessRating),
        'avgAvailability': _removeFromAvg('avgAvailability', review.availabilityRating),
        'avgAmenities':    _removeFromAvg('avgAmenities',    review.amenitiesRating),
        'avgScent':        _removeFromAvg('avgScent',        review.smellRating),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    await UserService().decrementReviewCount(review.reviewId);
  }

  String getRatingBadge(double rating) {
    if (rating >= 4.5) return 'Awesome!';
    if (rating >= 3.5) return 'Good';
    if (rating >= 2.5) return 'Average';
    if (rating >= 1.5) return 'Poor';
    return 'Terrible';
  }
}
