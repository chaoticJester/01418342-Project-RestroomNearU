import 'package:flutter/material.dart'; 
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:restroom_near_u/providers/app_auth_provider.dart';
import 'register_page.dart';
import 'forget_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // สร้าง Controller รับค่าจากช่องกรอก
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ดึง authProvider มาใช้งาน
    final authProvider = Provider.of<AppAuthProvider>(context);

    return Scaffold( // 
      body: SafeArea(
        child: SingleChildScrollView( // เพิ่ม SingleChildScrollView กันคีย์บอร์ดบังหน้าจอ
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Text(
                  "Login here",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 25),
                const Text(
                  "Welcome to RestroomNearU",
                  style: TextStyle(fontSize: 25),
                  textAlign: TextAlign.center, 
                ),
                const SizedBox(height: 70),
                
                // ช่อง Email
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Email",
                    prefixIcon: const Icon(Icons.email), 
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), 
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey, width: 1.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue, width: 2.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), 
                  ),
                ),
                const SizedBox(height: 30),
                
                // ช่อง Password
                TextField(
                  controller: _passwordController,
                  obscureText: true, // ซ่อนรหัสผ่านเป็นจุดๆ
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: const Icon(Icons.key), 
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), 
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey, width: 1.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue, width: 2.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), 
                  ),
                ),
                const SizedBox(height: 10),
                
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ForgotPasswordPage()), 
                    );
                  },
                  child: const Text(
                    "Forgot your password?",
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold), 
                  ),
                ),
                const SizedBox(height: 10),
                
                // ปุ่ม Sign In (Email)
                SizedBox(
                  width: double.infinity, 
                  height: 50, 
                  child: ElevatedButton(
                    // ถ้ากำลังโหลด ให้ปุ่มกดไม่ได้ (null)
                    onPressed: authProvider.isLoading ? null : () {
                      authProvider.signInWithEmail(
                        _emailController.text.trim(), 
                        _passwordController.text.trim(), 
                        context
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue, 
                      foregroundColor: Colors.white, 
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), 
                      ),
                    ),
                    // ถ้าโหลดอยู่ให้โชว์วงกลมหมุนๆ
                    child: authProvider.isLoading 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Sign In", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 10),
                
                TextButton(
                  onPressed: () {
                    // เพิ่มบรรทัดนี้เพื่อเปิดหน้า Register
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterPage()), // อย่าลืม import RegisterPage ด้านบนด้วยนะครับ
                    );
                  },
                  child: const Text(
                    "Create new account",
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold), 
                  ),
                ),
                const SizedBox(height: 30),
                const Text("Or continue with", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                const SizedBox(height: 30),
                
                // ปุ่ม Google Sign In
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    // ป้องกันการกดซ้ำตอนโหลด
                    onPressed: authProvider.isLoading ? null : () {
                      authProvider.signInWithGoogle(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white, 
                      foregroundColor: Colors.black87, 
                      elevation: 2, 
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), 
                        side: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
                      ),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    icon: const Icon(FontAwesomeIcons.google, size: 20, color: Colors.black87),
                    label: const Text("Continue with Google"),
                  ),
                ),
              ],
            ),
          ),
        ),
      )
    );
  }
}