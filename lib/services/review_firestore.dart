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

      // 2. คำนวณค่าเฉลี่ยใหม่
      double currentAvg = (restroomSnapshot.get('avgRating') ?? 0.0).toDouble();
      int currentTotal = (restroomSnapshot.get('totalRatings') ?? 0).toInt();

      int newTotal = currentTotal + 1;
      // สูตรคำนวณค่าเฉลี่ยแบบสะสม: ((ค่าเก่า * จำนวนเก่า) + คะแนนใหม่) / จำนวนใหม่
      double newAvg = ((currentAvg * currentTotal) + review.rating) / newTotal;

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
        'totalRatings': newTotal,
      });

      await UserService().incrementReviewCount(reviewRef.id);
    });
  }

  // READ: อ่านข้อมูลรีวิว

  // 1. ดึงรีวิวทั้งหมดของ "ห้องน้ำหนึ่งๆ" (เรียงตามเวลาล่าสุด)
  Stream<List<ReviewModel>> getReviewsByRestroom(String restroomId) {
    return _reviewCollection
        .where('restroomId', isEqualTo: restroomId) // Filter เฉพาะห้องน้ำนี้
        .orderBy('timestamp', descending: true)     // ใหม่สุดขึ้นก่อน
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

  // 2. ดึงประวัติรีวิวของ "ผู้ใช้คนหนึ่ง" (เช่น หน้า My Reviews)
  Stream<List<ReviewModel>> getReviewsByUser(String userId) {
    return _reviewCollection
        .where('reviewerId', isEqualTo: userId)
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

  Stream<List<ReviewModel>> getReviewsByRestroomId(String restroomId) {
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

  // UPDATE: แก้ไขรีวิว
  Future<void> updateReview(String reviewId, String restroomId, double oldRating, double newRating, String newComment) async {
    final firestore = FirebaseFirestore.instance;
    final restroomRef = firestore.collection('restrooms').doc(restroomId);
    final reviewRef = _reviewCollection.doc(reviewId);

    return firestore.runTransaction((transaction) async {
      // 1. Read current restroom data first
      DocumentSnapshot restroomSnapshot = await transaction.get(restroomRef);
      if (!restroomSnapshot.exists) {
        throw Exception("Restroom does not exist!");
      }

      // 2. Calculate new average by swapping old rating out, new rating in
      double currentAvg = (restroomSnapshot.get('avgRating') ?? 0.0).toDouble();
      int currentTotal = (restroomSnapshot.get('totalRatings') ?? 0).toInt();

      double newAvg = currentTotal <= 0 ? newRating : ((currentAvg * currentTotal) - oldRating + newRating) / currentTotal;

      // 3. Update review content and restroom rating simultaneously
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
  
  // ฟังก์ชันกด Like รีวิว
  Future<void> toggleLikeReview(String reviewId, String userId) async {
    final reviewRef = _reviewCollection.doc(reviewId);
    final snapshot = await reviewRef.get();

    if (!snapshot.exists) return;

    final List likedBy = snapshot.get('likedBy') ?? [];
    final bool alreadyLiked = likedBy.contains(userId);

    await reviewRef.update({
      'totalLikes': FieldValue.increment(alreadyLiked ? -1 : 1),
      'likedBy': alreadyLiked 
          ? FieldValue.arrayRemove([userId]) 
          : FieldValue.arrayUnion([userId]),
    });
  }

  // DELETE: ลบรีวิว
  Future<void> deleteReview(String reviewId, double rating, String restroomId) async {
    final firestore = FirebaseFirestore.instance;
    final restroomRef = firestore.collection('restrooms').doc(restroomId);
    final reviewRef = _reviewCollection.doc(reviewId);

    await firestore.runTransaction((transaction) async {
      // 1. Read the current restroom data first
      DocumentSnapshot restroomSnapshot = await transaction.get(restroomRef);
      if (!restroomSnapshot.exists) {
        throw Exception("Restroom does not exist!");
      }

      // 2. Calculate new average
      double currentAvg = (restroomSnapshot.get('avgRating') ?? 0.0).toDouble();
      int currentTotal = (restroomSnapshot.get('totalRatings') ?? 0).toInt();

      int newTotal = currentTotal - 1;

      // 3. Edge case: last review deleted → reset to 0
      double newAvg = newTotal <= 0 ? 0.0 : ((currentAvg * currentTotal) - rating) / newTotal;

      // 4. Delete review and update restroom rating simultaneously
      transaction.delete(reviewRef);
      transaction.update(restroomRef, {
        'avgRating': newAvg,
        'totalRatings': newTotal < 0 ? 0 : newTotal, 
      });
    });
    await UserService().incrementReviewCount(reviewRef.id);
  }

  // ฟังก์ชันคืนค่าคำบรรยายตามช่วงคะแนน 
  String getRatingBadge(double rating) {
    if (rating >= 4.5) return 'Awesome!';
    if (rating >= 3.5) return 'Good';
    if (rating >= 2.5) return 'Average';
    if (rating >= 1.5) return 'Poor';
    return 'Terrible';
  }
}