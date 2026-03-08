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
import 'package:restroom_near_u/pages/admin/admin_users_page.dart';
import 'package:provider/provider.dart';
import 'package:restroom_near_u/providers/app_auth_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 
  
  await dotenv.load(fileName: ".env");
  
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
        '/admin_users': (context) => const AdminUsersPage(),
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
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          if(authSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if(authSnapshot.hasData) {
            final User firebaseUser = authSnapshot.data!;

            return StreamBuilder<UserModel?>(
              stream: UserService().getUserStream(firebaseUser.uid),
              builder: (context, userSnapshot) {
                if(userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                if(userSnapshot.hasData && userSnapshot.data != null) {
                  final UserModel userModel = userSnapshot.data!;

                  // ── Check if Banned ──
                  if (userModel.isBanned) {
                    return _RestrictedAccessScreen(
                      title: 'Account Banned',
                      message: 'Your account has been permanently banned for violating our terms of service.',
                      icon: Icons.gavel_rounded,
                    );
                  }

                  // ── Check if Suspended ──
                  if (userModel.isSuspended) {
                    final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(userModel.suspendedUntil!);
                    return _RestrictedAccessScreen(
                      title: 'Account Suspended',
                      message: 'Your account is temporarily suspended until $dateStr.',
                      icon: Icons.timer_rounded,
                    );
                  }

                  if(userModel.role == Role.admin) {
                    return const AdminHomePage();
                  } else {
                    return const UserHomePage();
                  }
                }

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

class _RestrictedAccessScreen extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const _RestrictedAccessScreen({
    required this.title,
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9EA),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 80, color: Colors.red),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1C1B1F)),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Color(0xFF6B6874)),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => FirebaseAuth.instance.signOut(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7BBFBA),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
