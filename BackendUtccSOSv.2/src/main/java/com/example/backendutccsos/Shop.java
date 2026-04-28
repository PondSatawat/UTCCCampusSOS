package com.example.backendutccsos;

import jakarta.persistence.*;
import lombok.Data;

@Data
@Entity
public class Shop {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String name;        // ชื่อร้าน
    private String type;        // ประเภท ('motorcycle' หรือ 'car')
    private String address;     // ที่อยู่ร้าน
    private String phoneNumber; // เบอร์ติดต่อ
    private Double latitude;    // พิกัดละติจูดของร้าน
    private Double longitude;   // พิกัดลองจิจูดของร้าน

    // @Transient บอก Database ว่าไม่ต้องสร้างคอลัมน์นี้ 
    // ใช้คำนวณระยะทางแบบ Real-time และส่งกลับเป็น JSON
    @Transient
    private Double distance;
}