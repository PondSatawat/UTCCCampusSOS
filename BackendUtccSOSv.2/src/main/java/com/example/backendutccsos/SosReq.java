package com.example.backendutccsos;

import java.time.LocalDateTime;
import org.hibernate.annotations.CreationTimestamp;
import jakarta.persistence.*;
import lombok.Data;

@Data // ใช้ Lombok ช่วยสร้าง Getter/Setter ให้อัตโนมัติ
@Entity // บอกให้ Spring Boot รู้ว่านี่คือตารางใน Database
public class SosReq {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id; // รหัสการแจ้งเหตุ (รันเลขอัตโนมัติ 1, 2, 3...)
    private String userId; // รหัสผู้แจ้งเหตุ (อาจจะเป็นเลขประจำตัวนักศึกษา หรือรหัสพนักงาน)
    private String problemType; // ประเภทปัญหา (เช่น แบตหมด, ยางแบน)
    private String detail; // รายละเอียดเพิ่มเติม
    private String status = "รอดำเนินการ"; // สถานะเริ่มต้น
    private String locationName; // ชื่อสถานที่ที่พิมพ์บอก
    private Double latitude;     // พิกัดละติจูด
    private Double longitude;    // พิกัดลองจิจูด
    private String phoneNumber;   // เบอร์ติดต่อ
    private String symptoms;      // อาการเบื้องต้น
    private String vehicleInfo;   // ลักษณะรถ (เช่น Honda Click สีแดง)
    @CreationTimestamp // ระบบจะใส่เวลาให้อัตโนมัติเมื่อกด SOS
    @Column(updatable = false) // ป้องกันไม่ให้เวลาเปลี่ยนเมื่อมีการอัปเดตสถานะ
    private LocalDateTime createdAt;
}
