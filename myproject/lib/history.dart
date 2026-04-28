import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'history_detail.dart';
import 'config.dart';
import 'dart:async';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _currentUserRole = 'user'; // เพิ่มตัวแปรเก็บ Role ไว้ส่งข้ามหน้า
  String _formatDate(String? dateStr) {
  if (dateStr == null) return '-';
  try {
    // แปลง String จาก API เป็น DateTime
    DateTime dt = DateTime.parse(dateStr);
    // Format เป็นรูปแบบที่ต้องการ (เช่น 20/04/2026 21:10)
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  } catch (e) {
    return dateStr;
  }
}

  Future<List<dynamic>> _fetchHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    
    _currentUserRole = userDoc['role'] ?? 'user'; // เก็บ Role ไว้

    String url = _currentUserRole == 'admin'
        ? '${AppConfig.baseUrl}/api/sos/all' 
        : '${AppConfig.baseUrl}/api/sos/user/${user.uid}'; 

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Failed to load history');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1828), 
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('History', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              Container(
                width: 40, height: 4, margin: const EdgeInsets.only(top: 8, bottom: 24),
                decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(2)),
              ),
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: _fetchHistory(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.white));
                    if (snapshot.hasError) return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
                    if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('ยังไม่มีประวัติการแจ้งเหตุ', style: TextStyle(color: Colors.white70)));

                    final data = snapshot.data!;

                    RefreshIndicator(
                      color: Colors.blueAccent,
                      backgroundColor: Colors.white,
                      onRefresh: () async {
                        setState(() {});
                      },
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        final item = data[index];
                        // เปลี่ยนสีไอคอนตามสถานะ
                        Color statusColor = item['status'] == 'เสร็จสิ้น' ? Colors.green : (item['status'] == 'เจ้าหน้าที่กำลังเดินทาง' ? Colors.orange : Colors.redAccent);

                        return Card(
                          elevation: 0,
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(backgroundColor: statusColor, child: const Icon(Icons.warning, color: Colors.white)),
                            title: Text('${item['problemType']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: Text('เวลา: ${_formatDate(item['createdAt'])}\n'
                                          'สถานที่: ${item['locationName']}\n'
                                          'สถานะ: ${item['status']}',
                                          style: const TextStyle(color: Colors.white70),
                              ),
                            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
                            isThreeLine: true,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  // ส่ง Role ไปให้หน้า Detail ด้วย
                                  builder: (context) => HistoryDetailScreen(data: item, role: _currentUserRole), 
                                ),
                              ).then((_) => setState(() {})); // โหลดข้อมูลใหม่เมื่อกดย้อนกลับมาหน้านี้ (เพื่ออัปเดตสถานะล่าสุด)
                            },
                          ),
                        );
                      },
                    ),
                    );
                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        final item = data[index];
                        // เปลี่ยนสีไอคอนตามสถานะ
                        Color statusColor = item['status'] == 'เสร็จสิ้น' ? Colors.green : (item['status'] == 'กำลังเดินทาง' ? Colors.orange : Colors.redAccent);

                        return Card(
                          elevation: 0,
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(backgroundColor: statusColor, child: const Icon(Icons.warning, color: Colors.white)),
                            title: Text('${item['problemType']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: Text('เวลา: ${_formatDate(item['createdAt'])}\n'
                                          'สถานที่: ${item['locationName']}\n'
                                          'สถานะ: ${item['status']}',
                                          style: const TextStyle(color: Colors.white70),
                              ),
                            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
                            isThreeLine: true,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  // ส่ง Role ไปให้หน้า Detail ด้วย
                                  builder: (context) => HistoryDetailScreen(data: item, role: _currentUserRole), 
                                ),
                              ).then((_) => setState(() {})); // โหลดข้อมูลใหม่เมื่อกดย้อนกลับมาหน้านี้ (เพื่ออัปเดตสถานะล่าสุด)
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}