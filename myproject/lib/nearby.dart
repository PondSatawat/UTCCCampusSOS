import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'config.dart';

class NearbyScreen extends StatefulWidget {
  final Position? initialPosition;
  const NearbyScreen({super.key, this.initialPosition});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  Future<List<dynamic>> _getNearbyShops() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location services are disabled');
    
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('กรุณาอนุญาตการเข้าถึงตำแหน่ง');
      }
    }

    Position pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
    ));

    final url = Uri.parse('${AppConfig.baseUrl}/api/shops/nearby?lat=${pos.latitude}&lng=${pos.longitude}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Failed to load shops');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1828),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nearby Garages', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 8, bottom: 24), decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(2))),
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: _getNearbyShops(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.white));
                    if (snapshot.hasError) return const Center(child: Text('ไม่พบข้อมูลร้าน หรือยังไม่ได้เปิดเซิร์ฟเวอร์', style: TextStyle(color: Colors.white70)));
                    if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('ไม่พบร้านซ่อมในรัศมี 10 กม.', style: TextStyle(color: Colors.white70)));
                  
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final shop = snapshot.data![index];
                        IconData icon = shop['type'] == 'motorcycle' ? Icons.motorcycle : Icons.directions_car;
                        return Card(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: Colors.white)),
                            title: Text(shop['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            subtitle: Text('${shop['address']}\nห่างออกไป: ${double.parse(shop['distance'].toString()).toStringAsFixed(2)} กม.', style: const TextStyle(color: Colors.white70)),
                            isThreeLine: true,
                            trailing: IconButton(icon: const Icon(Icons.phone, color: Colors.greenAccent), onPressed: () => launchUrl(Uri.parse('tel:${shop['phoneNumber']}'))),
                          
                          onTap: () async {
                            final lat = shop['latitude'];
                            final lng = shop['longitude'];
                            final String googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
                            final Uri googleMapsUri = Uri.parse(googleMapsUrl);

                            if (await canLaunchUrl(googleMapsUri)) {
                              launchUrl(googleMapsUri);
                            } else {
                              if(!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('ไม่สามารถเปิด Google Maps ได้'), backgroundColor: Colors.redAccent));
                            }
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