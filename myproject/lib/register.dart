import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  
  // ซ่อนรหัสผ่าน
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _register() async {
    // เช็คว่ากรอกครบทุกช่องไหม
    if (_usernameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน'), backgroundColor: Colors.orange));
      return;
    }
    
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('รหัสผ่านไม่ตรงกัน'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    try {
      // สร้างบัญชีใน Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 3. บันทึกข้อมูลลง Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': 'user', 
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('สมัครสมาชิกสำเร็จ!'), backgroundColor: Colors.green));
      Navigator.pop(context); 
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ผิดพลาด: ${e.toString()}'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1828),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Create Account', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                const Text('สมัครสมาชิกเพื่อใช้งาน Campus Auto SOS', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 40),

                // ช่อง Username
                _buildTextField(_usernameController, 'ชื่อผู้ใช้งาน (Username)', Icons.person, false),
                const SizedBox(height: 16),
                
                // ช่อง Email
                _buildTextField(_emailController, 'อีเมล', Icons.email, false),
                const SizedBox(height: 16),
                
                // ช่อง รหัสผ่าน พร้อมปุ่มเปิดปิดตา
                _buildPasswordField(
                  _passwordController, 
                  'รหัสผ่าน (ขั้นต่ำ 6 ตัวอักษร)', 
                  _obscurePassword, 
                  () => setState(() => _obscurePassword = !_obscurePassword)
                ),
                const SizedBox(height: 16),
                
                // ช่อง ยืนยันรหัสผ่าน พร้อมปุ่มเปิดปิดตา
                _buildPasswordField(
                  _confirmPasswordController, 
                  'ยืนยันรหัสผ่านอีกครั้ง', 
                  _obscureConfirmPassword, 
                  () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword)
                ),
                const SizedBox(height: 40),

                _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          minimumSize: const Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _register,
                        child: const Text('Sign Up', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),

                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("มีบัญชีอยู่แล้ว? ", style: TextStyle(color: Colors.white70)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text('เข้าสู่ระบบ', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
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

  // วิดเจ็ตสำหรับช่องกรอกปกติ (Username, Email)
  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon, bool isPassword) {
    return TextField(
      controller: ctrl,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  // 4. วิดเจ็ตใหม่สำหรับช่องรหัสผ่านที่มีปุ่ม "ตา" (Eye Icon)
  Widget _buildPasswordField(TextEditingController ctrl, String hint, bool isObscure, VoidCallback onToggle) {
    return TextField(
      controller: ctrl,
      obscureText: isObscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: const Icon(Icons.lock, color: Colors.white70),
        suffixIcon: IconButton(
          icon: Icon(isObscure ? Icons.visibility_off : Icons.visibility, color: Colors.white70),
          onPressed: onToggle, // เวลากดจะสลับค่าเปิด-ปิดตา
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}