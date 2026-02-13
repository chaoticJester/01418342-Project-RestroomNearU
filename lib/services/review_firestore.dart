import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/review_model.dart'; 

class ReviewService {
  final CollectionReference _reviewCollection =
      FirebaseFirestore.instance.collection('reviews');

  // CREATE: เขียนรีวิวใหม่
  Future<void> addReviewWithRatingUpdate(ReviewModel review) async {
    final firestore = FirebaseFirestore.instance;
    final restroomRef = firestore.collection('restrooms').doc(review.restroomId);
    final reviewRef = _reviewCollection.doc(); // สร้าง ID ใหม่

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
      reviewData['timestamp'] = FieldValue.serverTimestamp();

      // 4. เขียนลง database (ทำพร้อมกันทั้ง 2 ที่)
      transaction.set(reviewRef, reviewData); // สร้างรีวิว
      transaction.update(restroomRef, {       // อัปเดตคะแนนห้องน้ำ
        'avgRating': newAvg,
        'totalRatings': newTotal,
      });
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

  // UPDATE: แก้ไขรีวิว
  Future<void> updateReview(String reviewId, String newComment, double newRating) async {
    try {
      await _reviewCollection.doc(reviewId).update({
        'comment': newComment,
        'rating': newRating,
        'timestamp': FieldValue.serverTimestamp(), // อัปเดตเวลาแก้ไขล่าสุด
      });
    } catch (e) {
      print("Error updating review: $e");
      rethrow;
    }
  }
  
  // ฟังก์ชันกด Like รีวิว
  Future<void> likeReview(String reviewId) async {
     // ใช้ FieldValue.increment(1) เพื่อป้องกัน Race Condition เวลามีคนกดพร้อมกัน
     await _reviewCollection.doc(reviewId).update({
       'totalLikes': FieldValue.increment(1),
     });
  }

  // DELETE: ลบรีวิว
  Future<void> deleteReview(String reviewId) async {
    try {
      await _reviewCollection.doc(reviewId).delete();
    } catch (e) {
      print("Error deleting review: $e");
      rethrow;
    }
  }
}