import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:restroom_near_u/models/user_model.dart';
import 'package:restroom_near_u/services/user_firestore.dart'; 
import 'package:restroom_near_u/pages/login_page.dart';
import 'package:restroom_near_u/pages/user/user_homepage.dart';
import 'package:restroom_near_u/pages/user/profile_page.dart';
import 'package:restroom_near_u/pages/user/add_new_restroom_page.dart';
import 'package:restroom_near_u/pages/admin/admin_homepage.dart';
import 'package:restroom_near_u/pages/admin/admin_request_page.dart';
import 'package:restroom_near_u/pages/admin/admin_report_page.dart';
import 'package:restroom_near_u/pages/admin/admin_total_toilets_page.dart';
import 'package:restroom_near_u/pages/admin/admin_profile_page.dart';
import 'package:provider/provider.dart';
import 'package:restroom_near_u/providers/app_auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 
  
  await Firebase.initializeApp( 
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppAuthProvider()),
      ],
      child: const MyApp(),
    )
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/login_page': (context) => LoginPage(),
        '/user_homepage' : (context) => UserHomePage(),
        '/add_new_restroom': (context) => const AddNewRestroomPage(),
        '/profile': (context) => const ProfilePage(),
        '/admin_homepage': (context) => AdminHomePage(),
        '/admin_requests': (context) => const AdminRequestPage(),
        '/admin_reports': (context) => const AdminReportPage(),
        '/admin_toilets': (context) => const AdminTotalToiletsPage(),
        '/admin_profile': (context) => const AdminProfilePage(),
      }, 
      theme: ThemeData(
        textTheme: const TextTheme(
          displayLarge:  TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          displaySmall:  TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          titleLarge:   TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          titleMedium:  TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          titleSmall:   TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          bodyLarge:    TextStyle(fontSize: 16),
          bodyMedium:   TextStyle(fontSize: 15),
          bodySmall:    TextStyle(fontSize: 13),
          labelLarge:   TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          labelMedium:  TextStyle(fontSize: 14),
          labelSmall:   TextStyle(fontSize: 12),
        ),
      ),
      home: StreamBuilder<User?>(
        // Login หรือยัง?
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          // เช็คสถานะ Auth
          if(authSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // มีไอดี Login อยู่
          if(authSnapshot.hasData) {
            final User firebaseUser = authSnapshot.data!;

            // ใช้ StreamBuilder แทน FutureBuilder
            // เพื่อให้ react ทันทีที่ Firestore document ถูกสร้าง
            return StreamBuilder<UserModel?>(
              stream: UserService().getUserStream(firebaseUser.uid),
              builder: (context, userSnapshot) {
                // ยังโหลดอยู่
                if(userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                // ได้ข้อมูลมาแล้ว → ส่งไปตาม role
                if(userSnapshot.hasData && userSnapshot.data != null) {
                  final UserModel userModel = userSnapshot.data!;
                  if(userModel.role == Role.admin) {
                    return const AdminHomePage();
                  } else {
                    return const UserHomePage();
                  }
                }

                // Document ยังไม่มี → แสดง loading รอ
                // (อาจเกิดระหว่าง register ก่อน Firestore doc จะถูกสร้าง)
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
            );
          }
          return const LoginPage();
        }
      ),
    );
  }
}
