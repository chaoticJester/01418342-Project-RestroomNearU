import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart' ;
import 'package:restroom_near_u/services/user_firestore.dart'; 
import 'package:restroom_near_u/models/user_model.dart';
import 'package:restroom_near_u/pages/user/user_homepage.dart';

class AppAuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final UserService _userService = UserService(); 

  bool _isLoading = false;
  bool get isLoading => _isLoading; // ใช้บอก UI ว่ากำลังโหลดอยู่ไหม

  // ฟังก์ชันสมัครสมาชิกด้วย Email & Password 
  Future<void> signUpWithEmail(String name, String email, String password, BuildContext context) async {
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showError(context, "Please enter all the needed information.");
      return;
    }

    try {
      _setLoading(true);
      
      // สร้างบัญชีใน Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );

      final user = userCredential.user;

      if(user != null) {
        await user.updateDisplayName(name);
        
        final newUser = UserModel(
          userId: user.uid,
          displayName: name,
          email: email,
          role: Role.user,
          totalReviews: 0,
          reviewIds: []
        );

        await _userService.createNewUser(newUser);
      }

      if (context.mounted) {
        Navigator.pop(context); 
      }

    } on FirebaseAuthException catch (e) {
      // ดักจับ Error แจ้งเตือนผู้ใช้ เช่น รหัสสั้นไป, อีเมลซ้ำ
      String message = "Error occured: ${e.message}";
      if (e.code == 'weak-password') message = "Password must have at least 6 characters.";
      if (e.code == 'email-already-in-use') message = "This email is already used.";
      
      _showError(context, message);
    } catch (e) { 
      _showError(context, "System Error: ${e.toString()}");
      print("System Error: $e");
    } finally {
      _setLoading(false);
    }
  }

  // ฟังก์ชัน Login ด้วย Email & Password 
  Future<void> signInWithEmail(String email, String password, BuildContext context) async {
    if (email.isEmpty || password.isEmpty) {
      _showError(context, "Please enter your email and password.");
      return;
    }

    try {
      _setLoading(true);
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      // ถ้าสำเร็จ StreamBuilder ใน main.dart จะพาไปหน้า Home เอง

      
    } on FirebaseAuthException catch (e) {
      _showError(context, "Login failed: ${e.message}");
    } finally {
      _setLoading(false);
    }
  }

  // ฟังก์ชัน Login ด้วย Google 
  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      _setLoading(true);
      
      // ให้เด้งหน้าต่างเลือกบัญชี Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _setLoading(false);
        return; // ผู้ใช้กดยกเลิก
      }

      // ขอ Token จาก Google
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Login เข้า Firebase
      await _auth.signInWithCredential(credential);

      // สำคัญ: Sync ข้อมูลลง Database ของเรา (ดึง UserService ของคุณมาใช้)
      await _userService.syncUserWithFirestore();

    } catch (e) {
      _showError(context, "Login with google failed.");
      print(e);
    } finally {
      _setLoading(false);
    }
  }

  // ฟังก์ชันส่งอีเมลรีเซ็ตรหัสผ่าน 
  Future<void> resetPassword(String email, BuildContext context) async {
    if (email.isEmpty) {
      _showError(context, "Please enter your email.");
      return;
    }

    try {
      _setLoading(true);
      
      // 1. ดึงข้อมูล User จาก Database ด้วยอีเมลก่อน
      final userModel = await _userService.getUserByEmail(email);

      // 2. เช็คว่าเป็น Admin หรือไม่?
      if (userModel != null && userModel.role == Role.admin) {
        // ถ้าเป็น Admin ให้หยุดการทำงานทันที และโชว์ Error
        if (context.mounted) {
           _showError(context, "Admin passwords cannot be reset here. Please contact the system administrator.");
        }
        return; // เด้งออกจากฟังก์ชัน ไม่ทำคำสั่งบรรทัดถัดไป
      }

      // 3. ถ้าไม่ใช่ Admin (เป็น User ธรรมดา) ให้ส่งอีเมลรีเซ็ตตามปกติ
      await _auth.sendPasswordResetEmail(email: email);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Password reset link sent! Please check your email."),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); 
      }
    } on FirebaseAuthException catch (e) {
      String message = "Error: ${e.message}";
      if (e.code == 'user-not-found') message = "No user found for that email.";
      
      _showError(context, message);
    } finally {
      _setLoading(false);
    }
  }

  // Helper function จัดการสถานะโหลด
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners(); // สั่งให้ UI อัปเดต
  }

  // Helper function โชว์แจ้งเตือน Error
  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}