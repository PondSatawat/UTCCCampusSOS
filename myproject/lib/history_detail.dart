import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // สำหรับเปิดแผนที่
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';
import 'package:intl/intl.dart';

class HistoryDetailScreen extends StatefulWidget {
  final dynamic data;
  final String role; // รับสิทธิ์มาจากหน้าก่อนหน้า
  
  const HistoryDetailScreen({super.key, required this.data, required this.role});

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  late String _currentStatus;
  bool _isLoading = false;
  String _formatDate(String? dateStr) {
  if (dateStr == null || dateStr == "null") return '-';
  try {
    // แปลง String เป็น DateTime
    DateTime dt = DateTime.parse(dateStr);
    // กำหนดรูปแบบที่ต้องการ เช่น 20/04/2026 21:10
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  } catch (e) {
    return dateStr; // ถ้าแปลงไม่ได้ให้คืนค่าเดิม
  }
}

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.data['status'] ?? 'รอดำเนินการ'; // โหลดสถานะเริ่มต้น
  }

  // ฟังก์ชันเปิด Google Maps
  Future<void> _openGoogleMap() async {
    final lat = widget.data['latitude'];
    final lng = widget.data['longitude'];
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    
    if (!await launchUrl(url)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ไม่สามารถเปิดแผนที่ได้')));
      }
    }
  }

  // ฟังก์ชันอัปเดตสถานะไปที่ Spring Boot
Future<void> _updateStatus(String newStatus) async {
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/api/sos/updateStatus/${widget.data['id']}');
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': newStatus}),
      );

      if (response.statusCode == 200) {
        setState(() => _currentStatus = newStatus);
        
        if (newStatus == 'กำลังเดินทาง' || newStatus == 'เสร็จสิ้น') {
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('อัปเดตสถานะเป็น $newStatus สำเร็จ!'), backgroundColor: Colors.green)
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red)
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1828),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // โชว์สถานะปัจจุบันตัวใหญ่ๆ
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('สถานะปัจจุบัน:', style: TextStyle(color: Colors.white70, fontSize: 16)),
                        Text(_currentStatus, style: TextStyle(color: _currentStatus == 'เสร็จสิ้น' ? Colors.green : Colors.orangeAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  _buildInfoRow('ประเภทเหตุ', widget.data['problemType']),
                  _buildInfoRow('อาการ', widget.data['symptoms']),
                  _buildInfoRow('รถที่เกิดเหตุ', widget.data['vehicleInfo']),
                  _buildInfoRow('เบอร์โทร', widget.data['phoneNumber']),
                  _buildInfoRow('พิกัด (ละติจูด)', widget.data['latitude'].toString()),
                  _buildInfoRow('พิกัด (ลองจิจูด)', widget.data['longitude'].toString()),
                  _buildInfoRow('วันและเวลา', _formatDate(widget.data['createdAt'])),
                  
                  const SizedBox(height: 20),
                  
                  // ปุ่มเปิดแผนที่
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                    ),
                    onPressed: _openGoogleMap,
                    icon: const Icon(Icons.map, color: Colors.white),
                    label: const Text('นำทางด้วย Google Maps', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),

                  const SizedBox(height: 20),

                  // ส่วนของปุ่มช่าง (เห็นเฉพาะ Admin)
                  if (widget.role == 'admin') _buildAdminActions(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // วิดเจ็ตสร้างปุ่มให้ช่างตามสถานะปัจจุบัน
  Widget _buildAdminActions() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    if (_currentStatus == 'รอดำเนินการ') {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        onPressed: () => _updateStatus('กำลังเดินทาง'),
        child: const Text('กดรับงาน (กำลังเดินทาง)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      );
    } else if (_currentStatus == 'กำลังเดินทาง') {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        onPressed: () => _updateStatus('เสร็จสิ้น'),
        child: const Text('ปิดจ๊อบ (งานเสร็จสิ้น)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      );
    } else {
      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(border: Border.all(color: Colors.green), borderRadius: BorderRadius.circular(10)),
        child: const Text('ช่วยเหลือเคสนี้เสร็จสิ้นแล้ว 🎉', style: TextStyle(color: Colors.green, fontSize: 16)),
      );
    }
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
          const Text('รายละเอียดประวัติ', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16))),
          Expanded(child: Text(value?.toString() ?? '-', style: const TextStyle(color: Colors.white, fontSize: 16))),
        ],
      ),
    );
  }
}