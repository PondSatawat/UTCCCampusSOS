import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';
import 'register.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

Future<void> _login() async {
    // 1. เพิ่มแจ้งเตือนกรณีลืมกรอกข้อมูล
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกอีเมลและรหัสผ่านให้ครบถ้วน'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ล็อกอินด้วย Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
      String uid = userCredential.user!.uid;

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!mounted) return;

      // 3. ตรวจสอบสิทธิ์ (Role)
      if (userDoc.exists && userDoc['role'] == 'admin') {
        
        await FirebaseMessaging.instance.subscribeToTopic('admin_alerts');
        
        // 2. ใส่คำสั่งเปลี่ยนหน้าให้ Admin ด้วย!
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainTabScreen()),
        );

      } else {
        // ให้ User ปกติ รอรับแจ้งเตือนของตัวเอง
        await FirebaseMessaging.instance.subscribeToTopic('user_$uid');

        // พา User ปกติไปหน้า MainTabScreen
        if (!mounted) return; 
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainTabScreen()),
        );
      }

      // แสดงข้อความต้อนรับ
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เข้าสู่ระบบสำเร็จ'),
          backgroundColor: Colors.green, // ใช้สีเขียวให้ดูสำเร็จ
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('อีเมลหรือรหัสผ่านไม่ถูกต้อง'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1828),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.car_crash, size: 80, color: Colors.white),
                const SizedBox(height: 15),
                const Text(
                  'UTCC Campus SOS',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'เข้าสู่ระบบเพื่อดำเนินการต่อ',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 40),

                _buildTextField(_emailController, 'อีเมล', Icons.email, false),
                const SizedBox(height: 16),
                _buildTextField(
                  _passwordController,
                  'รหัสผ่าน',
                  Icons.lock,
                  true,
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text(
                      'ลืมรหัสผ่าน?',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),

                _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          minimumSize: const Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _login,
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                const SizedBox(height: 30),
                _buildDivider(),
                const SizedBox(height: 20),

                // --- ปุ่ม Social Login ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSocialButton(Icons.g_mobiledata, Colors.red, () {}),
                    const SizedBox(width: 20),
                    _buildSocialButton(Icons.facebook, Colors.blue, () {}),
                    const SizedBox(width: 20),
                    _buildSocialButton(Icons.apple, Colors.black, () {}),
                  ],
                ),

                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "ยังไม่มีบัญชีใช่ไหม? ",
                      style: TextStyle(color: Colors.white70),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'สมัครสมาชิก',
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Widgets ย่อยเพื่อความคลีน ---
  Widget _buildTextField(
    TextEditingController ctrl,
    String hint,
    IconData icon,
    bool isPassword,
  ) {
    return TextField(
      controller: ctrl,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Row(
      children: [
        Expanded(child: Divider(color: Colors.white24, thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'Or continue with',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        Expanded(child: Divider(color: Colors.white24, thickness: 1)),
      ],
    );
  }

  Widget _buildSocialButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(icon, color: color, size: 35),
      ),
    );
  }
}
