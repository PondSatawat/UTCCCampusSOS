import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'config.dart';

class HomeScreen extends StatelessWidget {
  final Position? currentPosition;
  const HomeScreen({super.key, this.currentPosition});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1828),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(
              context,
            ), // 2. ส่ง context เข้าไปเผื่อไว้โชว์ Error แจ้งเตือน
            const SizedBox(height: 20),
            _buildBigSOSButton(context),
            const SizedBox(height: 40),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const Text(
                      'เลือกปัญหาที่พบ',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildCategoryItem(
                      context,
                      Icons.battery_alert,
                      Colors.orange,
                      'แบตหมด / สตาร์ทไม่ติด',
                      'ต้องการสายพ่วงแบต หรือ ผู้ช่วยเหลือ',
                    ),
                    _buildCategoryItem(
                      context,
                      Icons.tire_repair,
                      Colors.blueGrey,
                      'ยางแบน / ยางรั่ว',
                      'ต้องการอุปกรณ์เปลี่ยนยาง หรือ ร้านปะยาง',
                    ),
                    _buildCategoryItem(
                      context,
                      Icons.car_crash,
                      Colors.red,
                      'เครื่องยนต์มีปัญหา',
                      'สตาร์ทไม่ติด, เครื่องดับ, มีควัน',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. รับค่า BuildContext และแก้ตรง onPressed ของปุ่ม IconButton
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'UTCC Campus SOS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.phone, color: Colors.white),
              onPressed: () async {
                // คำสั่งเรียกแอปโทรศัพท์ (tel: ตามด้วยเบอร์)
                final Uri url = Uri.parse('tel:191');

                // ตรวจสอบว่ามือถือเครื่องนี้โทรออกได้ไหม
                if (!await launchUrl(url)) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'ไม่สามารถเปิดแอปโทรศัพท์ได้',
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBigSOSButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToForm(context, 'แจ้งเหตุฉุกเฉินด่วน'),
      child: Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.red.shade600,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.3),
              spreadRadius: 10,
              blurRadius: 20,
            ),
          ],
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'SOS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'แตะเพื่อขอความช่วยเหลือ',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryItem(
    BuildContext context,
    IconData icon,
    Color color,
    String title,
    String sub,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          sub,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: () => _navigateToForm(context, title),
      ),
    );
  }

  void _navigateToForm(BuildContext context, String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SosFormScreen(problemType: type, currentPosition: currentPosition),
      ),
    );
  }
}

class SosFormScreen extends StatefulWidget {
  final String problemType;
  final Position? currentPosition;
  const SosFormScreen({super.key, required this.problemType, this.currentPosition});

  @override
  State<SosFormScreen> createState() => _SosFormScreenState();
}

class _SosFormScreenState extends State<SosFormScreen> {
  final _phoneController = TextEditingController();
  final _symptomsController = TextEditingController();
  final _vehicleController = TextEditingController();
  final _locationController = TextEditingController();
  bool _isLoading = false;

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('กรุณาเปิด GPS');
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('ปฏิเสธการเข้าถึงพิกัด');
      }
    }
    return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
    ));
  }

  Future<void> _submitData() async {
    // 1. ป้องกันการกดปุ่มรัวๆ ถ้าระบบกำลังโหลดอยู่แล้วให้หยุดเลย
    if (_isLoading) return;

    // 2. สั่งให้หน้าจอขึ้นสถานะ Loading ทันที (โชว์ไอคอนหมุนๆ)
    setState(() => _isLoading = true);

    try{
    Position pos = await _determinePosition();

      final currentUser = FirebaseAuth.instance.currentUser;
      final String uid = currentUser?.uid ?? 'unknown';

      final url = Uri.parse('${AppConfig.baseUrl}/api/sos/request');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': uid,
          'problemType': widget.problemType,
          'phoneNumber': _phoneController.text,
          'symptoms': _symptomsController.text,
          'vehicleInfo': _vehicleController.text,
          'locationName': _locationController.text,
          'latitude': pos.latitude,
          'longitude': pos.longitude,
          'detail': 'ส่งจากแอป Campus SOS (Version 2.0)',
        }),
      );

      if (!mounted) return;

      // 3. พอส่งเสร็จ สั่งปิดสถานะ Loading
      setState(() => _isLoading = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ส่งข้อมูลสำเร็จ ทีมช่างกำลังไปหาคุณ!'),
            backgroundColor: Colors.green,
          ),
        );
        // 4. สั่งให้ปิดหน้าฟอร์ม กลับไปหน้า Home
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เซิร์ฟเวอร์ตอบกลับผิดพลาด: ${response.statusCode}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      // กรณี Error (เช่น เน็ตหลุด, หา GPS ไม่เจอ) ก็ต้องปิดหน้า Loading ด้วย
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ผิดพลาด: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ระบุรายละเอียด'),
        backgroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'ประเภทเหตุ: ${widget.problemType}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 25),
                _buildField(
                  'เบอร์โทรศัพท์ติดต่อ',
                  _phoneController,
                  Icons.phone,
                  TextInputType.phone,
                  'ระบุเบอร์โทรของคุณ',
                ),
                _buildField(
                  'อาการ/ปัญหาเบื้องต้น',
                  _symptomsController,
                  Icons.build,
                  TextInputType.multiline,
                  'เช่น สตาร์ทไม่ติดมีเสียงดัง',
                ),
                _buildField(
                  'ลักษณะรถ (รุ่น/สี/ทะเบียน)',
                  _vehicleController,
                  Icons.motorcycle,
                  TextInputType.text,
                  'เช่น Honda Click สีขาว กข 123',
                ),
                _buildField(
                  'สถานที่เกิดเหตุ (จุดนัดพบ)',
                  _locationController,
                  Icons.location_on,
                  TextInputType.text,
                  'เช่น หน้าตึก 10 โซน A',
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A1828),
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _submitData,
                  child: const Text(
                    'ส่งข้อมูลแจ้งเหตุ',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl,
    IconData icon,
    TextInputType type,
    String hint,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        maxLines: type == TextInputType.multiline ? 3 : 1,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
