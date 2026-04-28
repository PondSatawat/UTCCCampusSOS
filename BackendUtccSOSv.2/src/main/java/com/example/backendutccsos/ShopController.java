package com.example.backendutccsos;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import java.util.*;

@RestController
@RequestMapping("/api/shops")
@CrossOrigin(origins = "*")
public class ShopController {

    @Autowired
    private ShopRepository shopRepository;

    // ค้นหาร้านใกล้เคียง
    @GetMapping("/nearby")
    public List<Shop> getNearbyShops(@RequestParam Double lat, @RequestParam Double lng) {
        List<Shop> allShops = shopRepository.findAll();
        List<Shop> nearbyShops = new ArrayList<>();

        for (Shop shop : allShops) {
            // คำนวณระยะทางจากมือถือ ไปยัง ร้านค้า (หน่วยเป็นกิโลเมตร)
            double dist = calculateDistance(lat, lng, shop.getLatitude(), shop.getLongitude());
            
            // ถ้าระยะทางน้อยกว่าหรือเท่ากับ 10 กิโลเมตร ให้แสดงในแอป
            if (dist <= 10.0) { 
                shop.setDistance(dist);
                nearbyShops.add(shop);
            }
        }

        // เรียงลำดับจากร้านที่ "ใกล้ที่สุด" ไปหา "ไกลที่สุด"
        nearbyShops.sort(Comparator.comparing(Shop::getDistance));
        
        return nearbyShops;
    }

    // เพิ่มข้อมูลร้านใหม่ (สำหรับ Admin)
    //https://filled-arise-encroach.ngrok-free.dev/api/shops/add
    @PostMapping("/add")
    public String addShop(@RequestBody Shop shop) {
        shopRepository.save(shop);
        return "เพิ่มร้านค้า " + shop.getName() + " สำเร็จ!";
    }

    // สูตรคณิตศาสตร์คำนวณระยะทาง GPS (Haversine Formula)
    private double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
        final int R = 6371; // รัศมีโลก (กิโลเมตร)
        double latDistance = Math.toRadians(lat2 - lat1);
        double lonDistance = Math.toRadians(lon2 - lon1);
        double a = Math.sin(latDistance / 2) * Math.sin(latDistance / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(lonDistance / 2) * Math.sin(lonDistance / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    }
}