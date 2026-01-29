import 'dart:io';
import 'package:flutter/material.dart';
import 'package:restroom_near_u/login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/login_page': (context) => LoginPage()
      }, 
      home: LoginPage(),
    );
  }
}
