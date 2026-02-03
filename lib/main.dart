import 'package:flutter/material.dart';
import 'package:restroom_near_u/login_page.dart';
import 'package:restroom_near_u/home_page.dart';
import 'package:restroom_near_u/add_new_restroom_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/login_page': (context) => LoginPage(),
        '/home_page' : (context) => HomePage(),
        '/add_new_restroom': (context) => const AddNewRestroomPage(),
      }, 
      home: UserHomePage(),
    );
  }
}
