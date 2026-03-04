import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '/models/user_model.dart'; 

class UserService {
  final CollectionReference _userCollection =
      FirebaseFirestore.instance.collection('users');
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // CREATE / SYNC
  Future<void> syncUserWithFirestore() async {
    final User? firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return;

    final DocumentReference docRef = _userCollection.doc(firebaseUser.uid);
    final DocumentSnapshot doc = await docRef.get();

    if (!doc.exists) {
      final newUser = UserModel(
        userId: firebaseUser.uid,
        displayName: firebaseUser.displayName ?? 'New User',
        email: firebaseUser.email ?? '',
        role: Role.user,
        totalReviews: 0,
        reviewIds: [],
        photoUrl: firebaseUser.photoURL,
        favoriteRestrooms: [],
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

  // READ
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

  Stream<UserModel?> getUserStream(String userId) {
    return _userCollection.doc(userId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

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

  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final snapshot = await _userCollection
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return UserModel.fromMap(snapshot.docs.first.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print("Error fetching user by email: $e");
      return null;
    }
  }

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

  // UPDATE

  Future<void> updateDisplayName(String newName) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _userCollection.doc(user.uid).update({'displayName': newName});
    await user.updateDisplayName(newName);
  }

  /// ✅ NEW: Upload a profile photo to Firebase Storage and save URL to Firestore
  Future<String?> uploadProfilePhoto(File imageFile) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_photos/${user.uid}.jpg');

      final uploadTask = await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Save URL to Firestore
      await _userCollection.doc(user.uid).update({'photoUrl': downloadUrl});

      // Also update Firebase Auth profile
      await user.updatePhotoURL(downloadUrl);

      return downloadUrl;
    } catch (e) {
      print("Error uploading profile photo: $e");
      return null;
    }
  }

  /// ✅ NEW: Remove profile photo
  Future<void> removeProfilePhoto() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Delete from Storage
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_photos/${user.uid}.jpg');
      await ref.delete();
    } catch (_) {
      // File might not exist, ignore
    }

    // Remove URL from Firestore
    await _userCollection.doc(user.uid).update({'photoUrl': FieldValue.delete()});
    await user.updatePhotoURL(null);
  }

  Future<void> incrementAddedCount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _userCollection.doc(user.uid).update({
      'totalAdded': FieldValue.increment(1),
    });
  }

  Future<void> incrementHelpfulCount(String userId) async {
    await _userCollection.doc(userId).update({
      'totalHelpful': FieldValue.increment(1),
    });
  }

  Future<void> decrementHelpfulCount(String userId) async {
    await _userCollection.doc(userId).update({
      'totalHelpful': FieldValue.increment(-1),
    });
  }

  Future<void> incrementReviewCount(String reviewId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _userCollection.doc(user.uid).update({
      'totalReviews': FieldValue.increment(1),
      'reviewIds': FieldValue.arrayUnion([reviewId]),
    });
  }

  Future<void> decrementReviewCount(String reviewId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _userCollection.doc(user.uid).update({
      'totalReviews': FieldValue.increment(-1),
      'reviewIds': FieldValue.arrayRemove([reviewId]),
    });
  }

  Future<void> addFavoriteRestroom(String restroomId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _userCollection.doc(user.uid).update({
      'favoriteRestrooms': FieldValue.arrayUnion([restroomId]),
    });
  }

  Future<void> removeFavoriteRestroom(String restroomId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _userCollection.doc(user.uid).update({
      'favoriteRestrooms': FieldValue.arrayRemove([restroomId]),
    });
  }

}
