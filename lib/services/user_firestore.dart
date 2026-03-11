import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '/models/user_model.dart'; 

class UserService {
  final CollectionReference _userCollection =
      FirebaseFirestore.instance.collection('users');
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Points values for Level System
  static const int pointsPerReview = 20;
  static const int pointsPerRestroomAdded = 50;
  static const int pointsPerHelpfulVote = 5;

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
        points: 0,
        reviewIds: [],
        photoUrl: firebaseUser.photoURL,
        favoriteRestrooms: [],
      );
      await docRef.set(newUser.toMap());
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
      debugPrint("Error fetching user: $e"); // ✅ FIX #12: was print()
      return null;
    }
  }

  /// Get user by email (needed for password reset check)
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
      debugPrint("Error fetching user by email: $e"); // ✅ FIX #12: was print()
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

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Delete Firestore data
    await _userCollection.doc(user.uid).delete();
    
    // Delete profile photo from storage if exists
    try {
      await FirebaseStorage.instance
          .ref()
          .child('profile_photos/${user.uid}.jpg')
          .delete();
    } catch (_) {}

    // Delete Auth account
    await user.delete();
  }

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
      await _userCollection.doc(user.uid).update({'photoUrl': downloadUrl});
      await user.updatePhotoURL(downloadUrl);
      return downloadUrl;
    } catch (e) {
      debugPrint("Error uploading profile photo: $e"); // ✅ FIX #12: was print()
      return null;
    }
  }

  Future<void> removeProfilePhoto() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_photos/${user.uid}.jpg');
      await ref.delete();
    } catch (_) {}

    await _userCollection.doc(user.uid).update({'photoUrl': FieldValue.delete()});
    await user.updatePhotoURL(null);
  }

  /// Increments totalAdded + points for the currently signed-in user.
  /// Used when a user submits a new restroom request themselves.
  Future<void> incrementAddedCount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _userCollection.doc(user.uid).update({
      'totalAdded': FieldValue.increment(1),
      'points': FieldValue.increment(pointsPerRestroomAdded),
    });
  }

  /// ✅ FIX #7 & #8: Increments totalAdded + points for an ARBITRARY userId.
  /// Used by admin approval flow so the submitter earns their points.
  Future<void> incrementAddedCountForUser(String userId) async {
    if (userId.isEmpty) return;
    await _userCollection.doc(userId).update({
      'totalAdded': FieldValue.increment(1),
      'points': FieldValue.increment(pointsPerRestroomAdded),
    });
  }

  Future<void> incrementHelpfulCount(String userId) async {
    await _userCollection.doc(userId).update({
      'totalHelpful': FieldValue.increment(1),
      'points': FieldValue.increment(pointsPerHelpfulVote),
    });
  }

  Future<void> decrementHelpfulCount(String userId) async {
    await _userCollection.doc(userId).update({
      'totalHelpful': FieldValue.increment(-1),
      'points': FieldValue.increment(-pointsPerHelpfulVote),
    });
  }

  Future<void> incrementReviewCount(String reviewId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _userCollection.doc(user.uid).update({
      'totalReviews': FieldValue.increment(1),
      'reviewIds': FieldValue.arrayUnion([reviewId]),
      'points': FieldValue.increment(pointsPerReview),
    });
  }

  Future<void> decrementReviewCount(String reviewId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _userCollection.doc(user.uid).update({
      'totalReviews': FieldValue.increment(-1),
      'reviewIds': FieldValue.arrayRemove([reviewId]),
      'points': FieldValue.increment(-pointsPerReview),
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
