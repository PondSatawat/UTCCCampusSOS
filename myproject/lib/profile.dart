import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // ฟังก์ชันออกจากระบบ
  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // ฟังก์ชันเปลี่ยนชื่อผู้ใช้งาน
  void _updateUsername(BuildContext context, String currentUid) {
    TextEditingController nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0A1828),
          title: const Text('เปลี่ยนชื่อผู้ใช้งาน', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: nameCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'กรอกชื่อใหม่',
              hintStyle: TextStyle(color: Colors.white54),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(currentUid)
                      .update({'username': nameCtrl.text.trim()});
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('บันทึก', style: TextStyle(color: Colors.blueAccent)),
            ),
          ],
        );
      },
    );
  }

  // ฟังก์ชันเปลี่ยนรหัสผ่าน
  void _changePassword(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    TextEditingController passCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0A1828),
          title: const Text('เปลี่ยนรหัสผ่านใหม่', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: passCtrl,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'รหัสผ่านใหม่ (6 ตัวขึ้นไป)',
              hintStyle: TextStyle(color: Colors.white54),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await user!.updatePassword(passCtrl.text.trim());
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('เปลี่ยนรหัสผ่านสำเร็จ'), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ต้องล็อกอินใหม่ก่อนเปลี่ยนรหัสผ่าน'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('บันทึก', style: TextStyle(color: Colors.blueAccent)),
            ),
          ],
        );
      },
    );
  }

  // ฟังก์ชันลบบัญชี
  void _deleteAccount(BuildContext context, String currentUid) {
    final user = FirebaseAuth.instance.currentUser;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0A1828),
          title: const Text('ยืนยันการลบบัญชี', style: TextStyle(color: Colors.redAccent)),
          content: const Text(
            'คุณแน่ใจหรือไม่ที่จะลบบัญชี? ข้อมูลทั้งหมดจะหายไปและไม่สามารถกู้คืนได้',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance.collection('users').doc(currentUid).delete();
                  await user!.delete();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ต้องล็อกอินใหม่ก่อนทำการลบบัญชี'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('ลบบัญชี', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );
  }

  // ข้อมูลเกี่ยวกับแอป
  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0A1828),
          title: const Text('About This App', style: TextStyle(color: Colors.white)),
          content: const Text(
            'UTCC Campus SOS\nVersion 2.0\n\nแอปพลิเคชันช่วยเหลือฉุกเฉินสำหรับนักศึกษาและบุคลากร มหาวิทยาลัยหอการค้าไทย',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ปิด', style: TextStyle(color: Colors.blueAccent)),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: const Color(0xFF0A1828),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('My Profile',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 8, bottom: 24),
                decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(2)),
              ),

              // ส่วนแสดงข้อมูลโปรไฟล์แบบ Real-time
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
                builder: (context, snapshot) {
                  String username = 'กำลังโหลด...';
                  String role = 'user';

                  if (snapshot.hasData && snapshot.data!.exists) {
                    var data = snapshot.data!.data() as Map<String, dynamic>;
                    username = data['username'] ?? 'User';
                    role = data['role'] ?? 'user';
                  }

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blueAccent.withOpacity(0.3), width: 1.5),
                    ),
                    child: Column(
                      children: [
                        // รูป Profile แบบ Fixed Icon
                        const CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.white10,
                          child: Icon(Icons.person, size: 50, color: Colors.white70),
                        ),
                        const SizedBox(height: 16),
                        Text(username,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 8),

                        // Badge แสดง Role ของผู้ใช้
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: role == 'admin' 
                                ? Colors.redAccent.withOpacity(0.15) 
                                : Colors.blueAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: role == 'admin' ? Colors.redAccent : Colors.blueAccent),
                          ),
                          child: Text(
                            role.toUpperCase(),
                            style: TextStyle(
                              color: role == 'admin' ? Colors.redAccent : Colors.blueAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),
                        Text(user.email ?? '', style: const TextStyle(fontSize: 14, color: Colors.white54)),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 35),
              const Text('Settings',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 10),

              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildSettingsItem('Update username', () => _updateUsername(context, user.uid)),
                    _buildSettingsItem('Change password', () => _changePassword(context)),
                    _buildSettingsItem('Delete my account', () => _deleteAccount(context, user.uid)),
                    _buildSettingsItem('About this app', () => _showAbout(context)),
                    const SizedBox(height: 15),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Logout',
                          style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                      onTap: () => _logout(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // วิดเจ็ตสร้างปุ่มเมนู Setting
  Widget _buildSettingsItem(String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 16)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
      onTap: onTap,
    );
  }
}