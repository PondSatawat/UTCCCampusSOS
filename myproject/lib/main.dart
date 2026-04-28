import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'home.dart';
import 'history.dart';
import 'nearby.dart';
import 'ai.dart';
import 'login.dart';
import 'profile.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


ValueNotifier<bool> hasNewNotification = ValueNotifier(false);// รับแจ้งเตือนตอนพับแอป

@pragma('vm:entry-point') 
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Notify Vibration..."); 
  if (message.data['type'] == 'SOS_EMERGENCY') {
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // ขออนุญาตส่งการแจ้งเตือน
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(alert: true, badge: true, sound: true);

  // ฟังแจ้งเตือนตอนเปิดแอปทิ้งไว้
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    debugPrint("Received message: ${message.data}");
    String msgType = message.data['type'] ?? '';

    // ดึงข้อมูลผู้ใช้ปัจจุบันว่าล็อกอินเป็นใครอยู่
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final role = doc.data()?['role'] ?? 'user';

      if (role == 'admin' && msgType == 'SOS_EMERGENCY') {
        // Admin: ขึ้นจุดแดงเฉพาะเวลามีคนส่งแจ้งเหตุเข้ามา
        hasNewNotification.value = true;
      } else if (role == 'user' && msgType == 'STATUS_UPDATE') {
        // User: ขึ้นจุดแดงเฉพาะเวลา Admin อัปเดตสถานะให้
        hasNewNotification.value = true;
      }
    }
  });

  // ฟังแจ้งเตือนตอนพับแอป
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  try {
    String? token = await FirebaseMessaging.instance.getToken();
    debugPrint(" FCM Token is: $token");
  } catch (e) {
    debugPrint("Error fetching Token: $e");
  }

  runApp(const CampusAutoSOSApp());
}

class CampusAutoSOSApp extends StatelessWidget {
  const CampusAutoSOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Auto SOS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        primaryColor: const Color(0xFF0A1828),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0A1828)),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _selectedIndex = 0;
  Position? _currentPosition; // ตัวแปรเก็บพิกัดปัจจุบัน

  @override
  void initState() {
    super.initState();
    _determinePosition(); // หาพิกัดทันทีที่เปิดแอป
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position pos = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() => _currentPosition = pos); // เก็บพิกัดไว้
    }
  }

  void _onItemTapped(int index) {
    if(index == 1) {
      hasNewNotification.value = false; // เข้า History แล้วถือว่าอ่านแจ้งเตือนแล้ว
    }
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // ส่งพิกัดไปให้หน้า Home และ Nearby
    final List<Widget> pages = [
      HomeScreen(currentPosition: _currentPosition),
      const HistoryScreen(),
      const AiScreen(),
      NearbyScreen(initialPosition: _currentPosition),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        backgroundColor: const Color(0xFF0A1828),
        onTap: _onItemTapped,
items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          // Redbutton on History tab
          BottomNavigationBarItem(
            icon: ValueListenableBuilder<bool>(
              valueListenable: hasNewNotification,
              builder: (context, hasNew, child) {
                return Stack(
                  clipBehavior: Clip.none, // ให้จุดแดงเลยขอบไอคอนได้นิดนึง
                  children: [
                    const Icon(Icons.history),
                    if (hasNew) // ถ้ามีแจ้งเตือนใหม่ ค่อยวาดจุดแดง
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.redAccent, // สีจุดแดง
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 10,
                            minHeight: 10,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            label: 'History',
          ),
          
          const BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: 'AI'),
          const BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Nearby'),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}