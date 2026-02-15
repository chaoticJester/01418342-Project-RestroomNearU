import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/models/user_model.dart'; 

class UserService {
  final CollectionReference _userCollection =
      FirebaseFirestore.instance.collection('users');
  
  // Instance ของ FirebaseAuth เพื่อดึงข้อมูลคนล็อกอินปัจจุบัน
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // CREATE / SYNC: สร้างข้อมูล User ลง Firestore เมื่อ Login ครั้งแรก
  // ฟังก์ชันนี้ใช้เรียกหลังจาก Google Sign-In สำเร็จ
  Future<void> syncUserWithFirestore() async {
    final User? firebaseUser = _auth.currentUser;

    if (firebaseUser == null) return;

    final DocumentReference docRef = _userCollection.doc(firebaseUser.uid);
    final DocumentSnapshot doc = await docRef.get();

    // เช็คว่ามีข้อมูลใน Firestore หรือยัง?
    if (!doc.exists) {
      // ถ้ายังไม่มี (เพิ่งสมัครใหม่) ให้สร้างข้อมูลเริ่มต้น
      final newUser = UserModel(
        userId: firebaseUser.uid,
        displayName: firebaseUser.displayName ?? 'New User',
        email: firebaseUser.email ?? '',
        role: Role.user, // เริ่มต้นเป็น User ธรรมดา
        totalReviews: 0,
        reviewIds: [],
      );

      await docRef.set(newUser.toMap());
      print("New user created in Firestore");
    } else {
      print("User already exists, skipping create.");
    }
  }

  Future<void> createNewUser(UserModel user) async {
    await _userCollection.doc(user.userId).set(user.toMap());
  }

  // READ: อ่านข้อมูล User
  // 1. ดึงข้อมูล User ปัจจุบันแบบ Realtime (ใช้แสดงในหน้า Profile)
  Stream<UserModel?> getCurrentUserStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _userCollection.doc(user.uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  // 2. ดึงข้อมูล User อื่น (เช่น ดูโปรไฟล์คนรีวิว)
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _userCollection.doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print("Error fetching user: $e");
      return null;
    }
  }

  // 3. ค้นหาข้อมูล User จาก Email
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      // ค้นหาใน collection 'users' ที่ฟิลด์ 'email' ตรงกับที่กรอกมา
      final snapshot = await _userCollection
          .where('email', isEqualTo: email)
          .limit(1) // เอาแค่คนแรกที่เจอ
          .get();

      if (snapshot.docs.isNotEmpty) {
        // ถ้าเจอข้อมูล ให้แปลงเป็น UserModel
        return UserModel.fromMap(snapshot.docs.first.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print("Error fetching user by email: $e");
      return null;
    }
  }

  // 3. ตรวจสอบว่าเป็น Admin หรือไม่? 
  Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _userCollection.doc(user.uid).get();
    if (doc.exists) {
      final userData = UserModel.fromMap(doc.data() as Map<String, dynamic>);
      return userData.role == Role.admin;
    }
    return false;
  }

  // UPDATE: แก้ไขข้อมูล
  
  // 1. แก้ไขโปรไฟล์ (ชื่อ)
  Future<void> updateDisplayName(String newName) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _userCollection.doc(user.uid).update({
      'displayName': newName,
    });
    
    // อัปเดตใน Firebase Auth ด้วย (เพื่อให้ตรงกัน)
    await user.updateDisplayName(newName);
  }

  // 2. อัปเดตจำนวนรีวิว (ใช้เรียกเมื่อ User เขียนรีวิวเสร็จ)
  Future<void> incrementReviewCount(String reviewId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _userCollection.doc(user.uid).update({
      'totalReviews': FieldValue.increment(1),
      'reviewIds': FieldValue.arrayUnion([reviewId]) // เพิ่ม ID รีวิวลงใน List
    });
  }
}